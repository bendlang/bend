from pathlib import Path
import difflib, hashlib, json, shutil, subprocess

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'wave8-source-02/project'
parent = phase / 'local-law-source-01/project'
owner = phase / 'spans-context-source-04/project'
handoff_file = phase / 'spans-context-source-04-handoff/manifest.json'
handoff = json.loads(handoff_file.read_text())
out = phase / 'wave9-source-01'

def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def inventory(source):
    return {str(p.relative_to(source)): p for folder in ['src', 'tools', 'tests'] for p in (source / folder).rglob('*') if p.is_file()}

a, b, c = inventory(parent), inventory(owner), inventory(base)
assert a.keys() == b.keys() == c.keys()
actual = {f for f in a if a[f].read_bytes() != b[f].read_bytes()}
assert actual == {row['path'] for row in handoff['changes']}
for row in handoff['changes']:
    assert ident(a[row['path']])['sha256'] == row['parentSha256']
    assert ident(b[row['path']])['sha256'] == row['sha256']
out.mkdir()
shutil.copy2(__file__, out / 'consumed-tool.py')
shutil.copytree(base, out / 'project')
merged, patches = [], []
for f in sorted(actual):
    result = subprocess.run(['git', 'merge-file', '-p', str(c[f]), str(a[f]), str(b[f])], capture_output=True)
    destination = out / 'project' / f
    destination.write_bytes(result.stdout)
    row = {'path': f, 'base': ident(c[f]), 'commonParent': ident(a[f]), 'owner': ident(b[f]), 'result': ident(destination), 'exitCode': result.returncode}
    merged.append(row)
    (out / 'merge-progress.json').write_text(json.dumps(merged, indent=2) + '\n')
    assert result.returncode == 0, (f, result.stderr.decode())
    patches += difflib.unified_diff(c[f].read_text().splitlines(True), destination.read_text().splitlines(True), fromfile=f, tofile=f)
(out / 'combined.patch').write_text(''.join(patches))
shutil.copy2(phase / 'wave8-source-02/selection.json', out / 'selection.json')
(out / 'manifest.json').write_text(json.dumps({'parent': str(base), 'plan': ident(root / 'design/phase16/wave9-integration.md'), 'handoff': ident(handoff_file), 'tool': ident(Path(__file__)), 'changes': merged, 'patch': ident(out / 'combined.patch')}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
print(out)
