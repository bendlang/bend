#!/usr/bin/env python3
"""Extend the pending15 plan with actual16 without rerunning its protocols."""
from pathlib import Path
import hashlib, json, shutil, sys
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RAW = ROOT / 'selfhost/build/phase30'
proof, out = map(lambda p: Path(p).resolve(), sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')
prior_path = RAW / 'runtime-actual-timing-plan-15/plan.json'
prior = json.loads(prior_path.read_text())
assert prior['complete']
gates = [proof, RAW / 'runtime-row-actual-numeric-16/report.json', RAW / 'runtime-row-actual-boundaries-16/report.json']
gates.extend(RAW / name / 'report.json' for name in ['review-retire-structure-16b-helper',
    'review-retire-structure-16b-mandelbrot', 'review-retire-scalar-16', 'review-retire-entry-16',
    'review-retire-callables-16-row', 'review-retire-callables-16-helper', 'review-retire-callables-16-mandelbrot',
    'review-retire-arm-16'])
for gate in gates:
    d = json.loads(gate.read_text())
    assert d['complete'] and d['pass'], gate
added = {'checked-runtime-row32': RAW / 'runtime-row-actual-adapters-16/candidate.mjs',
         'checked-runtime-scalar128': RAW / 'runtime-actual-source-16-helper/candidate.mjs'}
cases = []
for c in prior['cases']:
    old = c['modules']
    cases.append({**c, 'modules': {'phase29': old['phase29'], 'held14': old['held14'], 'repair15': old['candidate'],
                                  'candidate': str(added[c['id']]), 'typescript': old['typescript']}})
paths = [Path(__file__), prior_path, ROOT / 'design/phase30/generic-runtime-cleanup-validation.md', *gates,
         RAW / 'runtime-row-actual-adapters-16/derive.json', RAW / 'attempt-16/attempt.json']
for name in ['row', 'helper', 'mandelbrot']:
    module = RAW / ('runtime-actual-source-16-' + name) / 'candidate.mjs'
    paths.extend([module, Path(str(module) + '.json')])
m = json.loads((RAW / 'attempt-16/attempt.json').read_text())
paths.extend([Path(m['api']['file']), Path(m['runtime']['file'])])
inputs = [ident(p) for p in dict.fromkeys(paths)] + prior['inputs'] + [ident(p) for p in added.values()]
for item in inputs:
    assert ident(item['file']) == item, item['file']
plan = {'kind': 'phase30-checked16-runtime-cleanup-small-confirmation', 'complete': True, 'inputs': inputs,
        'scope': 'One same-window Phase29/held14/runtime15/cleaned16/TS comparison; pending15-only plan remains unexecuted. Original points and maintained confirmation protocol unchanged.', 'cases': cases}
save(out / 'plan.json', plan)
for protocol in ['screen', 'confirm']:
    save(out / (protocol + '.json'), {'protocol': protocol, 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': cases})
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'cases': len(cases), 'out': str(out)}))
