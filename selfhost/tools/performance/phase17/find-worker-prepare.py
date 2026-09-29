"""One-file source worker trial from the exact Phase16 checked project."""
from pathlib import Path
import difflib
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
BASE = ROOT / 'selfhost/build/phase16/compact-final-source-01/project'
OUT = ROOT / 'selfhost/build/phase17/find-worker-source-01'
PLAN = ROOT / 'design/phase17/frontend_find_worker.md'

def members(root):
    return {str(p.relative_to(root)): {
        'sha256': hashlib.sha256(p.read_bytes()).hexdigest(),
        'bytes': p.stat().st_size, 'mode': p.stat().st_mode & 0o777,
    } for p in sorted(root.rglob('*')) if p.is_file()}

before = members(BASE)
assert len(before) == 214
OUT.mkdir()
project = OUT / 'project'
shutil.copytree(BASE, project)
relative = 'src/front/declarations.bend'
file = project / relative
old = file.read_text()
needle = '      f_choose(KDef, f_eq(name, dn(d)), u => d, u => f_find(name, ds))\n'
assert old.count(needle) == 1
replacement = '''      f_find_next(name, d, ds, f_eq(name, dn(d)))

@unsafe
def f_find_next(
  +name: String, +d: KDef, +ds: List<&2, KDef>, +same: Bool,
) -> KDef:
  match same:
    case True{}: d
    case False{}: f_find(name, ds)
'''
new = old.replace(needle, replacement)
file.write_text(new)
after = members(project)
assert set(before) == set(after)
assert [p for p in before if before[p] != after[p]] == [relative]
patch = ''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
    fromfile='a/' + relative, tofile='b/' + relative))
(OUT / 'source.patch').write_text(patch)
manifest = {
    'kind': 'phase17-frontend-find-worker-source', 'complete': True,
    'parent': str(BASE), 'project': str(project),
    'before': before, 'after': after, 'changes': [relative],
    'physicalLineDelta': len(new.splitlines()) - len(old.splitlines()),
    'byteDelta': len(new.encode()) - len(old.encode()),
    'definitionDelta': 1, 'typeDelta': 0,
    'inputs': [{'path': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
               for p in [Path(__file__), PLAN]],
    'installed': False,
}
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
(OUT / 'workflow.json').write_text(json.dumps({
    'project': str(project), 'upstream': str(ROOT / 'selfhost/.bootstrap/upstream-phase8'),
    'profile': 'equality', 'cpu': '0', 'jobs': 1,
}, indent=2) + '\n')
print(json.dumps({k: manifest[k] for k in ['complete', 'changes', 'physicalLineDelta', 'byteDelta']}))
