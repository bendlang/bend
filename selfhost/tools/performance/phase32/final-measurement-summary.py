#!/usr/bin/env python3
"""Summarize completed integration measurements; missing work stays explicit."""
import argparse
import hashlib
import json
import statistics
from pathlib import Path

ap = argparse.ArgumentParser()
ap.add_argument('plan_directory')
ap.add_argument('out')
ap.add_argument('--require-complete', action='store_true')
args = ap.parse_args()
base, out = Path(args.plan_directory).resolve(), Path(args.out).resolve()
out.mkdir(parents=True, exist_ok=False)
inputs = {}


def identity(file):
    p = Path(file).resolve()
    raw = p.read_bytes()
    row = dict(file=str(p), sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw))
    inputs[str(p)] = row
    return row


def read(file):
    identity(file)
    return json.loads(Path(file).read_text())


def stats(values):
    return dict(median=statistics.median(values), min=min(values), max=max(values), samples=values)


def compare(old, new):
    return dict(speedup=old['median'] / new['median'],
                candidateTimeChangePercent=100 * (new['median'] / old['median'] - 1),
                rangesOverlap=max(old['min'], new['min']) <= min(old['max'], new['max']),
                candidateEntirelyFaster=new['max'] < old['min'],
                candidateEntirelySlower=new['min'] > old['max'])


def timing(file, ids, roles):
    data = read(file)
    assert data['complete'] and data['allCasesMeasured']
    assert [c['id'] for c in data['cases']] == ids
    assert data['protocol']['samples'] == 5
    result = []
    for case in data['cases']:
        assert case['complete'] and list(case['sides']) == roles
        assert len(case['samples']) == 5 * len(roles)
        assert {(r['variant'], r['repetition']) for r in case['samples']} == {
            (role, trial) for role in roles for trial in range(5)}
        rows, modules = {}, {}
        for role in roles:
            times, first, rss, imports, drifts, halves, contexts = [], [], [], [], [], [], set()
            for sample in [r for r in case['samples'] if r['variant'] == role]:
                r = sample['result']
                assert sample['complete'] and sample['exitCode'] == 0 and r['complete']
                assert r['firstResult'] == case['point']['expected']
                assert r['warmup'] >= data['protocol']['warmupCalls']
                assert r['warmupMs'] >= data['protocol']['warmupMs']
                artifact = identity(r['module']['file'])
                assert artifact['sha256'] == r['module']['sha256']
                modules.setdefault(role, artifact)
                assert modules[role] == artifact
                contexts.add((r['node'], tuple(r['args']), r['affinity']))
                times.append(r['executionMs'] / r['repetitions'])
                first.append(r['firstCallMs'])
                imports.append(r['importMs'])
                rss.append(r['peakRssKiB'])
                h = r['halves']
                assert sum(x['calls'] for x in h) == r['repetitions']
                drift = None
                if len(h) == 2:
                    drift = 100 * ((h[1]['ms'] / h[1]['calls']) / (h[0]['ms'] / h[0]['calls']) - 1)
                    drifts.append(drift)
                halves.append(dict(trial=sample['repetition'], halves=h, halfDriftPercent=drift))
            assert len(contexts) == 1
            assert times == case['sides'][role]['samplesMs']
            assert statistics.median(times) == case['sides'][role]['medianMs']
            rows[role] = dict(timeMs=stats(times), firstCallMs=stats(first), importMs=stats(imports),
                              maxRssKiB=max(rss), rssSamplesKiB=rss,
                              halfDriftPercent=stats(drifts) if drifts else None, halves=halves,
                              context=list(next(iter(contexts))))
        baseline, candidate = rows['baseline07']['timeMs'], rows['candidate']['timeMs']
        result.append(dict(id=case['id'], point=case['point'], variants=rows, modules=modules,
            baselineCandidateIdenticalBytes=modules['baseline07']['sha256'] == modules['candidate']['sha256'],
            versus07=compare(baseline, candidate),
            candidateTimesTypeScript=candidate['median'] / rows['typescript']['timeMs']['median'],
            baselineTimesTypeScript=baseline['median'] / rows['typescript']['timeMs']['median']))
    return dict(complete=True, report=identity(file), protocol=data['protocol'], cases=result,
                wallSeconds=data['wallSeconds'])


def costs(file):
    data = read(file)
    assert data['complete'] and data['pass'] and len(data['rows']) == 18
    roles = ['typescript', 'phase31_07', 'candidate']
    assert {(r['source'], r['sample'], r['variant']) for r in data['rows']} == {
        (source, trial, role) for source in ['mandelbrot', 'editdist']
        for trial in range(3) for role in roles}
    cases = {}
    for source in ['mandelbrot', 'editdist']:
        rows = {}
        for role in roles:
            selected = [r for r in data['rows'] if r['source'] == source and r['variant'] == role]
            for row in selected:
                e, o = row['execution'], row['observation']
                assert e['exitCode'] == 0 and not any(e[k] for k in ['signal', 'error', 'timedOut', 'overflow'])
                assert o['complete'] and o['pass']
                assert identity(o['output']['file'])['sha256'] == o['output']['sha256']
            fields = {key: stats([r['observation'][key] for r in selected])
                      for key in ['requestMs', 'hostImportMs', 'importAndRequestMs', 'maxRssKiB']}
            fields['processWallMs'] = stats([r['execution']['wallMs'] for r in selected])
            assert fields == data['statistics'][source][role]
            rows[role] = fields
        comparisons = {}
        for field in ['requestMs', 'importAndRequestMs', 'processWallMs', 'maxRssKiB']:
            comparisons[field] = dict(versus07=compare(rows['phase31_07'][field], rows['candidate'][field]),
                candidateTimesTypeScript=rows['candidate'][field]['median'] / rows['typescript'][field]['median'])
        cases[source] = dict(variants=rows, comparisons=comparisons)
    return dict(complete=True, report=identity(file), rows=18, cases=cases,
                boundaries=data['boundaries'], wallMs=data['wallMs'])


def acquire(name, file, callback):
    if not Path(file).exists():
        return dict(status='not-recorded', complete=False, expectedReport=str(file))
    try:
        return dict(status='complete', **callback(file))
    except Exception as error:
        return dict(status='incomplete-or-invalid', complete=False, expectedReport=str(file),
                    error=repr(error), report=identity(file))


plan = read(base / 'plan.json')
identity(__file__)
runtime = {}
for name in ['mandelbrot', 'editdist', 'test-rle-roundtrip']:
    p = base / 'original-timing-plan' / (name + '-timing') / 'report.json'
    runtime[name] = acquire(name, p, lambda file, name=name: timing(
        file, [name], ['typescript', 'baseline07', 'candidate']))
canaries = acquire('canaries', base / 'canary-confirm/report.json', lambda file: timing(
    file, ['scalar-region-0', 'scalar-region-8192', 'complete-generic-row32'],
    ['baseline07', 'candidate', 'typescript']))
compiler = acquire('compiler-cost', base / 'compiler-cost/report.json', costs)
complete = all(x['complete'] for x in [*runtime.values(), canaries, compiler])
result = dict(kind='phase32-final-measurement-summary', complete=complete, **{'pass': complete},
    attempt=plan['attempt'], runtime=runtime, canaries=canaries, compilerCost=compiler,
    inputs=list(inputs.values()),
    scope='All available frozen-plan observations; absent/incomplete receipts stay explicit. '
          'Measurement completeness is not correctness or promotion admission. Byte-identical '
          'modules permit no source-transformation explanation for timing changes. '
          'Request/import/process timing boundaries and all drift remain distinct.')
(out / 'measurements.json').write_text(json.dumps(result, indent=2) + '\n')
lines = ['# Phase32 final measurements', '',
         'Current status: ' + ('all requested measurements completed.' if complete else
         'incomplete; the missing or invalid receipts below remain outstanding.'), '',
         '| Original program | TypeScript ms | Checked07 ms | Candidate ms | Speedup | Candidate/TS | Identical07 bytes |',
         '|---|---:|---:|---:|---:|---:|---|']
for name, entry in runtime.items():
    if not entry['complete']:
        lines.append(f'| {name} | {entry["status"]} | | | | | |')
        continue
    row = entry['cases'][0]
    v = row['variants']
    lines.append(f'| {name} | {v["typescript"]["timeMs"]["median"]:.6g} | '
                 f'{v["baseline07"]["timeMs"]["median"]:.6g} | {v["candidate"]["timeMs"]["median"]:.6g} | '
                 f'{row["versus07"]["speedup"]:.3f}× | {row["candidateTimesTypeScript"]:.3f}× | '
                 f'{row["baselineCandidateIdenticalBytes"]} |')
lines += ['', 'Compiler cost: ' + compiler['status'] + '. Canary confirmation: ' + canaries['status'] + '.']
if compiler['complete']:
    lines += ['', '| Source / boundary | TypeScript | Checked07 | Candidate | Change vs07 | Ranges overlap |',
              '|---|---:|---:|---:|---:|---|']
    for source, case in compiler['cases'].items():
        for field in ['requestMs', 'importAndRequestMs', 'processWallMs', 'maxRssKiB']:
            v = case['variants']
            comparison = case['comparisons'][field]['versus07']
            lines.append(f'| {source} / {field} | {v["typescript"][field]["median"]:.6g} | '
                         f'{v["phase31_07"][field]["median"]:.6g} | {v["candidate"][field]["median"]:.6g} | '
                         f'{comparison["candidateTimeChangePercent"]:+.2f}% | {comparison["rangesOverlap"]} |')
    lines += ['', 'All18 fresh library requests retain the normal validated Base pipeline. '
              'TypeScript explicitly imports compiler modules outside request time; the Bend API loads '
              'lazily within its request. Import-plus-request is reported separately. Supervised process '
              'wall includes preflight, persistence and postflight and is not ordinary CLI latency.']
if canaries['complete']:
    lines += ['', '| Canary | Checked07 ms | Candidate ms | Change vs07 | Ranges overlap | Identical07 bytes |',
              '|---|---:|---:|---:|---|---|']
    for row in canaries['cases']:
        v, comparison = row['variants'], row['versus07']
        lines.append(f'| {row["id"]} | {v["baseline07"]["timeMs"]["median"]:.6g} | '
                     f'{v["candidate"]["timeMs"]["median"]:.6g} | '
                     f'{comparison["candidateTimeChangePercent"]:+.2f}% | {comparison["rangesOverlap"]} | '
                     f'{row["baselineCandidateIdenticalBytes"]} |')
lines += ['',
          'The JSON retains every median, full range, sample, half drift, first-call/import cost, RSS, '
          'byte comparison and measurement boundary. Identical emitted bytes do not establish identical '
          'process timing; such differences cannot be assigned to a compiler source transformation.', '',
          'This report does not replace the separate correctness closure or final admission decision.', '']
(out / 'measurements.md').write_text('\n'.join(lines))
print(json.dumps(dict(complete=complete, runtime={k: v['status'] for k, v in runtime.items()},
                     canaries=canaries['status'], compilerCost=compiler['status'])))
if args.require_complete and not complete:
    raise SystemExit(1)
