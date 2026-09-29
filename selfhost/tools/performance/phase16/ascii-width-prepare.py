from pathlib import Path
import difflib
import hashlib
import json
import shutil
root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'range-cost-recovery-source-01/project'
out = phase / 'ascii-width-source-01'
out.mkdir()
shutil.copytree(base, out / 'project')
relative = 'src/front/lexer.bend'
p = out / 'project' / relative
s = p.read_text()
old = 'u => 0, u => dg_width(word)))'
new = 'u => 0, u => f_choose(U32, U32.is_eq(k, 1), u => size, u => dg_width(word))))'
assert s.count(old) == 1
p.write_text(s.replace(old, new))
def identity(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
patch = out / 'src_front_lexer.bend.patch'
patch.write_text(''.join(difflib.unified_diff(s.splitlines(True), p.read_text().splitlines(True), fromfile=relative, tofile=relative)))
(out / 'manifest.json').write_text(json.dumps({'parent':str(base), 'before':identity(base/relative),
    'after':identity(p), 'patch':identity(patch), 'tool':identity(Path(__file__)),
    'plan':identity(root/'design/phase16/ascii-token-width.md')}, indent=2)+'\n')
(out / 'workflow.json').write_text(json.dumps({'project':str(out/'project'),
    'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'), 'profile':'equality', 'cpu':'1', 'jobs':1}, indent=2)+'\n')
shutil.copy2(__file__, out/'consumed-tool.py')
print(out)
