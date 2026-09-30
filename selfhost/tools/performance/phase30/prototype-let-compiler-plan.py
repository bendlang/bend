#!/usr/bin/env python3
"""Bind checked13/14 and pinned TS after actual private-Let semantic gates."""
from pathlib import Path
import hashlib, json, shutil, sys

ROOT = Path(__file__).resolve().parents[4]
BUILD = ROOT / 'selfhost/build/phase30'
out = Path(sys.argv[1]).resolve(); out.mkdir(parents=True, exist_ok=False)

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')

controls = BUILD / 'inspection-private-let-actual-14'
runner = BUILD / 'tree-compiler-plan-12/long-warmup-compare.py'
launcher = BUILD / 'tree-compiler-plan-12/long-warmup-time.py'
inputs = [ident(p) for p in [Path(__file__), ROOT / 'design/phase30/actual-private-let-timing.md', runner, launcher,
          controls / 'derive.json', controls / 'oracle/report.json', controls / 'boundaries/report.json']]
assert json.loads((controls / 'derive.json').read_text())['complete']
for p in [controls / 'oracle/report.json', controls / 'boundaries/report.json']:
    d = json.loads(p.read_text()); assert d['complete'] and d['pass']
modules = {'actual13': BUILD / 'tree-region-13/candidate.mjs', 'actual14': BUILD / 'private-let-region-14b/candidate.mjs',
           'typescript': ROOT / 'selfhost/build/phase28/runtime-01/mandelbrot/upstream.mjs'}
source_hashes = []
for name, file in modules.items():
    receipt = Path(str(file) + '.json'); d = json.loads(receipt.read_text())
    assert d['complete'] and (d.get('checked') or d.get('observation', {}).get('checked'))
    assert d['output']['sha256'] == ident(file)['sha256']
    source_hashes.append(d['input']['sha256']); inputs += [ident(file), ident(receipt)]
    for key in ['input', 'api', 'runtime', 'base', 'driver', 'attempt']:
        if key in d:
            assert ident(d[key]['file'])['sha256'] == d[key]['sha256']
            inputs.append(ident(d[key]['file']))
    if name != 'typescript':
        assert Path(d['attempt']['file']).parent.name == 'attempt-' + name.removeprefix('actual')
assert len(set(source_hashes)) == 1
case = {'id': 'actual-private-let-original-mandelbrot', 'point': {'args': [2, 0], 'expected': 887240761},
        'modules': {name: str(file) for name, file in modules.items()}}
plan = {'kind': 'phase30-actual-private-let-long-warmup-plan', 'complete': True, 'inputs': inputs,
        'scope': 'Actual checked13 frame reuse versus actual checked14 adding only private Let statements, plus pinned TypeScript; original Mandelbrot bench2 only.',
        'protocol': {'samples': 3, 'warmupCalls': 3, 'warmupMs': 15000, 'calibrationMs': 100, 'targetMs': 1000, 'timeout': 120},
        'launcher': str(launcher), 'cases': [case]}
save(out / 'plan.json', plan); shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
save(out / 'long-warmup.json', {'protocol': 'long_warmup', 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': [case]})
print(json.dumps({'complete': True, 'out': str(out), 'config': ident(out / 'long-warmup.json')}))
