#!/usr/bin/env python3
"""Read frozen generated modules and prior AST inventory; execute no compiler."""
import argparse
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
ap = argparse.ArgumentParser(description=__doc__)
ap.add_argument('--out', type=Path, required=True)
args = ap.parse_args()
bundle = ROOT/'selfhost/build/phase35/combined-full-01'
manifest_file = bundle/'manifest.json'
ast_file = ROOT/'selfhost/build/phase35/combined-profiles-01/analysis/report.json'
manifest = json.loads(manifest_file.read_text())
analysis = json.loads(ast_file.read_text())
assert manifest['complete'] and analysis['complete']


def identity(file):
    data = file.read_bytes()
    return dict(file=str(file.relative_to(ROOT)), sha256=hashlib.sha256(data).hexdigest(), bytes=len(data))


result = dict(kind='phase36-inline-static-opportunity', complete=False,
              scope='Static declaration/signature counts; no planner visits, liveness proof or timing.',
              inputs=[identity(Path(__file__)), identity(manifest_file), identity(ast_file)], cases=[])
for case in manifest['cases']:
    if case['id'] not in ['local-pair', 'local-fold', 'mandelbrot', 'symreg', 'raytrace']:
        continue
    module = bundle/case['modules']['candidate']['path']
    text = module.read_text()
    assert identity(module)['sha256'] == case['modules']['candidate']['sha256']
    row = dict(id=case['id'], module=identity(module), closures=[], privateDeclarations=0)
    for line in text.splitlines():
        if 'const $guards=[' not in line:
            continue
        assert line.startswith('G[') and line.count('const $guards=[') == 1
        names = re.findall(r'function (\$R[\w$]+)\(', line)
        decoded = [''.join(chr(int(n)) for n in h[2:].split('$')[0].split('_') if n) for h in names]
        root = re.match(r'G\["([^"]+)"\]', line).group(1)
        row['closures'].append(dict(root=root, declarations=len(names), names=names, bendNames=decoded,
                                    bytes=len(line.encode())))
        row['privateDeclarations'] += len(names)
    entries = [e for e in analysis['entries'] if e['id'] == case['id'] and e['role'] == 'candidate']
    if entries:
        assert len(entries) == 1
        entry = entries[0]
        assert entry['sha256'] == identity(module)['sha256']
        targets = {target['name'] for target in entry['callTargets']}
        helpers = [f for f in entry['functions'] if f['kind'] == 'FunctionDeclaration' and f['name'].startswith('$R_')]
        assert len(helpers) == row['privateDeclarations']
        uncalled = [f for f in helpers if f['name'] not in targets]
        row['withoutDirectCall'] = dict(declarations=len(uncalled), bytes=sum(f['bytes'] for f in uncalled),
                                       caveat='Spelling-level existing AST inventory, not private-plan liveness or removal permission.')
    if case['id'] in ['mandelbrot', 'symreg', 'raytrace']:
        source = ROOT/'selfhost/tools/performance/programs/fixtures'/(case['id']+'.bend')
        assert identity(source)['sha256'] == case['sourceSha256']
        signatures = dict(re.findall(r'^def\s+([^\s(]+)\([\s\S]*?\)\s*->\s*([^:\n]+):', source.read_text(), re.M))
        names = sorted({n for closure in row['closures'] for n in closure['bendNames']})
        row['source'] = identity(source)
        row['helperSourceResultTypes'] = {n: signatures[n] for n in names}
        assert set(row['helperSourceResultTypes'].values()) <= {'U32', 'F32'}
    result['cases'].append(row)
result['complete'] = True
with args.out.open('x') as stream:
    json.dump(result, stream, indent=2)
    stream.write('\n')
print(json.dumps(dict(complete=True, cases=len(result['cases']), output=str(args.out))))
