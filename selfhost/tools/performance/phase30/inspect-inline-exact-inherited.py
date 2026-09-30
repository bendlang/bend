#!/usr/bin/env python3
"""Adapt retained method controls to unchanged permission decisions, no execution."""
from pathlib import Path
import hashlib
import json
import sys

HERE = Path(__file__).resolve().parent
base, out = (Path(x).resolve() for x in sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)
source = HERE / 'inspect-exact-call-controls.mjs'
text = source.read_text()
changes = [
    ("const sides=['baseline','actual-call']", "const sides=['baseline','inline-exact']"),
    ("kind:'phase30-exact-call-value-controls'", "kind:'phase30-inline-exact-inherited-method-controls'"),
    ("assert.deepEqual(report.permission.map(x=>x.accessorNativeExact),[[false],[true]])",
     "assert.deepEqual(report.permission.map(x=>x.accessorNativeExact),[[false],[false]])"),
    ("path.resolve(import.meta.dirname,'../phase29/fixture-points.json')",
     json.dumps(str(HERE.parent / 'phase29/fixture-points.json'))),
]
for old, new in changes:
    assert text.count(old) == 1
    text = text.replace(old, new)
target = out / 'method-controls.mjs'
target.write_text(text)


def identity(file):
    data = file.read_bytes()
    return {'file': str(file), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}


report = {'kind': 'phase30-inline-exact-inherited-controls-derivation', 'complete': True,
          'inputs': [identity(Path(__file__).resolve()), identity(source), identity(base / 'derive.json')],
          'output': identity(target), 'changes': [{'old': a, 'new': b} for a, b in changes],
          'scope': 'All old method/error/row actions retained; candidate label and exact permission expected unchanged on both sides; fixture path rebound to original.'}
(out / 'derive.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'complete': True, 'out': str(out), 'control': str(target)}))
