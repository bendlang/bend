#!/usr/bin/env python3
"""Freeze the separately authorized frame-reuse long-warmup comparison."""
from pathlib import Path
import hashlib, json, sys

ROOT = Path(__file__).resolve().parents[4]
BUILD = ROOT / 'selfhost/build/phase30'
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)

def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}

origin = BUILD / 'review-tree-frame-plan-01/screen.json'
screen = json.loads(origin.read_text())
for item in screen['inputs']:
    assert ident(item['file']) == item
case = screen['cases'][0]
assert case['id'] == 'frame-reuse-original'
assert case['point'] == {'args': [2, 0], 'expected': 887240761}
runner = BUILD / 'tree-compiler-plan-12/long-warmup-compare.py'
launcher = BUILD / 'tree-compiler-plan-12/long-warmup-time.py'
assert "protocols['long_warmup']=dict(samples=3,warmupCalls=3,warmupMs=15000,calibrationMs=100,targetMs=1000,timeout=120)" in runner.read_text()
inputs = screen['inputs'] + [ident(p) for p in [
    Path(__file__), origin, ROOT / 'design/phase30/tree-frame-long-warmup.md',
    BUILD / 'tree-compiler-plan-12/plan.json', runner, launcher,
    ROOT / 'selfhost/tools/performance/phase29/execute.mjs',
]]
plan = {'kind': 'phase30-frame-reuse-long-warmup-plan', 'complete': True,
        'inputs': inputs, 'scope': 'Original Mandelbrot only; actual12 versus immutable private-frame reuse derivative. No instrumented modules.',
        'protocol': {'samples': 3, 'warmupCalls': 3, 'warmupMs': 15000,
                     'calibrationMs': 100, 'targetMs': 1000, 'timeout': 120},
        'launcher': str(launcher), 'cases': [case]}
(out / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
config = {'protocol': 'long_warmup', 'inputs': [ident(out / 'plan.json')] + inputs, 'cases': [case]}
(out / 'long-warmup.json').write_text(json.dumps(config, indent=2) + '\n')
print(json.dumps({'complete': True, 'plan': ident(out / 'plan.json'), 'config': ident(out / 'long-warmup.json')}))
