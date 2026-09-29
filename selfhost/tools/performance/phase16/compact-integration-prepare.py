"""Merge the complete checked pattern-owner delta onto a frozen term handoff."""
from pathlib import Path
import difflib, hashlib, json, shutil, subprocess, sys

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base, out = map(lambda s: Path(s).resolve(), sys.argv[1:])
common = phase / 'wave9-source-01/project'
ordinary = phase / 'empty-call-pattern-source-01/project'
marked = phase / 'marked-pattern-source-01/project'

def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

def inventory(p):
    return {str(f.relative_to(p)): f for folder in ['src', 'tools', 'tests']
            for f in (p / folder).rglob('*') if f.is_file()}

a, b, c, current = map(inventory, [common, ordinary, marked, base])
assert a.keys() == b.keys() == c.keys() == current.keys()
assert {n for n in a if a[n].read_bytes() != b[n].read_bytes()} == {'src/front/elaborate.bend'}
assert {n for n in b if b[n].read_bytes() != c[n].read_bytes()} == {'src/front/elaborate.bend', 'src/front/parallel.bend'}
marked_manifest = marked.parent / 'manifest.json'
for row in json.loads(marked_manifest.read_text())['changes']:
    assert ident(b[row['file']])['sha256'] == row['beforeSha256']
    assert ident(c[row['file']])['sha256'] == row['afterSha256']
for name in ['empty-call-pattern-checked-01', 'marked-pattern-checked-01']:
    v = json.loads((phase / name / 'validation-001/report.json').read_text())
    assert v['complete'] and v['pass']
handoff = base.parent / 'manifest.json'
assert handoff.is_file()
term_handoff = json.loads(handoff.read_text())
assert set(current) == {r['file'] for r in term_handoff['completeFinalFiles']}
for row in term_handoff['completeFinalFiles']:
    assert ident(current[row['file']])['sha256'] == row['sha256']
out.mkdir()
shutil.copy2(__file__, out / 'consumed-tool.py')
shutil.copytree(base, out / 'project')
report = {'complete': False, 'pass': False, 'installationEligible': False,
          'base': str(base), 'handoff': ident(handoff), 'common': str(common),
          'ordinaryManifest': ident(ordinary.parent / 'manifest.json'),
          'markedManifest': ident(marked_manifest),
          'plan': ident(root / 'design/phase16/compact-final-gates.md'),
          'tool': ident(Path(__file__)), 'changes': []}

def save():
    (out / 'manifest.json').write_text(json.dumps(report, indent=2) + '\n')

save()
patch = []
for name in sorted(n for n in a if a[n].read_bytes() != c[n].read_bytes()):
    result = subprocess.run(['git', 'merge-file', '-p', str(current[name]),
                             str(a[name]), str(c[name])], capture_output=True)
    target = out / 'project' / name
    target.write_bytes(result.stdout)
    report['changes'].append({'path': name, 'base': ident(current[name]),
                              'common': ident(a[name]), 'owner': ident(c[name]),
                              'result': ident(target), 'exitCode': result.returncode})
    save()
    assert result.returncode == 0, (name, result.returncode, result.stderr.decode())
    patch.extend(difflib.unified_diff(current[name].read_text().splitlines(True),
                 target.read_text().splitlines(True), fromfile=name, tofile=name))
(out / 'combined.patch').write_text(''.join(patch))
report['patch'] = ident(out / 'combined.patch')
report['complete'] = report['pass'] = True
save()
(out / 'workflow.json').write_text(json.dumps({'project': str(out / 'project'),
    'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'),
    'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
print(out)
