#!/usr/bin/env python3
"""Bounded static comparisons and separate generated-program CPU/allocation profiles."""
import argparse
import json
import os
from pathlib import Path
import shutil
import sys
import time
from urllib.parse import unquote, urlparse

from run import HERE, PRESETS, load_bundle, relative_path, require, verify
from support import ExecutionGuard, identity, save

DEPTH = {20: (50, 200), 60: (150, 600), 300: (400, 1500), 600: (1000, 3000)}


def read_result(file):
    try:
        return json.loads(Path(file).read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {'complete': False, 'error': 'Missing or interrupted JSON receipt; raw file retained'}


def from_run(file, catalog, selected, inputs):
    file = file / 'report.json' if file.is_dir() else file
    inputs.append(identity(file))
    report = json.loads(file.read_text())
    require(report.get('kind') == 'bend-program-execution-report' and report.get('pass') is True
            and report.get('complete') is True,
            '--from-run requires a successful execution report')
    require(any(x['sha256'] == identity(catalog)['sha256'] for x in report['inputs']),
            'Timing run used a different catalog')
    roles = report['plan']['roles']
    require(set(roles) in ({'typescript', 'baseline'}, {'typescript', 'baseline', 'candidate'}), 'Unexpected timing roles')
    indexed = {row['id']: row for row in report['cases']}
    points = {}
    for case in selected:
        require(case['id'] in indexed, 'Timing run lacks selected case: ' + case['id'])
        row = indexed[case['id']]
        require(row['summary']['complete'] and row['point'] == case['point'], 'Incomplete or changed timing point')
        points[case['id']] = {}
        for role in roles:
            samples = [s for s in row['samples'] if s['role'] == role]
            require(samples and all(s['complete'] for s in samples), 'Incomplete timing role')
            modules = [s['result']['module'] for s in samples]
            require(len({(m['file'], m['sha256']) for m in modules}) == 1, 'Timing role changed module')
            measured = modules[0]
            actual = identity(measured['file'])
            require(actual['sha256'] == measured['sha256'], 'Measured module changed after timing')
            inputs.append(actual)
            points[case['id']][role] = dict(path=actual['path'], resolved=actual['path'],
                                          sha256=actual['sha256'], bytes=actual['bytes'])
    return {'roles': report['plan']['variants'], 'points': points}


def attach_locations(summary, entry):
    """Map V8 function-origin locations to the smallest containing AST function."""
    module = Path(entry['path']).resolve()
    for row in summary.get('frames', []):
        frame = row['frame']
        url = frame.get('url', '')
        pathname = unquote(urlparse(url).path) if url.startswith('file:') else url
        if not pathname or Path(pathname).resolve() != module:
            continue
        point = (frame.get('lineNumber', -1) + 1, frame.get('columnNumber', -1))
        matches = [f for f in entry.get('functions', [])
                   if (f['line'], f['column']) <= point < (f['endLine'], f['endColumn'])]
        if matches:
            function = min(matches, key=lambda f: f['endUtf16'] - f['startUtf16'])
            row['generatedSource'] = {key: function.get(key) for key in
                ['name', 'line', 'column', 'section', 'bendNames', 'mapping', 'startUtf16', 'endUtf16']}
    owners = {}
    for frame in summary.get('frames', []):
        mapped = frame.get('generatedSource', {})
        names = mapped.get('bendNames') or []
        name = ', '.join(names) if names else mapped.get('name') or frame['frame'].get('functionName') or '<anonymous>'
        key = (mapped.get('section') or frame.get('category') or 'unmapped', name)
        owner = owners.setdefault(key, dict(section=key[0], name=name, selfWeight=0, frames=0))
        owner['selfWeight'] += frame['selfWeight']
        owner['frames'] += 1
    total = summary.get('totalWeight', 0)
    summary['ownersBySelf'] = sorted([{**r, 'selfPercent': 100*r['selfWeight']/total if total else 0}
                                      for r in owners.values()], key=lambda r: -r['selfWeight'])
    summary['mappingScope'] = 'Function-origin positions mapped to smallest AST range; inferred ownership is labeled. Self weights aggregate exclusively; inclusive weights are never summed across frames.'


def render(report, out):
    lines = ['# Generated-program diagnostics', '',
             f"Status: **{report['status']}**; {report.get('completedProfiles', 0)}/{len(report['profiles'])} requested profiles complete.", '',
             'CPU/allocation diagnostics are instrumented observations, not benchmark timings or speed ratios.',
             'Static sites do not establish execution frequency or semantic equivalence.', '',
             '[Structural report](analysis/report.md) · [Side-by-side generated source](analysis/comparison.html)', '',
             '| Case | Role | Kind | Status | Samples | Depth reached | Estimated allocation bytes/call | Largest self cost | Raw profile |',
             '|---|---|---|---|---:|---|---:|---|---|']
    for row in report['profiles']:
        result = row.get('result', {})
        summary = result.get('summary', {})
        top = summary.get('ownersBySelf', [])[:1]
        label = f"{top[0]['name'].replace('|', '/')} ({top[0]['selfPercent']:.1f}%)" if top else '—'
        profile = result.get('profile', {})
        profile_path = profile.get('path', profile.get('file'))
        link = f"[raw]({os.path.relpath(profile_path, out)})" if profile_path else '—'
        status = 'complete' if row['complete'] else row.get('status', 'not-started')
        per_call = summary.get('estimatedBytesPerCall')
        allocation = f'{per_call:.6g}' if per_call is not None else '—'
        lines.append(f"| {row['id']} | {row['role']} | {row['kind']} | {status} | {summary.get('sampleCount', '—')} | {result.get('targetReached', '—')} | {allocation} | {label} | {link} |")
    lines += ['', 'Raw CPU profiles open in a Chrome-compatible profiler; allocation profiles use the V8 sampling heap format.',
              'Sampled allocation bytes estimate allocation during the window, not retained heap or exact allocation counts.',
              'Inspect warnings, capped depth, GC/harness shares and unmapped frames in report.json. No samples is not proof of no cost.', '']
    (out / 'report.md').write_text('\n'.join(lines))


def main(argv=None):
    begin = time.monotonic()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--budget', type=int, choices=DEPTH, default=60)
    parser.add_argument('--mode', choices=['static', 'cpu', 'allocation', 'all'], default='all')
    parser.add_argument('--set', choices=['fast', 'core', 'broad', 'full'])
    parser.add_argument('--cases')
    parser.add_argument('--catalog', type=Path, default=HERE / 'catalog.json')
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--candidate', type=Path)
    parser.add_argument('--from-run', type=Path, help='Profile exact copied modules from a successful timing run')
    parser.add_argument('--node', default=shutil.which('node'))
    parser.add_argument('--cpu', type=int, default=3 if 3 in os.sched_getaffinity(0) else min(os.sched_getaffinity(0)))
    parser.add_argument('--rss-mib', type=int, default=1536)
    parser.add_argument('--available-mib', type=int, default=2048)
    parser.add_argument('--out', type=Path)
    parser.add_argument('--plan', action='store_true')
    args = parser.parse_args(argv)
    require(not (args.from_run and (args.baseline or args.candidate)), '--from-run cannot be combined with bundle selectors')
    require(args.node and Path(args.node).is_file(), 'Node 24+ required; pass --node PATH')
    require(args.cpu in os.sched_getaffinity(0), 'CPU outside allowed affinity')
    require(128 <= args.rss_mib <= 4096 and args.available_mib >= 1024, 'Invalid memory limits')
    require(args.plan or args.out is not None, '--out NEW_DIRECTORY is required')
    catalog = json.loads(args.catalog.read_text())
    by_id = {c['id']: c for c in catalog['cases']}
    require(len(by_id) == len(catalog['cases']), 'Duplicate catalog cases')
    selected_set = args.set or PRESETS[args.budget]['defaultSet']
    names = (args.cases.split(',') if args.cases else catalog['sets'][selected_set])
    if args.from_run and not args.cases and not args.set:
        path = args.from_run / 'report.json' if args.from_run.is_dir() else args.from_run
        names = json.loads(path.read_text())['plan']['selectedIds']
    require(names and len(names) == len(set(names)) and all(n in by_id for n in names), 'Unknown, empty or duplicate selection')
    require(all(n.replace('-', '').replace('_', '').isalnum() for n in names), 'Unsafe case ID')
    selected = [by_id[n] for n in names]
    tools = ['diagnose.py', 'run.py', 'support.py', 'analyze.mjs', 'profile.mjs']
    inputs = [identity(HERE / name) for name in tools] + [identity(args.catalog), identity(args.node), identity(sys.executable)]
    catalog_hash = identity(args.catalog)['sha256']
    for case in selected:
        inputs.append(verify(relative_path(args.catalog.parent, case['source']['path']), case['source']))
    def acquire(out=None):
        if args.from_run:
            return from_run(args.from_run, args.catalog, selected, inputs)
        reference = load_bundle(args.baseline or HERE / 'baseline/manifest.json', catalog, catalog_hash,
                                selected, ['typescript', 'baseline'], inputs, out / 'baseline' if out else None)
        if args.candidate:
            candidate = load_bundle(args.candidate, catalog, catalog_hash, selected, ['candidate'], inputs,
                                    out / 'candidate' if out else None)
            reference['roles'].update(candidate['roles'])
            for name in names:
                reference['points'][name].update(candidate['points'][name])
        return reference
    warm, target = DEPTH[args.budget]
    kinds = [] if args.mode == 'static' else ['cpu', 'allocation'] if args.mode == 'all' else [args.mode]
    plan = dict(kind='bend-program-diagnostic-plan', version=1, budgetSeconds=args.budget, selectedIds=names,
                mode=args.mode, warmupCalls=1, warmupMs=warm, targetMs=target, maxRepetitions=10000000,
                samplingIntervalUs=1000, samplingIntervalBytes=32768, cpu=args.cpu, heapMiB=1024,
                allocationIntervalOverrides={'raytrace': 262144},
                rssMiB=args.rss_mib, availableMiB=args.available_mib,
                scope='Separate instrumented diagnostics; no throughput ratios. Static analysis never executes analyzed code.')
    if args.plan:
        bundle = acquire()
        plan['variants'] = bundle['roles']
        print(json.dumps(plan, indent=2))
        return 0
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    report = dict(kind='bend-program-diagnostic-report', version=1, complete=False, **{'pass': False},
                  status='preflight', plan=plan, inputs=inputs, outputs=[], analysis={}, profiles=[])
    save(out / 'report.json', report)
    deadline = begin + args.budget
    try:
        with ExecutionGuard(args.rss_mib, args.available_mib) as guard:
            bundle = acquire(out / 'acquired')
            roles = ['typescript', 'baseline'] + (['candidate'] if 'candidate' in bundle['roles'] else [])
            plan['variants'] = bundle['roles']
            for name in tools:
                destination = out / 'consumed' / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(HERE / name, destination)
                inputs.append(verify(destination, identity(HERE / name)))
            entries = []
            for case in selected:
                for role in roles:
                    entry = bundle['points'][case['id']][role]
                    source = Path(entry['resolved'])
                    module = out / 'modules' / case['id'] / (role + source.suffix)
                    module.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(source, module)
                    inputs.append(verify(module, entry))
                    entries.append(dict(id=case['id'], role=role, path=str(module), sha256=entry['sha256'],
                        sourcePath=str(relative_path(args.catalog.parent, case['source']['path'])),
                        sourceSha256=case['source']['sha256'], family='upstream' if role == 'typescript' else 'selfhost'))
                    for kind in kinds:
                        report['profiles'].append(dict(id=case['id'], role=role, kind=kind, complete=False, status='not-started'))
            config = out / 'analysis-input.json'
            save(config, dict(entries=entries))
            inputs.append(identity(config))
            save(out / 'plan.json', {**plan, 'inputs': inputs})
            save(out / 'report.json', report)
            command = ['taskset', '-c', str(args.cpu), str(Path(args.node).resolve()), '--stack-size=4096', '--max-old-space-size=1024']
            process = guard.run(command + [str(out / 'consumed/analyze.mjs'), str(config), str(out / 'analysis')],
                                out / 'analysis-process', deadline)
            analysis = read_result(out / 'analysis/report.json')
            report['analysis'] = dict(process=process, complete=process['complete'] and analysis.get('complete') is True)
            if not report['analysis']['complete']:
                reason = process.get('stoppedFor')
                report['status'] = 'budget-exhausted' if reason == 'deadline' else 'interrupted' if reason == 'signal' else 'failed'
                raise RuntimeError('Static analysis incomplete; see preserved receipt')
            analysis_index = {(e['id'], e['role']): e for e in analysis['entries']}
            require(len(analysis_index) == len(entries) == len(analysis['entries']), 'Static coverage differs from plan')
            for entry in entries:
                observed = analysis_index[(entry['id'], entry['role'])]
                require(observed['path'] == entry['path'] and observed['sha256'] == entry['sha256'],
                        'Static analysis module differs from plan')
            report['outputs'].extend(identity(p) for p in (out / 'analysis').rglob('*') if p.is_file())
            report['status'] = 'profiling'
            worker = identity(out / 'consumed/profile.mjs')
            for row in report['profiles']:
                if guard.interrupted or time.monotonic() >= deadline:
                    report['status'] = 'interrupted' if guard.interrupted else 'budget-exhausted'
                    break
                case = by_id[row['id']]
                entry = next(e for e in entries if e['id'] == row['id'] and e['role'] == row['role'])
                directory = out / 'profiles' / row['id'] / (row['role'] + '-' + row['kind'])
                directory.mkdir(parents=True)
                point = {**case['point'], **{k: plan[k] for k in ['warmupCalls', 'warmupMs', 'targetMs', 'maxRepetitions', 'samplingIntervalUs', 'samplingIntervalBytes']}, 'profileKind': row['kind']}
                if row['kind'] == 'allocation':
                    point['samplingIntervalBytes'] = plan['allocationIntervalOverrides'].get(
                        row['id'], plan['samplingIntervalBytes'])
                save(directory / 'point.json', point)
                point_identity = identity(directory / 'point.json')
                inputs.append(point_identity)
                verify(entry['path'], {'sha256': entry['sha256'], 'bytes': Path(entry['path']).stat().st_size})
                verify(out / 'consumed/profile.mjs', worker)
                suffix = 'cpuprofile' if row['kind'] == 'cpu' else 'heapprofile'
                process = guard.run(command + [str(out / 'consumed/profile.mjs'), entry['path'], str(directory / 'point.json'),
                        str(directory / 'sample.json'), str(directory / ('profile.' + suffix))], directory / 'process', deadline)
                result = read_result(directory / 'sample.json')
                row.update(process=process, result=result, status='executed', complete=process['complete'] and result.get('complete') is True and result.get('pass') is True)
                if row['complete']:
                    require(result['module']['sha256'] == entry['sha256'] and result['toolSha256'] == worker['sha256']
                            and result['configSha256'] == point_identity['sha256'], 'Profiled input differs from frozen plan')
                    report['outputs'].append(verify(result['profile']['path'], result['profile']))
                    report['outputs'].append(identity(directory / 'sample.json'))
                    attach_locations(result['summary'], analysis_index[(row['id'], row['role'])])
                    if row['kind'] == 'allocation':
                        result['summary']['estimatedBytesPerCall'] = result['summary']['estimatedBytes'] / result['repetitions']
                        result['summary']['perCallScope'] = 'Sampled allocation estimate divided by validated profiled calls; includes harness/inspector allocations, not a retained-memory or speed ratio.'
                save(out / 'report.json', report)
                if not row['complete']:
                    reason = process.get('stoppedFor')
                    report['status'] = 'budget-exhausted' if reason == 'deadline' else 'interrupted' if reason == 'signal' else 'failed'
                    break
            for item in inputs:
                verify(item['path'], item)
            for item in report['outputs']:
                verify(item['path'], item)
            if report['analysis']['complete'] and all(r['complete'] for r in report['profiles']):
                report.update(status='diagnosed', complete=True, **{'pass': True})
    except Exception as error:
        report.update(error=repr(error), complete=False, **{'pass': False})
        if report['status'] not in ['budget-exhausted', 'interrupted']:
            report['status'] = 'failed'
        report['interpretation'] = 'Incomplete diagnostics or invalidated provenance; raw artifacts retained without a success claim.'
        for row in report['profiles']:
            if row['complete']:
                row.update(complete=False, status='invalidated')
    finally:
        report['completedProfiles'] = sum(r['complete'] for r in report['profiles'])
        report['wallSeconds'] = time.monotonic() - begin
        report['budgetOverrunSeconds'] = max(0, report['wallSeconds'] - args.budget)
        save(out / 'report.json', report)
        render(report, out)
    print(json.dumps({k: report[k] for k in ['status', 'pass', 'completedProfiles', 'wallSeconds']}))
    return 0 if report['pass'] else 1


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
