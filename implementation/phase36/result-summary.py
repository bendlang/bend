#!/usr/bin/env python3
"""Read completed final receipts; extract bound execution, compiler and profile data."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import statistics

ROOT = Path(__file__).resolve().parents[2]
BASELINE_API = '467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82'
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('--attempt', type=Path, required=True)
ap.add_argument('--baseline-attempt', type=Path, default=ROOT/'selfhost/build/phase35/checked09')
ap.add_argument('--fullrun', type=Path, required=True)
ap.add_argument('--costrun', type=Path, required=True)
ap.add_argument('--profiles', type=Path, required=True)
ap.add_argument('--out', type=Path, required=True)
ap.add_argument('--table', type=Path, help='Optional new Markdown execution table')
a = ap.parse_args()
identities = {}


def identity(file):
    file = Path(file).resolve()
    if str(file) not in identities:
        h = hashlib.sha256()
        with file.open('rb') as stream:
            for block in iter(lambda: stream.read(2**20), b''):
                h.update(block)
        identities[str(file)] = dict(file=str(file), sha256=h.hexdigest(), bytes=file.stat().st_size)
    return identities[str(file)]


def verify(ref, parent=ROOT):
    file = Path(ref.get('file', ref.get('path')))
    if not file.is_absolute():
        file = parent/file
    actual = identity(file)
    assert actual['sha256'] == ref['sha256'], ('changed input', str(file))
    if 'bytes' in ref:
        assert actual['bytes'] == ref['bytes'], str(file)
    return Path(actual['file'])


def read(file, name='report.json'):
    file = Path(file).resolve()
    file = file/name if file.is_dir() else file
    identity(file)
    return file, json.loads(file.read_text())


def stats(xs):
    return dict(median=statistics.median(xs), minimum=min(xs), maximum=max(xs), samples=xs)


def change(before, after):
    return dict(delta=after-before, percent=100*(after/before-1))


def sources(file, attempt):
    assert attempt['kind'] == 'bend-development-attempt' and attempt['checked'] is True
    assert attempt['artifactKind'] == 'derived-b1'
    for key in ['api', 'runtime', 'base']:
        verify(attempt[key])
    snapshot = Path(attempt['snapshot']['root'])
    frozen = {row['frozen']['file']: row['frozen'] for row in attempt['snapshot']['sources']}
    manifest_file = snapshot/'src/compiler.json'
    verify(frozen[str(manifest_file)])
    manifest = json.loads(manifest_file.read_text())
    files = [snapshot/name for name in manifest['modules']]
    texts = []
    for p in files:
        verify(frozen[str(p)])
        texts.append(p.read_text())
    runtime = verify(attempt['runtime'])
    lines = [line for text in texts for line in text.splitlines()]
    return dict(attempt=identity(file), api=attempt['api'], manifest=identity(manifest_file), modules=len(files),
                physicalLines=len(lines), nonblankLines=sum(bool(x.strip()) for x in lines),
                definitions=sum(x.startswith('def ') for x in lines), laws=sum(x.startswith('law ') for x in lines),
                types=sum(x.startswith('type ') for x in lines), sourceBytes=sum(p.stat().st_size for p in files),
                runtimeLines=len(runtime.read_text().splitlines()), runtimeBytes=runtime.stat().st_size)


def frame_key(frame):
    return tuple(frame.get(k, fallback) for k, fallback in
                 [('functionName', ''), ('url', ''), ('lineNumber', -1), ('columnNumber', -1)])


def ancestry(profile, summary):
    mapped = {frame_key(f['frame']): set((f.get('generatedSource') or {}).get('bendNames', [])) for f in summary['frames']}
    nodes = {n['id']: n for n in profile['nodes']}
    parents = {}
    for node in profile['nodes']:
        for child in node.get('children', []):
            assert child not in parents
            parents[child] = node['id']
    memo, owner_memo = {}, {}

    def marks(node_id):
        pending, cursor = [], node_id
        while cursor is not None and cursor not in memo:
            pending.append(cursor)
            cursor = parents.get(cursor)
        for current in reversed(pending):
            frame = nodes[current]['callFrame']
            names = mapped.get(frame_key(frame), set())
            parent = parents.get(current)
            bits = memo[parent] if parent is not None else 0
            owner_memo[current] = names | (owner_memo[parent] if parent is not None else set())
            if names & {'gen', 'gen.leaf', 'node'}:
                bits |= 1
            if names & {'eval', 'esize'}:
                bits |= 2
            if frame.get('functionName') in ['regionHostGuard', 'scalarGuard', 'localGuard', 'regionProofCovers']:
                bits |= 4
            if frame.get('functionName') in ['apply', 'invokeExact', 'enterExact', 'force']:
                bits |= 8
            memo[current] = bits
        return memo[node_id]

    weights, total, owners = [0]*4, 0, {}
    assert len(profile['samples']) == len(profile['timeDeltas'])
    for node_id, weight in zip(profile['samples'], profile['timeDeltas']):
        bits = marks(node_id)
        total += weight
        for name in owner_memo[node_id]:
            owners[name] = owners.get(name, 0) + weight
        for i in range(4):
            if bits & (1 << i):
                weights[i] += weight
    assert total == summary['totalWeight']
    return dict(totalMicroseconds=total, groups={k: dict(microseconds=v, percent=100*v/total) for k, v in
                zip(['producer', 'evalAndSize', 'guards', 'dispatch'], weights)},
                generatedOwnersIncludingCallees=[dict(name=k, microseconds=v, percent=100*v/total)
                    for k, v in sorted(owners.items(), key=lambda x: (-x[1], x[0]))],
                scope='Union ancestry within each group; groups overlap and must not be added. Source names use the retained AST mapping.')


attempt_file, attempt = read(a.attempt, 'attempt.json')
baseline_file, baseline = read(a.baseline_attempt, 'attempt.json')
assert baseline['api']['sha256'] == BASELINE_API
full_file, full = read(a.fullrun)
cost_file, cost = read(a.costrun)
profile_file, profiles = read(a.profiles)
for file, data in [(full_file, full), (cost_file, cost), (profile_file, profiles)]:
    assert data['complete'] is True and data['pass'] is True and not data.get('error'), str(file)
    for ref in data['inputs']:
        verify(ref, file.parent)
for plan in [full['plan'], profiles['plan']]:
    for role, selected in [('baseline', baseline), ('candidate', attempt)]:
        c = plan['variants'][role]['compiler']
        for key in ['api', 'runtime', 'base']:
            verify(c[key])
            assert c[key]['sha256'] == selected[key]['sha256'], (role, key)
assert full['plan']['selectedSet'] == 'full' and len(full['cases']) == 15
assert full['measuredCases'] == 15
assert len({case['id'] for case in full['cases']}) == 15
assert {case['id'] for case in full['cases']} == set(full['plan']['selectedIds'])
assert full['plan']['variants']['typescript']['compiler'] == profiles['plan']['variants']['typescript']['compiler']
report = dict(kind='phase36-final-result-summary', complete=False,
              scope='Same-run execution ratios, separate normal checked compilation and instrumented diagnostics. Fixed points do not estimate average application speed.',
              attempt=identity(attempt_file), baselineAttempt=identity(baseline_file),
              execution=dict(receipt=identity(full_file), wallSeconds=full['wallSeconds'], plan=full['plan'], cases=[]),
              compilation=dict(receipt=identity(cost_file), wallSeconds=cost['wallSeconds'], cases=[]),
              profiling=dict(receipt=identity(profile_file), wallSeconds=profiles['wallSeconds'], plan=profiles['plan'], rows=[]),
              source={role: sources(file, d) for role, file, d in [('baseline', baseline_file, baseline), ('candidate', attempt_file, attempt)]})
report['source']['changes'] = {key: change(report['source']['baseline'][key], report['source']['candidate'][key])
                               for key in ['modules', 'physicalLines', 'nonblankLines', 'definitions', 'laws', 'types', 'sourceBytes', 'runtimeLines', 'runtimeBytes']}
module_hashes, full_cases = {}, {row['id']: row for row in full['cases']}
for case in full['cases']:
    assert case['summary']['complete'] is True
    roles, modules = {}, {}
    for role in ['baseline', 'candidate', 'typescript']:
        samples = [s for s in case['samples'] if s['role'] == role]
        assert len(samples) == case['rounds']
        for sample in samples:
            assert sample['process']['complete'] and sample['result']['complete'] and sample['result']['pass']
            verify(sample['result']['module'])
            for key in ['args', 'expected', 'exportName']:
                assert sample['result']['config'][key] == case['point'][key]
        values = [s['result']['msPerCall'] for s in samples]
        roles[role] = stats(values)
        assert math.isclose(roles[role]['median'], case['summary']['stats'][role]['medianMs'], rel_tol=1e-12)
        assert len({s['result']['module']['sha256'] for s in samples}) == 1
        modules[role] = identity(verify(samples[0]['result']['module']))
        module_hashes[(case['id'], role)] = modules[role]['sha256']
    b, c, ts = [roles[r] for r in ['baseline', 'candidate', 'typescript']]
    report['execution']['cases'].append(dict(id=case['id'], point=case['point'], rounds=case['rounds'], milliseconds=roles,
        baselineOverCandidate=b['median']/c['median'], candidateOverTypeScript=c['median']/ts['median'],
        candidateChangePercent=100*(c['median']/b['median']-1),
        rangesOverlap=max(b['minimum'], c['minimum']) <= min(b['maximum'], c['maximum']), modules=modules,
        moduleGrowth=change(modules['baseline']['bytes'], modules['candidate']['bytes'])))

config_file = verify(cost['config'], cost_file.parent)
config = json.loads(config_file.read_text())
assert config['complete'] is True and config['samples'] == 3
assert config['worker']['sha256'] == 'f0dea569bdb02df60ed1156b0cead389e197291f1c3a3c6775102c7a03790f42'
for role, selected in [('baseline', baseline), ('candidate', attempt)]:
    for key in ['api', 'runtime', 'base']:
        assert config['variants'][role][key]['sha256'] == selected[key]['sha256']
assert len(cost['rows']) == 36 and {r['source'] for r in cost['rows']} == {'local-pair', 'mandelbrot', 'symreg', 'raytrace'}
for case in config['cases']:
    roles = {}
    for role in ['baseline', 'candidate', 'typescript']:
        rows = [r for r in cost['rows'] if r['source'] == case['id'] and r['variant'] == role]
        assert len(rows) == 3
        assert {r['sample'] for r in rows} == {0, 1, 2}
        for row in rows:
            o = row['observation']
            assert row['execution']['complete'] and o['complete'] and o['pass']
            verify(o['source']); verify(o['output'])
            assert o['source']['sha256'] == case['source']['sha256']
            assert o['output']['sha256'] == case['expected'][role]['sha256']
        roles[role] = {key: stats([r['observation'][key] for r in rows]) for key in
                       ['requestMs', 'hostImportMs', 'importAndRequestMs', 'preflightMs']}
        roles[role].update(processMs=stats([1000*r['execution']['wallSeconds'] for r in rows]),
                           peakTreeRssBytes=stats([r['execution']['peakTreeRssBytes'] for r in rows]),
                           outputBytes=stats([r['observation']['output']['bytes'] for r in rows]))
    b, c, ts = [roles[r]['requestMs'] for r in ['baseline', 'candidate', 'typescript']]
    report['compilation']['cases'].append(dict(id=case['id'], statistics=roles,
        candidateChangePercent=100*(c['median']/b['median']-1), candidateOverTypeScript=c['median']/ts['median'],
        rangesOverlap=max(b['minimum'], c['minimum']) <= min(b['maximum'], c['maximum'])))

analysis_file, analysis = read(profile_file.parent/'analysis/report.json')
assert analysis['complete'] is True and profiles['plan']['mode'] == 'all'
assert profiles['completedProfiles'] == len(profiles['profiles']) == len(profiles['plan']['selectedIds'])*6
assert sorted((r['id'], r['role'], r['kind']) for r in profiles['profiles']) == sorted(
    (case, role, kind) for case in profiles['plan']['selectedIds']
    for role in ['baseline', 'candidate', 'typescript'] for kind in ['cpu', 'allocation'])
report['profiling'].update(analysis=identity(analysis_file), completedProfiles=profiles['completedProfiles'], modules=[])
for entry in analysis['entries']:
    module = identity(verify(dict(path=entry['path'], sha256=entry['sha256'])))
    assert module['sha256'] == module_hashes[(entry['id'], entry['role'])]
    report['profiling']['modules'].append(dict(id=entry['id'], role=entry['role'], module=module,
        programBytes=entry['sections']['program']['bytes'], programMetrics=entry['sections']['program']['metrics']))
for row in profiles['profiles']:
    d, s = row['result'], row['result']['summary']
    assert row['complete'] and d['complete'] and d['pass'] and d['diagnosticOnly']
    assert d['module']['sha256'] == module_hashes[(row['id'], row['role'])]
    for key in ['args', 'expected', 'exportName']:
        assert d['config'][key] == full_cases[row['id']]['point'][key]
    raw = verify(d['profile'])
    compact = dict(id=row['id'], role=row['role'], kind=row['kind'], profile=identity(raw),
        repetitions=d['repetitions'], samples=s['sampleCount'], totalWeight=s['totalWeight'], unit=s['unit'],
        categories=s['categories'], topOwners=s['ownersBySelf'][:15],
        topSelf=[{k: f[k] for k in ['functionName', 'category', 'selfWeight', 'selfPercent', 'inclusivePercent']} for f in s['topSelf'][:20]],
        peakTreeRssBytes=row['process']['peakTreeRssBytes'], sampling=d['sampling'], warnings=s['warnings'])
    if row['kind'] == 'allocation':
        compact.update(estimatedBytesPerCall=s['estimatedBytesPerCall'], accounting={key: s['accounting'][key] for key in
            ['weightSource', 'sampleEstimatedBytes', 'headSelfSizeBytes', 'sampleMinusHeadBytes', 'unattributedSamples', 'unattributedEstimatedBytes']})
    else:
        compact['ancestryUnion'] = ancestry(json.loads(raw.read_text()), s)
    report['profiling']['rows'].append(compact)
identity(Path(__file__))
report['inputs'] = list(identities.values())
report['complete'] = True
with a.out.open('x') as stream:
    json.dump(report, stream, indent=2)
    stream.write('\n')
if a.table:
    lines = ['# Final unchanged-catalog execution comparison', '',
             'Milliseconds per call: median (observed minimum–maximum); same-run fresh rotated samples. Ranges are not confidence intervals.', '',
             '| Point | Phase35 | Final candidate | TypeScript | Gain vs Phase35 | Candidate / TS |',
             '| --- | ---: | ---: | ---: | ---: | ---: |']
    for row in report['execution']['cases']:
        cells = [f"{row['milliseconds'][role]['median']:.6g} ({row['milliseconds'][role]['minimum']:.6g}–{row['milliseconds'][role]['maximum']:.6g})" for role in ['baseline', 'candidate', 'typescript']]
        lines.append('| '+row['id']+' | '+' | '.join(cells)+f" | {row['baselineOverCandidate']:.4f}× | {row['candidateOverTypeScript']:.4f}× |")
    lines += ['', 'Generated execution, checked compilation and profiler measurements remain separate in the bound JSON receipt.', '']
    with a.table.open('x') as stream:
        stream.write('\n'.join(lines))
print(json.dumps(dict(complete=True, executionCases=len(report['execution']['cases']), compilerCases=len(report['compilation']['cases']),
                     profiles=report['profiling']['completedProfiles'], output=str(a.out))))
