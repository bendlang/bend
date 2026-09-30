#!/usr/bin/env python3
"""Freeze P30-030 focused timings after derivative and independent gates pass."""
from pathlib import Path
import hashlib
import json
import shutil
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = ROOT / 'selfhost/build/phase30'
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)
inputs = {}

def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

def retain(p, expected=None):
    item = ident(p)
    if expected:
        assert item['file'] == str(Path(expected['file']).resolve()), str(p)
        assert item['sha256'] == expected['sha256'], str(p)
        if 'bytes' in expected:
            assert item['bytes'] == expected['bytes'], str(p)
    assert item['file'] not in inputs or inputs[item['file']] == item
    inputs[item['file']] = item
    return item

def read(p):
    retain(p)
    return json.loads(Path(p).read_text())

def save(p, value):
    p.write_text(json.dumps(value, indent=2) + '\n')

for p in [Path(__file__), HERE / 'prototype-time.py', HERE.parent / 'phase29/compare.py',
          HERE.parent / 'phase29/execute.mjs',
          ROOT / 'design/phase30/registration-free-exact-dispatch.md',
          ROOT / 'design/phase30/registration-dispatch-decision.md',
          RAW / 'tree-compiler-plan-12/long-warmup-time.py',
          RAW / 'tree-compiler-plan-12/long-warmup-compare.py']:
    retain(p)
derived = {}
for name in ['rle', 'helper', 'mandelbrot', 'row']:
    d = read(RAW / f'registration-dispatch16-{name}/derive.json')
    assert d['complete'] and d['audit']['registrationFree'] == (name in ['rle', 'row'])
    for item in [*d['inputs'], d['baseline'], d['baselineRuntime']]:
        retain(item['file'], item)
    for v in d['variants'].values():
        assert v['inverseExact'] and v['generatedSuffixExact']
        retain(v['output']['file'], v['output'])
        retain(v['runtime']['file'], v['runtime'])
    derived[name] = d
for name in ['registration-rle-controls16', 'review-registration-transition-16',
             'review-registration-abi-16', 'review-registration-entry-16',
             'registration-row-controls16']:
    gate = read(RAW / name / 'report.json')
    assert gate['complete'] and gate['pass'], name
    for item in gate['inputs']:
        retain(item['file'], item)
for name in ['baseline', 'flag']:
    gate_dir = RAW / 'registration-mandel-point16' / name
    gate = read(gate_dir / 'run.json')
    assert gate['complete'] and gate['returncode'] == 0
    observed = read(gate_dir / 'stdout.log')
    assert observed['complete'] and observed['firstResult'] == 887240761
    retain(gate_dir / 'stderr.log')
row = read(RAW / 'registration-row-adapters16/derive.json')
assert row['complete']
for item in row['inputs']:
    retain(item['file'], item)
for item in row['variants'].values():
    retain(item['file'], item)
points = read(RAW / 'registration-row-adapters16/points.json')
row_point = next(p for p in points if p['args'] == [32, 17])
original = read(RAW / 'final-transfer-plan-16/test-rle-roundtrip.json')['cases'][0]
assert original['id'] == 'test-rle-roundtrip' and original['point']['expected'] == 11
for name in ['phase29', 'typescript']:
    module = original['modules'][name]
    receipt = read(module + '.json')
    assert receipt['complete'] and (receipt.get('checked') or receipt.get('observation', {}).get('checked'))
    retain(module, receipt['output'])
    for key in ['input', 'attempt', 'api', 'runtime', 'base', 'driver']:
        if key in receipt:
            retain(receipt[key]['file'], receipt[key])
cases = [
    {'id': 'registration-rle', 'point': original['point'], 'modules': {
        'phase29': original['modules']['phase29'],
        'unchanged16': derived['rle']['baseline']['file'],
        'direct': derived['rle']['variants']['direct']['output']['file'],
        'flag': derived['rle']['variants']['flag']['output']['file'],
        'typescript': original['modules']['typescript']}},
    {'id': 'registration-helper128', 'point': {'args': [128, 524800], 'expected': 128, 'exportName': 'bench'},
     'modules': {'unchanged16': derived['helper']['baseline']['file'],
                 'flag': derived['helper']['variants']['flag']['output']['file']}},
    {'id': 'registration-row32', 'point': row_point,
     'modules': {'unchanged16': row['variants']['baseline']['file'], 'flag': row['variants']['flag']['file']}}
]
whole = {'id': 'registration-original-mandelbrot',
         'point': {'args': [2, 0], 'expected': 887240761, 'exportName': 'bench'},
         'modules': {'unchanged16': derived['mandelbrot']['baseline']['file'],
                     'flag': derived['mandelbrot']['variants']['flag']['output']['file']}}
plan = {'kind': 'phase30-registration-dispatch-timing-plan', 'complete': True, 'executed': False,
        'criteria': {'minimumRleReductionPercent': 5, 'rleFiveSampleRangesMustBeDisjoint': True,
                     'maximumNegativeControlSlowdownPercentBeyondVariation': 3,
                     'negativeControls': ['helper128', 'row32', 'original-mandelbrot']},
        'inputs': list(inputs.values()), 'cases': cases, 'longCase': whole,
        'scope': 'Same-source runtime derivatives only; no production compiler change. Maintained screen/confirm; original Mandel uses existing15-second long protocol. No discarded samples.'}
save(out / 'plan.json', plan)
bound = [ident(out / 'plan.json'), *inputs.values()]
save(out / 'screen.json', {'protocol': 'screen', 'inputs': bound, 'cases': cases})
for suffix, case in zip(['rle', 'helper', 'row'], cases):
    save(out / ('confirm-' + suffix + '.json'), {'protocol': 'confirm', 'inputs': bound, 'cases': [case]})
save(out / 'long-mandelbrot.json', {'protocol': 'long_warmup', 'inputs': bound, 'cases': [whole]})
for item in inputs.values():
    assert ident(item['file']) == item
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'out': str(out), 'inputs': len(inputs), 'screenCases': len(cases)}))
