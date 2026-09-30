#!/usr/bin/env python3
"""Count the selected immutable manifest, keeping support source separate."""
from pathlib import Path
import hashlib, json, re, sys

attempt, out = (Path(x).resolve() for x in sys.argv[1:])
assert not out.exists()
record = json.loads((attempt / 'attempt.json').read_text())
snapshot = Path(record['snapshot']['root'])
manifest = snapshot / 'src/compiler.json'
modules = json.loads(manifest.read_text())['modules']
assert len(set(modules)) == len(modules)

def identity(file):
    raw = file.read_bytes()
    return {'file': str(file.resolve()), 'bytes': len(raw),
            'sha256': hashlib.sha256(raw).hexdigest()}

totals = dict(physicalLines=0, nonblankLines=0, bytes=0, defs=0, laws=0, types=0)
inputs = [identity(Path(__file__)), identity(attempt / 'attempt.json'), identity(manifest)]
for name in modules:
    file = snapshot / name if name.startswith('src/') else snapshot / 'src' / name
    item = identity(file)
    text = file.read_text()
    lines = text.splitlines()
    totals['physicalLines'] += len(lines)
    totals['nonblankLines'] += sum(bool(line.strip()) for line in lines)
    totals['bytes'] += item['bytes']
    for field, word in [('defs', 'def'), ('laws', 'law'), ('types', 'type')]:
        totals[field] += len(re.findall(r'^' + word + r'\b', text, re.M))
    inputs.append(item)
support = []
for name in ['src/runtime/js/core.mjs', 'tools/stage0-library.mjs']:
    file = snapshot / name
    support.append({'name': name, **identity(file),
                    'physicalLines': len(file.read_text().splitlines())})
report = {'complete': True, 'scope': 'Canonical manifest Bend source; top-level '
          'def/law/type declarations. Maintained support counted separately; '
          'generated runtime, compiler images and experiment infrastructure excluded.',
          'canonical': {**totals, 'modules': len(modules)}, 'support': support, 'inputs': inputs}
out.write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({'canonical': report['canonical'], 'support': support}))
