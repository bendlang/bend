from pathlib import Path
import difflib, hashlib, json, re, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
prior = phase / 'literal-context-source-02'
base = phase / 'wave9-source-01/project'
out = phase / 'literal-context-source-03'
manifest = json.loads((prior / 'manifest.json').read_text())
assert manifest['conflicts'] == ['src/front/elaborate.bend', 'tools/typed-driver.mjs']
out.mkdir()
shutil.copy2(__file__, out / 'consumed-tool.py')
shutil.copytree(prior / 'project', out / 'project')
pattern = re.compile(r'^<<<<<<< [^\n]*\n(.*?)^=======\n(.*?)^>>>>>>> [^\n]*\n?', re.M | re.S)

f = 'src/front/elaborate.bend'
s = (prior / 'conflicts' / f).read_text()
matches = list(pattern.finditer(s))
assert len(matches) == 1
left, right = matches[0].groups()
assert 'def f_scope_alias(' in left and 'def f_scope_alias_selected(' in left
assert right.strip() == 'f_choose(KTerm, Char.is_eq(f_head(s), \'"\'), u => kl_make("String", 0, ""), u => f_string_decoded_at(f_decode_char(s), origin))'
assert left.count('kt("Ctr", "SNil", 0, 1, Nil{})') == 1
resolved = left.replace('kt("Ctr", "SNil", 0, 1, Nil{})', 'kl_make("String", 0, "")')
s = pattern.sub(lambda _: resolved, s)
(out / 'project' / f).write_text(s)

f = 'tools/typed-driver.mjs'
s = (prior / 'conflicts' / f).read_text()
matches = list(pattern.finditer(s))
assert len(matches) == 2
replacements = []
left, right = matches[0].groups()
assert 'const loadAbi=' in left and right.strip() == "if(literalAbi===1&&spanAbi!==3)throw Error('Literal ABI requires source-range ABI3');"
replacements.append(left + right)
left, right = matches[1].groups()
assert 'api.f_complete_source(' in left and 'api.f_source_parsed(' in right
assert left.count('validateSpanBook(parsed.book,[range]);') == 1
assert left.count('validateSpanBook(parsed.book,[...physical.values()].map(x=>x.range));') == 1
resolved = left.replace('validateSpanBook(parsed.book,[range]);', 'validateSpanBook(parsed.book,[range],api.compiler_literal_abi?.()??0);')
resolved = resolved.replace('validateSpanBook(parsed.book,[...physical.values()].map(x=>x.range));', 'validateSpanBook(parsed.book,[...physical.values()].map(x=>x.range),api.compiler_literal_abi?.()??0);')
replacements.append(resolved)
iterator = iter(replacements)
s = pattern.sub(lambda _: next(iterator), s)
(out / 'project' / f).write_text(s)

def ident(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

changes, patch = [], []
for folder in ['src', 'tools', 'tests']:
    for p in sorted((out / 'project' / folder).rglob('*')):
        if not p.is_file():
            continue
        f = str(p.relative_to(out / 'project'))
        old = base / f
        assert '<<<<<<< ' not in p.read_text() and '>>>>>>> ' not in p.read_text(), f
        if old.read_bytes() != p.read_bytes():
            changes.append({'path': f, 'before': ident(old), 'after': ident(p)})
            patch += difflib.unified_diff(old.read_text().splitlines(True), p.read_text().splitlines(True), fromfile=f, tofile=f)
(out / 'combined.patch').write_text(''.join(patch))
(out / 'manifest.json').write_text(json.dumps({'complete': True, 'pass': True, 'parent': str(base), 'failedMerge': ident(prior / 'manifest.json'), 'plan': ident(root / 'design/phase16/literal-context-integration.md'), 'tool': ident(Path(__file__)), 'resolutions': ['Retain lexical alias helpers after changing empty string constructor', 'Retain both load and literal ABI guards', 'Retain ordered module completion and add literal validation to both range checks'], 'changes': changes, 'patch': ident(out / 'combined.patch'), 'installationEligible': False}, indent=2) + '\n')
(out / 'workflow.json').write_text(json.dumps({'project': str(out / 'project'), 'upstream': str(root / 'selfhost/.bootstrap/upstream-phase8'), 'profile': 'equality', 'cpu': '0', 'jobs': 1}, indent=2) + '\n')
print(out)
