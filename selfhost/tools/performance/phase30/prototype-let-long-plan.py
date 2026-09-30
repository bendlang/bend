#!/usr/bin/env python3
"""Freeze the authorized original-program private-Let long-warmup follow-up."""
from pathlib import Path
import hashlib, json, sys

ROOT = Path(__file__).resolve().parents[4]
BUILD = ROOT / 'selfhost/build/phase30'
out = Path(sys.argv[1]).resolve(); out.mkdir(parents=True, exist_ok=False)

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

origin = BUILD / 'inspection-private-let-plan-01/screen.json'
screen = json.loads(origin.read_text())
for item in screen['inputs']:
    assert ident(item['file']) == item
case = next(c for c in screen['cases'] if c['id'] == 'private-let-original-mandelbrot')
assert case['point'] == {'args': [2, 0], 'expected': 887240761}
runner = BUILD / 'tree-compiler-plan-12/long-warmup-compare.py'
launcher = BUILD / 'tree-compiler-plan-12/long-warmup-time.py'
assert "protocols['long_warmup']=dict(samples=3,warmupCalls=3,warmupMs=15000,calibrationMs=100,targetMs=1000,timeout=120)" in runner.read_text()
inputs = screen['inputs'] + [ident(p) for p in [Path(__file__), origin, ROOT / 'design/phase30/private-let-long-warmup.md',
          BUILD / 'tree-compiler-plan-12/plan.json', runner, launcher, ROOT / 'selfhost/tools/performance/phase29/execute.mjs']]
plan = {'kind': 'phase30-private-let-long-warmup-plan', 'complete': True, 'inputs': inputs,
        'scope': 'Original Mandelbrot only, exact unchanged private-Let prototype and actual12 baseline. No instrumentation.',
        'protocol': {'samples': 3, 'warmupCalls': 3, 'warmupMs': 15000, 'calibrationMs': 100, 'targetMs': 1000, 'timeout': 120},
        'launcher': str(launcher), 'cases': [case]}
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
(out / 'long-warmup.json').write_text(json.dumps({'protocol': 'long_warmup', 'inputs': [ident(out / 'plan.json')] + inputs, 'cases': [case]}, indent=2) + '\n')
print(json.dumps({'complete': True, 'plan': ident(out / 'plan.json'), 'config': ident(out / 'long-warmup.json')}))
