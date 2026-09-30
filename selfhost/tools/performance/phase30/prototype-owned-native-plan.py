#!/usr/bin/env python3
"""Freeze direct native calls after original and independent boundary gates."""
from pathlib import Path
import hashlib, json, shutil, sys

source, controls, counts, markers, deferred, out = map(lambda x: Path(x).resolve(), sys.argv[1:])
out.mkdir(parents=True, exist_ok=False)

def ident(p):
    p = Path(p).resolve(); raw = p.read_bytes()
    return {'file': str(p), 'sha256': hashlib.sha256(raw).hexdigest(), 'bytes': len(raw)}

def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')

for p in [controls, counts, markers, deferred]:
    d = json.loads(p.read_text()); assert d['complete'] and d['pass'], str(p)
derived = json.loads((source / 'derive.json').read_text()); assert derived['complete']
point = next(p for p in json.loads((source / 'points.json').read_text()) if p['args'] == [32, 17])
modules = {name: derived['variants'][name]['file'] for name in ['baseline', 'private_row', 'private_native', 'typescript']}
for name, file in modules.items():
    assert ident(file) == derived['variants'][name]
inputs = [ident(p) for p in [Path(__file__), source / 'derive.json', source / 'points.json', controls, counts, markers, deferred, *modules.values()]]
plan = {'kind': 'phase30-closed-owned-native-prospective-timing', 'complete': True, 'inputs': inputs,
        'scope': 'Same complete local row32 seed17 including generic gen/init and serialization. Prior private row versus direct native calls, with generic baseline and pinned TypeScript. Native candidate adds outer Array marker refusal; all timing uses standard unmodified prototypes. Diagnostic artifacts excluded.',
        'cases': [{'id': 'closed-owned-native-row32', 'point': point, 'modules': modules}]}
save(out / 'plan.json', plan); shutil.copyfile(Path(__file__), out / 'consumed-plan.py')
for protocol in ['screen', 'confirm']:
    save(out / (protocol + '.json'), {'protocol': protocol, 'inputs': [ident(out / 'plan.json'), *inputs], 'cases': plan['cases']})
print(json.dumps({'complete': True, 'out': str(out)}))
