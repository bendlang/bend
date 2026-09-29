from pathlib import Path
import difflib, hashlib, json, shutil, subprocess

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'wave9-source-01/project'
parent = phase / 'wave6-source-01/project'
owner = phase / 'checker-literal-handoff-01/project'
handoff_file = phase / 'checker-literal-handoff-01/manifest.json'
handoff = json.loads(handoff_file.read_text())
out = phase / 'literal-context-source-01'

def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def inventory(source):
    return {str(p.relative_to(source)): p for folder in ['src', 'tools', 'tests'] for p in (source / folder).rglob('*') if p.is_file()}

a, b, c = inventory(parent), inventory(owner), inventory(base)
assert a.keys() == b.keys() == c.keys()
actual = {f for f in a if a[f].read_bytes() != b[f].read_bytes()}
assert actual == {row['file'] for row in handoff['changes']}
for row in handoff['changes']:
    assert ident(a[row['file']])['sha256'] == row['beforeSha256']
    assert ident(b[row['file']])['sha256'] == row['afterSha256']
out.mkdir()
shutil.copy2(__file__, out / 'consumed-tool.py')
shutil.copytree(base, out / 'project')
merged, patches, conflicts = [], [], []
for f in sorted(actual):
    result = subprocess.run(['git', 'merge-file', '-p', str(c[f]), str(a[f]), str(b[f])], capture_output=True)
    assert result.returncode in [0, 1], (f, result.stderr.decode())
    destination = out / ('project' if result.returncode == 0 else 'conflicts') / f
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(result.stdout)
    merged.append({'path': f, 'base': ident(c[f]), 'commonParent': ident(a[f]), 'owner': ident(b[f]), 'result': ident(destination), 'exitCode': result.returncode})
    if result.returncode:
        conflicts.append(f)
    else:
        patches += difflib.unified_diff(c[f].read_text().splitlines(True), destination.read_text().splitlines(True), fromfile=f, tofile=f)
(out / 'combined.patch').write_text(''.join(patches))
(out / 'manifest.json').write_text(json.dumps({'complete': not conflicts, 'pass': not conflicts, 'parent': str(base), 'plan': ident(root / 'design/phase16/literal-context-integration.md'), 'handoff': ident(handoff_file), 'tool': ident(Path(__file__)), 'changes': merged, 'conflicts': conflicts, 'patch': ident(out / 'combined.patch')}, indent=2) + '\n')
assert not conflicts, conflicts
(out / 'workflow.json').write_text(json.dumps({'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
print(out)
