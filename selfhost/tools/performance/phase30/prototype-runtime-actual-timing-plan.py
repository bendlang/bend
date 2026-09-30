#!/usr/bin/env python3
"""Freeze row and scalar128 confirmation of compiler-produced runtime repair."""
from pathlib import Path
import hashlib, json, shutil, sys
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = ROOT / 'selfhost/build/phase30'
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')
adapters = RAW / 'runtime-row-actual-adapters-15'
manifest = json.loads((adapters / 'derive.json').read_text())
assert manifest['complete']
gates = [RAW / n / 'report.json' for n in ['runtime-actual-proof-15b', 'runtime-row-actual-numeric-15',
          'runtime-row-actual-boundaries-15', 'review-prebind-candidate-scalar-01', 'review-prebind-candidate-token-01', 'review-prebind-candidate-cell-01']]
for p in gates:
    d = json.loads(p.read_text())
    assert d.get('complete', True) and d.get('pass', True), p
order = ['phase29', 'held14', 'candidate', 'typescript']
row = {'id': 'checked-runtime-row32', 'point': next(p for p in json.loads((adapters / 'points.json').read_text()) if p['args'] == [32, 17]),
       'modules': {n: manifest['variants'][n]['file'] for n in order}}
helper_modules = {'phase29': ROOT / 'selfhost/build/phase29/fixture-candidate-04/candidate.mjs',
                  'held14': RAW / 'inspection-private-let-helper-14b/candidate.mjs',
                  'candidate': RAW / 'runtime-actual-source-15-helper/candidate.mjs',
                  'typescript': ROOT / 'selfhost/build/phase29/prototype-01/upstream.mjs'}
helper = {'id': 'checked-runtime-scalar128', 'point': {'exportName': 'bench', 'args': [128, 524800], 'expected': 128},
          'modules': {n: str(p) for n, p in helper_modules.items()}}
paths = [Path(__file__), adapters / 'derive.json', adapters / 'points.json', ROOT / 'design/phase30/generic-runtime-actual-validation.md', *gates]
for p in helper_modules.values():
    paths.extend([p, Path(str(p) + '.json')])
for attempt in [ROOT / 'selfhost/build/phase29/attempt-04', RAW / 'attempt-14', RAW / 'attempt-15']:
    paths.append(attempt / 'attempt.json')
    m = json.loads((attempt / 'attempt.json').read_text())
    paths.extend([Path(m['api']['file']), Path(m['runtime']['file'])])
inputs = [ident(p) for p in dict.fromkeys(paths)] + manifest['inputs'] + list(manifest['variants'].values())
for item in inputs:
    assert ident(item['file']) == item, item['file']
plan = {'kind': 'phase30-checked15-runtime-small-confirmation', 'complete': True, 'inputs': inputs,
        'scope': 'Actual checked15 source output, same-window Phase29/held14/15/TS. Row complete four-array state and scalar128; prior B helper ABI gates apply through exact complete-module proof with one declared comment change.',
        'cases': [row, helper]}
save(out / 'plan.json', plan)
for protocol in ['screen', 'confirm']:
    save(out / (protocol + '.json'), {'protocol': protocol, 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': plan['cases']})
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'cases': 2, 'variants': order, 'out': str(out)}))
