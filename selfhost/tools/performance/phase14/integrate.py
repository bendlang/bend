#!/usr/bin/env python3
"""Compose frozen candidates without editing the installed compiler."""
import hashlib, json, pathlib, shutil

ROOT = pathlib.Path(__file__).resolve().parents[4]
BASE = ROOT / 'selfhost/build/phase12/integrated-03/snapshot'
LAWS = ROOT / 'selfhost/build/phase14/laws-candidate-04'
RENDER = ROOT / 'selfhost/build/phase14/differences-build-02/snapshot/src/diagnostic/render.bend'
DISPATCH = ROOT / 'selfhost/build/phase14/dispatch-source-01/project/src/core/normalize.bend'
OUT = ROOT / 'selfhost/build/phase14/integration-source-01'
OUT.mkdir()

def identity(p):
    return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

patch = json.loads((LAWS / 'patch-manifest.json').read_text())
inputs = [identity(pathlib.Path(__file__).resolve()), identity(LAWS / 'patch-manifest.json')]
for item in patch['files']:
    before, after = BASE / item['file'], LAWS / 'attempt/snapshot' / item['file']
    assert identity(before)['sha256'] == item['beforeSha256']
    assert identity(after)['sha256'] == item['afterSha256']
    inputs.extend([identity(before), identity(after)])
assert identity(RENDER)['sha256'] == 'a36c519e3e23290297dba2c86ca99cf4f97cf8756987b1889c0b431e68fdd24d'
assert identity(DISPATCH)['sha256'] == '56734d1ca3c0a2093280e63c7c7eaf2b331cff8928924582e5314d92b3504be8'
inputs.extend([identity(RENDER), identity(DISPATCH)])
outputs = []
for name, cpu, include_dispatch in [('conformance', '0', False), ('combined', '1', True)]:
    project = OUT / name
    for folder in ['src', 'tools', 'tests']:
        shutil.copytree(BASE / folder, project / folder)
    (project / 'dist').mkdir()
    for item in patch['files']:
        shutil.copy2(LAWS / 'attempt/snapshot' / item['file'], project / item['file'])
    shutil.copy2(RENDER, project / 'src/diagnostic/render.bend')
    if include_dispatch:
        shutil.copy2(DISPATCH, project / 'src/core/normalize.bend')
    selection = project / 'tests/frontend/phase2-rules/cases.json'
    cases = json.loads(selection.read_text())
    assert len(cases) == 22 and cases[0]['id'] == 'check/string_literal_long.bend'
    cases.extend({'id': f'import/unsafe_law_{kind}.bend', 'lanes': ['check'],
                  'accept': False, 'rejectPhase': 'verdict'}
                 for kind in ['derived', 'fill', 'own', 'unused'])
    selection.write_text(json.dumps(cases, indent=2) + '\n')
    config = OUT / (name + '.json')
    config.write_text(json.dumps({'project': str(project),
        'upstream': str(ROOT / 'selfhost/.bootstrap/upstream-phase8'),
        'jobs': 1, 'cpu': cpu, 'profile': 'equality', 'timeoutMs': 30000}, indent=2) + '\n')
    outputs.append({'name': name, 'project': str(project), 'config': identity(config),
                    'selection': identity(selection)})
shutil.copy2(__file__, OUT / 'consumed-tool.py')
(OUT / 'manifest.json').write_text(json.dumps({'kind': 'phase14-integration-source',
    'inputs': inputs, 'outputs': outputs,
    'scope': 'Two checked builds separate conformance changes from source dispatch. Four exact upstream trust cases join the existing focused selection after its fresh string.'}, indent=2) + '\n')
print(OUT)
