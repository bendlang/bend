#!/usr/bin/env python3
"""Bind the seven-way row screen to fresh checked images and semantic gates."""
from pathlib import Path
import hashlib, json, shutil, sys

adapters, numeric, abc, fused, out = map(lambda p: Path(p).resolve(), sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')
derive = json.loads((adapters / 'derive.json').read_text())
assert derive['complete']
for gate in [numeric, abc, fused]:
    report = json.loads(gate.read_text())
    assert report['complete'] and report['pass']
order = ['phase29', 'baseline', 'inline', 'generic', 'fused', 'actual_call', 'typescript']
assert set(order) == set(derive['variants'])
points = json.loads((adapters / 'points.json').read_text())
point = next(p for p in points if p['args'] == [32, 17])
inputs = [ident(p) for p in [Path(__file__), adapters / 'derive.json', adapters / 'points.json', numeric, abc, fused]]
inputs.extend(derive['inputs'])
inputs.extend(derive['variants'].values())
for item in inputs:
    assert ident(item['file']) == item, item['file']
case = {'id': 'runtime-row32', 'point': point, 'modules': {n: derive['variants'][n]['file'] for n in order}}
plan = {'kind': 'phase30-generic-runtime-row-timing-plan', 'complete': True, 'inputs': inputs,
        'scope': 'Same freshly checked row source and complete four128-slot array result; runtime-only A/B/C derivatives. Baseline means checked14; Phase29 is named separately. No private owned-region or native-array ladder.',
        'variants': {'phase29': 'checked Phase29', 'baseline': 'checked14', 'inline': 'A ordinary exact branch inline',
                     'generic': 'B restore generic delayed constructor application', 'fused': 'B registered direct-literal matcher',
                     'actual_call': 'C original code.call read expression', 'typescript': 'pinned upstream same source'},
        'cases': [case]}
save(out / 'plan.json', plan)
for protocol in ['screen', 'confirm']:
    save(out / (protocol + '.json'), {'protocol': protocol, 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': [case]})
shutil.copyfile(__file__, out / 'consumed-plan.py')
print(json.dumps({'complete': True, 'variants': order, 'out': str(out)}))
