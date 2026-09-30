#!/usr/bin/env python3
"""Rebind unchanged row alias/effect assertions to four runtime variants."""
from pathlib import Path
import hashlib, json, shutil, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
config_path, out = map(lambda x: Path(x).resolve(), sys.argv[1:])
config = json.loads(config_path.read_text())
out.mkdir(parents=True, exist_ok=False)
def ident(p):
    p = Path(p).resolve()
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
def resolve(p):
    p = Path(p)
    return p.resolve() if p.is_absolute() else (config_path.parent / p).resolve()
def save(p, x):
    p.write_text(json.dumps(x, indent=2) + '\n')
names = list(config['variants'])
assert len(names) == 4 and names[0] == 'baseline'
assert all(n.replace('_', '').isalnum() for n in names)
original_tool = HERE / 'prototype-owned-controls.mjs'
old = original_tool.read_text()
old_names = "const variants=['baseline','private_cell','private_scalar','private_row'];"
assert old.count(old_names) == 1
new = old.replace(old_names, 'const variants=' + json.dumps(names, separators=(',', ':')) + ';')
start = new.index(' // Post-guard sentinels establish the domain')
end = new.index(' for(const row of report.inputs)', start)
removed = new[start:end]
new = new[:start] + new[end:]
tool = out / 'controls.mjs'
tool.write_text(new)
inputs = [Path(__file__), config_path, original_tool, ROOT / 'design/phase30/generic-runtime-row-diagnosis.md']
for name, value in {**config['variants'], 'typescript': config['typescript']}.items():
    source = resolve(value)
    inputs.append(source)
    shutil.copyfile(source, out / (name + '.mjs'))
points = resolve(config['points'])
inputs.append(points)
shutil.copyfile(points, out / 'points.json')
for p in config.get('evidence', []):
    inputs.append(resolve(p))
save(out / 'derive.json', {'kind': 'phase30-runtime-row-boundary-rebinding', 'complete': True,
    'inputs': [ident(p) for p in dict.fromkeys(inputs)], 'tool': ident(tool), 'variants': names,
    'edits': [{'old': old_names, 'new': 'const variants=' + json.dumps(names, separators=(',', ':')) + ';'},
              {'removedPrivateRegionAdmissionOnly': removed}],
    'preserved': 'All numeric, alias, boundary normalization, mutation, comparison and restoration code is unchanged.'})
print(json.dumps({'complete': True, 'variants': names, 'tool': str(tool)}))
