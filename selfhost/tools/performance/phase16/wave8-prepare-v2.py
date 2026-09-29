from pathlib import Path
import difflib, hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'wave7-source-01/project'
program = phase / 'program-completion-source-01/project'
pattern_parent = phase / 'alias-binding-source-04/project'
pattern = phase / 'alias-pattern-source-02/project'
note = phase / 'checker-note-source-01/project'
out = phase / 'wave8-source-02'

def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def inventory(source):
    return {str(p.relative_to(source)): p for folder in ['src', 'tools', 'tests'] for p in (source / folder).rglob('*') if p.is_file()}

def verify_delta(parent, source, expected):
    a, b = inventory(parent), inventory(source)
    assert a.keys() == b.keys()
    actual = {f for f in a if a[f].read_bytes() != b[f].read_bytes()}
    assert actual == expected, (str(source), actual, expected)
    return [{'path': f, 'before': ident(a[f]), 'after': ident(b[f])} for f in sorted(actual)]

groups = [
    (base, program, {'src/diagnostic/produce.bend', 'src/driver/api.bend', 'tools/typed-driver.mjs'}),
    (pattern_parent, pattern, {'src/front/elaborate.bend'}),
    (base, note, {'src/diagnostic/trace.bend'}),
]
verified = []
for parent, source, expected in groups:
    verified += verify_delta(parent, source, expected)
    for f in expected:
        assert (base / f).read_bytes() == (parent / f).read_bytes(), f
out.mkdir()
shutil.copytree(base, out / 'project')
for parent, source, expected in groups:
    for f in expected:
        shutil.copy2(source / f, out / 'project' / f)
patch = []
for row in verified:
    f = row['path']
    patch += difflib.unified_diff((base / f).read_text().splitlines(True), (out / 'project' / f).read_text().splitlines(True), fromfile=f, tofile=f)
(out / 'combined.patch').write_text(''.join(patch))
inputs, cases, seen = [], [], set()
selection_files = [phase / 'wave7-source-01/selection.json']
for name in ['alias-pattern-validation-02', 'program-completion-validation-01', 'checker-note-focus-01']:
    report_file = phase / name / 'report.json'
    report = json.loads(report_file.read_text())
    assert report['complete'] and report['pass'], name
    inputs.append(ident(report_file))
    selection_files.append(Path(report['selection']['file']))
for file in selection_files:
    inputs.append(ident(file))
    selection = json.loads(file.read_text())
    selected_cases = selection if isinstance(selection, list) else selection['cases']
    for case in selected_cases:
        key = json.dumps(case, sort_keys=True)
        if key not in seen:
            cases.append(case)
            seen.add(key)
(out / 'selection.json').write_text(json.dumps({'cases': cases}, indent=2) + '\n')
(out / 'manifest.json').write_text(json.dumps({'parent': str(base), 'plan': ident(root / 'design/phase16/wave8-integration.md'), 'tool': ident(Path(__file__)), 'inputs': inputs, 'changes': verified, 'patch': ident(out / 'combined.patch')}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
