from pathlib import Path
import difflib, hashlib, json, re, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'wave6-source-01/project'
alias = phase / 'alias-binding-source-04/project'
local = phase / 'local-law-source-01/project'
out = phase / 'wave7-source-01'

def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def changed(source):
    before = {str(p.relative_to(base)): p for p in (base / 'src').rglob('*') if p.is_file()}
    after = {str(p.relative_to(source)): p for p in (source / 'src').rglob('*') if p.is_file()}
    assert before.keys() == after.keys()
    return {f for f, p in before.items() if p.read_bytes() != after[f].read_bytes()}

handoff_file = phase / 'alias-binding-source-04-handoff/manifest.json'
handoff = json.loads(handoff_file.read_text())
expected_alias = {r['file'] for r in handoff['changes']}
assert changed(alias) == expected_alias
for row in handoff['changes']:
    assert ident(base / row['file'])['sha256'] == row['beforeSha256']
    assert ident(alias / row['file'])['sha256'] == row['afterSha256']
expected_local = {'src/front/declarations.bend', 'src/front/validate.bend'}
assert changed(local) == expected_local
assert expected_alias & expected_local == {'src/front/validate.bend'}
local_manifest = phase / 'local-law-source-01/manifest.json'
for row in json.loads(local_manifest.read_text())['changes']:
    assert ident(base / row['path'])['sha256'] == row['before']['sha256']
    assert ident(local / row['path'])['sha256'] == row['after']['sha256']

def function(text, name):
    start = text.index('def ' + name + '(')
    end = re.search(r'\n\n(?:def |law |type |#)', text[start:])
    assert end is not None, name
    return text[start:start + end.start()]

out.mkdir()
shutil.copytree(alias, out / 'project')
shutil.copy2(local / 'src/front/declarations.bend', out / 'project/src/front/declarations.bend')
f = 'src/front/validate.bend'
old = function((base / f).read_text(), 'f_def_prior')
new = function((local / f).read_text(), 'f_def_prior')
assert (local / f).read_text() == (base / f).read_text().replace(old, new)
p = out / 'project' / f
text = p.read_text()
assert function(text, 'f_def_prior') == old
p.write_text(text.replace(old, new))

inputs = [ident(handoff_file), ident(local_manifest)]
changes, patch = [], []
for f in sorted(expected_alias | expected_local):
    before, after = base / f, out / 'project' / f
    inputs.extend([ident(before), ident(alias / f), ident(local / f)])
    changes.append({'path': f, 'before': ident(before), 'after': ident(after)})
    patch.extend(difflib.unified_diff(before.read_text().splitlines(True), after.read_text().splitlines(True), fromfile=f, tofile=f))
patch_file = out / 'combined.patch'
patch_file.write_text(''.join(patch))
cases, seen = [], set()
for name in ['wave6-controls-01', 'alias-binding-lambda-controls-01', 'local-law-source-01']:
    file = phase / name / 'selection.json'
    inputs.append(ident(file))
    for case in json.loads(file.read_text())['cases']:
        key = json.dumps(case, sort_keys=True)
        if key not in seen:
            cases.append(case)
            seen.add(key)
(out / 'selection.json').write_text(json.dumps({'cases': cases}, indent=2) + '\n')
(out / 'manifest.json').write_text(json.dumps({'parent': str(base), 'plan': ident(root / 'design/phase16/wave7-integration.md'), 'tool': ident(Path(__file__)), 'inputs': inputs, 'changes': changes, 'patch': ident(patch_file)}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
