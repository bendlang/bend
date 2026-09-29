"""Freeze expected-type-only TODO experiment and its paired controls."""
from pathlib import Path
import difflib
import hashlib
import json
import shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'range-cost-recovery-source-01/project'
out = phase / 'quiet-todo-source-01'
out.mkdir()
shutil.copytree(base, out / 'project')
relative = 'src/check/kernel.bend'
p = out / 'project' / relative
before = p.read_text()
old = 'String.eq(tg(t), "Hol"), u => bad("unresolved hole")'
new = 'String.eq(tg(t), "Hol"), u => kc(KChecked, String.eq(nm(t), "TODO"), u => ok(t, ty, Nil{}), u => bad("unresolved hole"))'
assert before.count(old) == 1
p.write_text(before.replace(old, new))

def identity(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

patch = out / 'src_check_kernel.bend.patch'
patch.write_text(''.join(difflib.unified_diff(before.splitlines(True), p.read_text().splitlines(True),
                                           fromfile=relative, tofile=relative)))
fixtures = {
    'single': 'def main() -> U32: ?TODO\n',
    'two-source-holes': 'def a() -> U32: ?TODO\ndef main() -> U32: ?TODO\n',
    'two-references-one-hole': 'def a() -> U32: ?TODO\ndef main() -> U32: a + a\n',
    'affine-binder': 'def f(x: U32) -> U32: ?TODO\ndef main() -> U32: f(1)\n',
    'erased-binder': 'def f(-x: U32) -> U32: ?TODO\ndef main() -> U32: f(1)\n',
    'named-hole': 'def main() -> U32: ?help\n',
    'case-different-hole': 'def main() -> U32: ?todo\n',
    'inference-without-goal': 'def main() -> U32:\n  x = ?TODO\n  x\n',
    'later-ordinary-error': 'def a() -> U32: ?TODO\ndef main() -> U32: True{}\n',
    'earlier-ordinary-error': 'def a() -> U32: True{}\ndef main() -> U32: ?TODO\n',
    'unfilled-and-hole': 'law absent: U32\ndef main() -> U32: ?TODO\n',
    'filled-positive': 'def f(x: U32) -> U32: x\ndef main() -> U32: f(1)\n',
}
fd = out / 'fixtures'
fd.mkdir()
cases = [{'id': 'check/' + n + '.bend', 'lanes': ['check']} for n in ['hole_todo', 'hole_named']]
for name, body in fixtures.items():
    f = fd / (name + '.bend')
    f.write_text('import Base\n' + body)
    cases.append({'id': 'quiet-todo/' + name, 'file': str(f), 'lanes': ['check']})
(out / 'selection.json').write_text(json.dumps({'cases': cases}, indent=2) + '\n')
(out / 'manifest.json').write_text(json.dumps({
    'parent': str(base), 'before': identity(base / relative), 'after': identity(p),
    'patch': identity(patch), 'tool': identity(Path(__file__)),
    'plan': identity(root / 'design/phase16/quiet-todo.md'),
    'fixtures': [identity(f) for f in sorted(fd.glob('*.bend'))]}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({
    'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'),
    'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
shutil.copy2(__file__, out / 'consumed-tool.py')
print(out)
