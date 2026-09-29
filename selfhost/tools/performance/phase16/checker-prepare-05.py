from pathlib import Path
import shutil, json, hashlib, difflib
root = Path.cwd()
base = root / 'selfhost'
old = base / 'build/phase16/checker-source-04/project'
out = base / 'build/phase16/checker-source-05'
out.mkdir()
shutil.copytree(old, out / 'project')
project = out / 'project'
p = project / 'src/check/specialize.bend'
s = p.read_text()
assert s.count('+serial: U32, ') == 1
s = s.replace('+serial: U32, ', '')
s = s.replace('book, memo, serial, fresh, error, templates', 'book, memo, fresh, error, templates')
a = s.index('@unsafe\ndef sp_serial(')
b = s.index('@unsafe\ndef sp_fresh(', a)
s = s[:a] + s[b:]
s = s.replace('sp_memo(st), sp_serial(st), sp_fresh(st)', 'sp_memo(st), sp_fresh(st)')
s = s.replace('sp_done_memo(sp_memo(st), dn(d)), sp_serial(st), sp_fresh(st)', 'sp_done_memo(sp_memo(st), dn(d)), sp_fresh(st)')
s = s.replace('U32.show(sp_serial(st))', 'U32.show(sp_ordinal(sp_memo(st), dn(d)))')
s = s.replace('U32.add(sp_serial(st), 1), ', '')
s = s.replace('sp_stamp(check_declarations(book, Nil{}), bound), Nil{}, 0, ', 'sp_stamp(check_declarations(book, Nil{}), bound), Nil{}, ')
assert 'serial' not in s
needle = '@unsafe\ndef sp_done_memo('
assert s.count(needle) == 1
s = s.replace(needle, '@unsafe\ndef sp_ordinal(\n  +ms: List<&2, KSpecMemo>,\n  +name: String,\n) -> U32:\n  match ms:\n    case Nil{}: 0\n    case Con{h, rest}: U32.add(kc(U32, String.eq(sp_mtemplate(h), name), u => 1, u => 0), sp_ordinal(rest, name))\n\n' + needle)
p.write_text(s)
name = 'src/check/specialize.bend'
before = (old / name).read_bytes(); after = p.read_bytes()
changes = [{'file': name, 'beforeSha256': hashlib.sha256(before).hexdigest(), 'afterSha256': hashlib.sha256(after).hexdigest(), 'physicalLineDelta': len(after.splitlines()) - len(before.splitlines()), 'byteDelta': len(after) - len(before)}]
(out / 'src_check_specialize.bend.patch').write_text(''.join(difflib.unified_diff(before.decode().splitlines(True), after.decode().splitlines(True), fromfile=name, tofile=name)))
(out / 'manifest.json').write_text(json.dumps({'kind': 'phase16-template-local-instance-names', 'parentSource': 'checker-source-04', 'changes': changes, 'toolSha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), 'plan': str(root / 'design/phase16/checker-instance-names.md')}, indent=2) + '\n')
(out / 'config.json').write_text(json.dumps({'project': str(project), 'upstream': str(base / '.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '1', 'jobs': 1}, indent=2) + '\n')
print(out)
