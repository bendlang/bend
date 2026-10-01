#!/usr/bin/env python3
"""Bounded, paired execution of already compiled Bend programs; never compile."""
import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import statistics
import sys
import tarfile
import time

from support import ExecutionGuard, identity, save

HERE = Path(__file__).resolve().parent
PRESETS = {
    20: dict(defaultSet='fast', rounds=3, warmupCalls=3, warmupMs=100, calibrationMs=20, targetMs=50),
    60: dict(defaultSet='core', rounds=3, warmupCalls=3, warmupMs=350, calibrationMs=40, targetMs=150),
    300: dict(defaultSet='broad', rounds=5, warmupCalls=3, warmupMs=600, calibrationMs=50, targetMs=250),
    600: dict(defaultSet='full', rounds=5, warmupCalls=3, warmupMs=1000, calibrationMs=50, targetMs=300),
}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def relative_path(root, name):
    path = Path(name)
    require(not path.is_absolute() and '..' not in path.parts and path.parts, 'Unsafe bundle path: ' + name)
    resolved = (root / path).resolve()
    require(resolved.is_relative_to(root.resolve()), 'Bundle path escapes root: ' + name)
    return resolved


def verify(file, entry):
    actual = identity(file)
    require(actual['sha256'] == entry['sha256'] and actual['bytes'] == entry['bytes'],
            'Changed input: ' + str(file))
    return actual


def summarize(samples, roles, expected_rounds):
    """Retain unmatched rows; only whole successful rotations form statistics."""
    paired = []
    for index in range(expected_rounds):
        rows = [s for s in samples if s['round'] == index]
        if (len(rows) == len(roles) and {s['role'] for s in rows} == set(roles)
                and all(s['complete'] for s in rows)):
            paired.append(index)
    complete = len(paired) == expected_rounds and all(s['complete'] for s in samples)
    stats = {}
    for role in roles:
        results = [s['result'] for s in samples if s['role'] == role and s['round'] in paired]
        if results:
            values = [r['msPerCall'] for r in results]
            stats[role] = dict(medianMs=statistics.median(values), minimumMs=min(values),
                               maximumMs=max(values), samplesMs=values,
                               firstCallMs=[r.get('firstCallMs') for r in results],
                               importMs=[r.get('importMs') for r in results],
                               halfDriftPercent=[r.get('halfDriftPercent') for r in results])
    ratios = None
    if complete:
        ratios = {role + '/typescript': stats[role]['medianMs'] / stats['typescript']['medianMs']
                  for role in roles if role != 'typescript'}
        if 'candidate' in roles:
            ratios['baseline/candidate'] = stats['baseline']['medianMs'] / stats['candidate']['medianMs']
    return dict(complete=complete, balancedRounds=paired, stats=stats, ratios=ratios)


def load_bundle(file, catalog, catalog_hash, selected, required_roles, inputs, out=None):
    file = Path(file).resolve()
    inputs.append(identity(file))
    bundle = json.loads(file.read_text())
    require(bundle.get('kind') == 'bend-program-bundle' and bundle.get('schemaVersion') == 1
            and bundle.get('complete') is True, 'Incomplete or unsupported bundle')
    require(bundle['catalogSha256'] == catalog_hash, 'Catalog identity differs')
    require(bundle['upstreamCommit'] == catalog['upstreamCommit'], 'Upstream identity differs')
    require(set(bundle['roles']) == set(required_roles), 'Unexpected bundle roles')
    cases = {c['id']: c for c in bundle['cases']}
    require(len(cases) == len(bundle['cases']), 'Duplicate bundled cases')
    entries = {}
    points = {}
    for case in selected:
        require(case['id'] in cases, 'Bundle missing selected case: ' + case['id'])
        row = cases[case['id']]
        require(row['sourceSha256'] == case['source']['sha256'] and row['point'] == case['point'],
                'Case source/point differs: ' + case['id'])
        require(set(row['modules']) == set(required_roles), 'Case roles differ')
        points[case['id']] = row['modules']
        for entry in row['modules'].values():
            relative_path(file.parent, entry['path'])
            require(0 < entry['bytes'] <= 64 * 1024**2, 'Module size outside supported bounds')
            if entry['path'] in entries:
                require(entries[entry['path']] == entry, 'Conflicting module identities')
            entries[entry['path']] = entry
    if 'archive' in bundle:
        archive = relative_path(file.parent, bundle['archive']['path'])
        inputs.append(verify(archive, bundle['archive']))
        found, seen, total = set(), set(), 0
        with tarfile.open(archive, 'r:gz') as stream:
            for member in stream:
                relative_path(file.parent, member.name)
                require(member.isfile() and member.name not in seen, 'Unsafe or repeated archive member')
                seen.add(member.name)
                total += member.size
                require(0 <= member.size <= 64 * 1024**2 and total <= 512 * 1024**2,
                        'Archive expansion outside supported bounds')
                if member.name not in entries:
                    continue
                entry = entries[member.name]
                require(member.size == entry['bytes'], 'Archived module size differs')
                data = stream.extractfile(member).read()
                require(hashlib.sha256(data).hexdigest() == entry['sha256'], 'Archived module hash differs')
                found.add(member.name)
                if out is not None:
                    target = relative_path(out, member.name)
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(data)
        require(found == set(entries), 'Archive missing selected module')
    else:
        for name, entry in entries.items():
            source = relative_path(file.parent, name)
            inputs.append(verify(source, entry))
            if out is not None:
                target = relative_path(out, name)
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, target)
    if out is not None:
        for row in points.values():
            for entry in row.values():
                entry['resolved'] = str(relative_path(out, entry['path']))
    return dict(roles=bundle['roles'], points=points)


def render(report, out):
    lines = ['# Generated-program execution', '',
             f"Status: **{report['status']}**; {report.get('measuredCases', 0)}/{report.get('selectedCases', 0)} selected cases complete.", '',
             'Times include export invocation, exact result validation and checksum work; import and first calls are separate.',
             'The budget is a maximum wall time, not a request to pad a short run. Short warmups are screens, not steady-state evidence.', '',
             '| Case | Paired rounds | Baseline ms | Candidate ms | TypeScript ms | Candidate / TS (or baseline / TS) |',
             '|---|---:|---:|---:|---:|---:|']
    for case in report.get('cases', []):
        summary = case['summary']
        def value(role):
            row = summary['stats'].get(role)
            return f"{row['medianMs']:.6g}" if row and summary['complete'] else '—'
        ratio = summary['ratios']
        ratio = (ratio.get('candidate/typescript', ratio.get('baseline/typescript')) if ratio else None)
        lines.append(f"| {case['id']} | {len(summary['balancedRounds'])}/{case['rounds']} | {value('baseline')} | {value('candidate')} | {value('typescript')} | {f'{ratio:.3f}×' if ratio is not None else '—'} |")
    lines += ['', 'Missing, failed and partial samples remain in report.json; incomplete cases have no comparison ratio.',
              'Output agreement on these fixed inputs is not a full conformance gate. No historical timing is used as a denominator.', '']
    if report.get('diagnostics'):
        diagnostic = report['diagnostics']
        lines += [f"Separate diagnostics: **{diagnostic['status']}**; budget {diagnostic['budgetSeconds']} seconds.",
                  '[Profiles and generated-code comparison](diagnostics/report.md)', '']
    (out / 'report.md').write_text('\n'.join(lines))


def main(argv=None):
    started = time.monotonic()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--budget', type=int, choices=PRESETS, default=20)
    parser.add_argument('--set', choices=['fast', 'core', 'broad', 'full'])
    parser.add_argument('--cases', help='Comma-separated case IDs instead of a named set')
    parser.add_argument('--catalog', type=Path, default=HERE / 'catalog.json')
    parser.add_argument('--baseline', type=Path, default=HERE / 'baseline/manifest.json')
    parser.add_argument('--candidate', type=Path)
    parser.add_argument('--out', type=Path)
    parser.add_argument('--node', default=shutil.which('node'))
    parser.add_argument('--cpu', type=int, default=3 if 3 in os.sched_getaffinity(0) else min(os.sched_getaffinity(0)))
    parser.add_argument('--rss-mib', type=int, default=1536)
    parser.add_argument('--available-mib', type=int, default=2048)
    parser.add_argument('--diagnostics', choices=['static', 'cpu', 'allocation', 'all'],
                        help='After successful timing, run separate generated-code diagnostics')
    parser.add_argument('--diagnostic-budget', type=int, choices=PRESETS,
                        help='Separate diagnostic wall ceiling; defaults to --budget')
    parser.add_argument('--plan', action='store_true', help='Verify inputs and print plan without executing or writing output')
    parser.add_argument('--list', action='store_true', help='List cases and sets without requiring Node or bundles')
    args = parser.parse_args(argv)
    require(args.diagnostics or args.diagnostic_budget is None, '--diagnostic-budget requires --diagnostics')
    catalog = json.loads(args.catalog.read_text())
    if args.list:
        print(json.dumps(dict(sets=catalog.get('sets'), cases=[dict(id=c['id'], point=c['point']) for c in catalog['cases']]), indent=2))
        return 0
    require(args.node and Path(args.node).is_file(), 'Node not found; pass --node PATH (Node 24+)')
    require(args.cpu in os.sched_getaffinity(0), 'Requested CPU is outside allowed affinity')
    require(128 <= args.rss_mib <= 4096 and args.available_mib >= 1024, 'Invalid memory limits')
    require(args.plan or args.out is not None, '--out NEW_DIRECTORY is required')
    preset = PRESETS[args.budget]
    inputs = [identity(p) for p in [__file__, HERE / 'support.py', HERE / 'execute.mjs', args.catalog, args.node]]
    require(catalog['schemaVersion'] == 1, 'Unsupported catalog')
    by_id = {c['id']: c for c in catalog['cases']}
    require(len(by_id) == len(catalog['cases']), 'Duplicate catalog case')
    selected_set = args.set or preset['defaultSet']
    names = (args.cases.split(',') if args.cases else catalog.get('sets', {}).get(selected_set,
             [c['id'] for c in catalog['cases'] if selected_set in c.get('sets', [])]))
    require(names and len(set(names)) == len(names) and all(n in by_id for n in names), 'Unknown, empty or duplicate case selection')
    require(all(n.replace('-', '').replace('_', '').isalnum() for n in names), 'Unsafe case ID')
    selected = [by_id[n] for n in names]
    for case in selected:
        source = relative_path(args.catalog.parent, case['source']['path'])
        inputs.append(verify(source, case['source']))
    roles = ['typescript', 'baseline'] + (['candidate'] if args.candidate else [])
    plan = dict(kind='bend-program-execution-plan', version=1, budgetSeconds=args.budget,
                selectedSet=selected_set if not args.cases else None, selectedIds=names, roles=roles,
                protocol=preset, cpu=args.cpu, node=str(Path(args.node).resolve()), heapMiB=1024,
                rssMiB=args.rss_mib, availableMiB=args.available_mib,
                expensivePointPolicy='raytrace: one warmup call; at most three fresh rounds. Other points: three warmup calls. All also require preset warmup milliseconds.',
                comparison='Same-run execution only; prototype bundles retain explicit labels. No compiler or compilation timing.')
    if args.diagnostics:
        plan['diagnostics'] = dict(mode=args.diagnostics, budgetSeconds=args.diagnostic_budget or args.budget,
                                   scope='Additional separate wall budget; never included in timing ratios')
    if args.plan:
        load_bundle(args.baseline, catalog, inputs[3]['sha256'], selected, ['baseline', 'typescript'], inputs)
        if args.candidate:
            load_bundle(args.candidate, catalog, inputs[3]['sha256'], selected, ['candidate'], inputs)
        print(json.dumps(plan, indent=2))
        return 0
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    deadline = started + args.budget
    report = dict(kind='bend-program-execution-report', version=1, complete=False, **{'pass': False},
                  status='preflight', plan=plan, inputs=inputs, selectedCases=len(selected), cases=[])
    save(out / 'report.json', report)
    try:
        with ExecutionGuard(args.rss_mib, args.available_mib) as guard:
            baseline = load_bundle(args.baseline, catalog, inputs[3]['sha256'], selected,
                                   ['baseline', 'typescript'], inputs, out / 'modules/baseline')
            candidate = (load_bundle(args.candidate, catalog, inputs[3]['sha256'], selected,
                                     ['candidate'], inputs, out / 'modules/candidate') if args.candidate else None)
            plan['variants'] = {**baseline['roles'], **(candidate['roles'] if candidate else {})}
            for case in selected:
                rounds = min(preset['rounds'], 3) if case['id'] == 'raytrace' else preset['rounds']
                row = dict(id=case['id'], point=case['point'], rounds=rounds, samples=[],
                           summary=summarize([], roles, rounds))
                report['cases'].append(row)
            shutil.copyfile(HERE / 'execute.mjs', out / 'consumed-execute.mjs')
            shutil.copyfile(__file__, out / 'consumed-run.py')
            shutil.copyfile(HERE / 'support.py', out / 'consumed-support.py')
            copied = {e['resolved']: e for bundle in [baseline, candidate] if bundle
                      for modules in bundle['points'].values() for e in modules.values()}
            inputs.extend(verify(name, entry) for name, entry in copied.items())
            inputs.extend(identity(out / name) for name in ['consumed-execute.mjs', 'consumed-run.py', 'consumed-support.py'])
            inputs.extend(identity(p) for p in [sys.executable, shutil.which('taskset')])
            worker_identity = identity(out / 'consumed-execute.mjs')
            save(out / 'plan.json', {**plan, 'inputs': inputs})
            report['status'] = 'running'
            save(out / 'report.json', report)
            stopped = False
            for index in range(preset['rounds']):
                for case, row in zip(selected, report['cases']):
                    if index >= row['rounds']:
                        continue
                    order = roles[index % len(roles):] + roles[:index % len(roles)]
                    for role in order:
                        if guard.interrupted or time.monotonic() >= deadline:
                            report['status'] = 'interrupted' if guard.interrupted else 'budget-exhausted'
                            stopped = True
                            break
                        directory = out / 'samples' / case['id'] / f'{index}-{role}'
                        directory.mkdir(parents=True)
                        point = {**case['point'], **{k: preset[k] for k in ['warmupCalls', 'warmupMs', 'calibrationMs', 'targetMs']}}
                        if case['id'] == 'raytrace':
                            point['warmupCalls'] = 1
                        save(directory / 'point.json', point)
                        point_identity = identity(directory / 'point.json')
                        inputs.append(point_identity)
                        bundle = candidate if role == 'candidate' else baseline
                        module_entry = bundle['points'][case['id']][role]
                        module = module_entry['resolved']
                        verify(module, module_entry)
                        verify(out / 'consumed-execute.mjs', worker_identity)
                        command = ['taskset', '-c', str(args.cpu), str(Path(args.node).resolve()),
                                   '--stack-size=4096', '--max-old-space-size=1024',
                                   str(out / 'consumed-execute.mjs'), module,
                                   str(directory / 'point.json'), str(directory / 'sample.json')]
                        process = guard.run(command, directory / 'process', deadline)
                        result_file = directory / 'sample.json'
                        try:
                            result = json.loads(result_file.read_text()) if result_file.exists() else {}
                        except json.JSONDecodeError:
                            result = dict(complete=False, error='Interrupted or malformed sample receipt; raw file preserved')
                        if result.get('complete'):
                            require(result['module']['sha256'] == module_entry['sha256']
                                    and result['toolSha256'] == worker_identity['sha256']
                                    and result['configSha256'] == point_identity['sha256'],
                                    'Measured input identity differs from frozen plan')
                        sample = dict(role=role, round=index, process=process, result=result,
                                      complete=process['complete'] and result.get('complete') is True)
                        row['samples'].append(sample)
                        row['summary'] = summarize(row['samples'], roles, row['rounds'])
                        save(out / 'report.json', report)
                        if not sample['complete']:
                            reason = process.get('stoppedFor')
                            report['status'] = ('budget-exhausted' if reason == 'deadline' else
                                                'interrupted' if reason == 'signal' else 'failed')
                            stopped = True
                            break
                    if stopped:
                        break
                if stopped:
                    break
            for entry in inputs:
                verify(entry['path'], entry)
            if not stopped:
                report['status'] = 'measured'
                report['complete'] = report['pass'] = all(r['summary']['complete'] for r in report['cases'])
    except Exception as error:
        report.update(status='failed', error=repr(error), complete=False, **{'pass': False})
        # Exceptions include changed provenance. Retain observations, but never
        # publish their ratios as a valid comparison after an identity failure.
        for row in report['cases']:
            row['summary'].update(complete=False, ratios=None, invalidated=True)
    finally:
        report['measuredCases'] = sum(r['summary']['complete'] for r in report['cases'])
        report['wallSeconds'] = time.monotonic() - started
        report['budgetOverrunSeconds'] = max(0, report['wallSeconds'] - args.budget)
        save(out / 'report.json', report)
        render(report, out)
    command_pass = report['pass']
    if args.diagnostics:
        diagnostic = {**plan['diagnostics'], 'status': 'not-started', 'pass': False}
        report['diagnostics'] = diagnostic
        save(out / 'report.json', report)
        if report['pass']:
            save(out / 'timing-snapshot.json', report)
            from diagnose import main as diagnose
            try:
                code = diagnose(['--from-run', str(out / 'timing-snapshot.json'), '--mode', args.diagnostics,
                                 '--budget', str(diagnostic['budgetSeconds']), '--out', str(out / 'diagnostics'),
                                 '--catalog', str(args.catalog), '--node', str(args.node), '--cpu', str(args.cpu),
                                 '--rss-mib', str(args.rss_mib), '--available-mib', str(args.available_mib)])
                diagnostic.update(status='complete' if code == 0 else 'failed', **{'pass': code == 0})
            except Exception as error:
                diagnostic.update(status='failed', error=repr(error))
        command_pass = report['pass'] and diagnostic['pass']
        report['commandPass'] = command_pass
        report['totalWallSeconds'] = time.monotonic() - started
        save(out / 'report.json', report)
        render(report, out)
    summary_keys = ['status', 'pass', 'measuredCases', 'selectedCases', 'wallSeconds']
    if args.diagnostics:
        summary_keys += ['commandPass', 'diagnostics', 'totalWallSeconds']
    print(json.dumps({k: report[k] for k in summary_keys}))
    return 0 if command_pass else 1


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except Exception as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1)
