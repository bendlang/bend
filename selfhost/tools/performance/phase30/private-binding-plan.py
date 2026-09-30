#!/usr/bin/env python3
"""Freeze the two private-binding scopes after their separately retained controls."""
from pathlib import Path
import hashlib
import json
import sys

ROOT = Path(__file__).resolve().parents[4]
helper, whole, out = (Path(x).resolve() for x in sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)

def identity(p):
    p = Path(p).resolve()
    b = p.read_bytes()
    return dict(file=str(p), sha256=hashlib.sha256(b).hexdigest(), bytes=len(b))

inputs = [identity(p) for p in [Path(__file__),
    ROOT / 'design/phase30/private-helper-binding.md',
    helper / 'derive.json', whole / 'derive.json']]
for directory in [helper, whole]:
    receipt = json.loads((directory / 'derive.json').read_text())
    assert receipt['complete']
    for old in receipt['inputs']:
        assert identity(old['file']) == old
    inputs += [identity(directory / (n + '.mjs'))
        for n in ['baseline', 'constant_function', 'constant_arrow']]
controls = [ROOT / 'selfhost/build/phase30' / p for p in [
    'private-binding-helper-controls-01/result.json',
    'private-binding-whole-controls-01/report.json',
    'private-binding-tree-controls-01/report.json']]
for p in controls:
    report = json.loads(p.read_text())
    assert report['pass'] and report['complete']
    inputs.append(identity(p))
variants = lambda d: {n: str(d / (n + '.mjs'))
    for n in ['baseline', 'constant_function', 'constant_arrow']}
cases = [dict(id='binding-helper', point=dict(args=[128, 524800], expected=128), modules=variants(helper)),
         dict(id='binding-whole', point=dict(args=[2, 0], expected=887240761), modules=variants(whole))]
for protocol in ['screen', 'confirm']:
    (out / (protocol + '.json')).write_text(json.dumps(
        dict(protocol=protocol, inputs=inputs, cases=cases), indent=2) + '\n')
(out / 'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
(out / 'plan.json').write_text(json.dumps(dict(complete=True, inputs=inputs,
    scope='Binding form only; separately validated actual12 helper and whole program.'), indent=2) + '\n')
print(json.dumps(dict(complete=True, out=str(out))))
