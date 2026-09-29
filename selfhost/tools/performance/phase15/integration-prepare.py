#!/usr/bin/env python3
"""Freeze reviewed isolated changes into conformance-only and combined projects."""
import difflib, hashlib, json, pathlib, shutil, sys

root = pathlib.Path(__file__).resolve().parents[4]
base = root / 'selfhost/build/phase14/combined-01/snapshot'
behavior = pathlib.Path(sys.argv[1]).resolve()
out = pathlib.Path(sys.argv[2]).resolve()
out.mkdir()
def identity(p):
    return {'file': str(p), 'canonicalPath': str(p.resolve()),
            'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
def read(p): return json.loads(p.read_text())
def write(p, data): p.write_text(json.dumps(data, indent=2) + '\n')

source = root / 'selfhost/build/phase15'
changes = [(behavior, name) for name in [
    'src/front/declarations.bend', 'src/front/sugar.bend',
    'src/front/validate.bend', 'src/load/imports.bend', 'tools/typed-driver.mjs']]
changes.append((source / 'carets-build-01/snapshot', 'src/front/parser.bend'))
speed = (source / 'speed-checked-01/snapshot', 'src/core/term.bend')
assert identity(speed[0] / speed[1])['sha256'] == '118432638aaaee31321e23d00c5a61d9600a7c86f195e4cad25fb2f5413e34cf'
assert identity(changes[-1][0] / changes[-1][1])['sha256'] == identity(source / 'carets-prepare-01/project/src/front/parser.bend')['sha256']
targets = [x['id'] for x in read(source / 'behavior-controls-02/selection.json')[:10]]
assert len(targets) == len(set(targets)) == 10
report = {'kind': 'phase15-integrated-source', 'tool': identity(pathlib.Path(__file__).resolve()),
          'baseline': str(base), 'changes': [], 'projects': {}}
for directory, name in changes + [speed]:
    before, after = base / name, directory / name
    assert before.read_bytes() != after.read_bytes()
    patch = out / (name.replace('/', '_') + '.patch')
    patch.write_text(''.join(difflib.unified_diff(before.read_text().splitlines(True),
        after.read_text().splitlines(True), fromfile='a/selfhost/' + name, tofile='b/selfhost/' + name)))
    report['changes'].append({'relative': name, 'before': identity(before), 'after': identity(after), 'patch': identity(patch)})
for label, cpu in [('conformance', '1'), ('combined', '0')]:
    project = out / label
    for name in ['src', 'tools', 'tests']:
        shutil.copytree(base / name, project / name)
    (project / 'dist').mkdir()
    for directory, name in changes + ([speed] if label == 'combined' else []):
        shutil.copy2(directory / name, project / name)
    selection = project / 'tests/frontend/phase2-rules/cases.json'
    cases = read(selection)
    assert len(cases) == 26 and cases[0]['id'] == 'check/string_literal_long.bend'
    cases += [{'id': name, 'lanes': ['check'], 'accept': False, 'rejectPhase': 'parse'} for name in targets]
    write(selection, cases)
    config = out / (label + '.json')
    write(config, {'project': str(project), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'),
                   'profile': 'equality', 'cpu': cpu, 'jobs': 1})
    report['projects'][label] = {'root': str(project), 'config': identity(config), 'selection': identity(selection)}
write(out / 'manifest.json', report)
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
