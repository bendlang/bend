#!/usr/bin/env python3
"""Prepare an explicit constructor-only parser scope index, no grammar changes."""
from pathlib import Path
import hashlib, json, shutil, difflib, subprocess, sys
R = Path(__file__).resolve().parents[4]
P = R / 'selfhost/build/phase22/context-source-16'
O = R / 'selfhost/build/phase22/context-source-17'
assert not O.exists(); O.mkdir(); shutil.copytree(P / 'project', O / 'project')
files = ['src/front/contextual.bend', 'src/front/declarations.bend', 'src/front/sugar.bend', 'src/load/modules.bend', 'src/front/validate.bend']
before = {name: (O / 'project' / name).read_text() for name in files}
after = {name: text.replace('FParseScope{prior, index, ns, aliases}', 'FParseScope{prior, index, ctorIndex, ns, aliases}') for name, text in before.items()}
def replace(name, old, new):
    assert after[name].count(old) == 1, (name, old, after[name].count(old))
    after[name] = after[name].replace(old, new)
decl = 'src/front/declarations.bend'; ctx = 'src/front/contextual.bend'; load = 'src/load/modules.bend'; valid = 'src/front/validate.bend'
replace(decl, 'FParseScope{+prior: List<&2,KDef>, +index: KDef, +ns: String, +aliases: List<&2,KTerm>}', 'FParseScope{+prior: List<&2,KDef>, +index: KDef, +ctors: KDef, +ns: String, +aliases: List<&2,KTerm>}')
replace(decl, 'FParseScope{Nil{}, missing(), "", Nil{}}', 'FParseScope{Nil{}, missing(), missing(), "", Nil{}}')
replace(load, 'FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), ns, aliases}', 'FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), f_ctor_index(prior, missing()), ns, aliases}')
replace(ctx, 'f_context_declared(f_context_header(d, ns, aliases), prior, index, ns, aliases)', 'f_context_declared(f_context_header(d, ns, aliases), prior, index, ctorIndex, ns, aliases)')
replace(ctx, 'def f_context_declared(+d: KDef, +prior: List<&2,KDef>, +index: KDef, +ns: String, +aliases: List<&2,KTerm>)', 'def f_context_declared(+d: KDef, +prior: List<&2,KDef>, +index: KDef, +ctorIndex: KDef, +ns: String, +aliases: List<&2,KTerm>)')
replace(ctx, 'FParseScope{Con{d, prior}, index_set(index, d, index_hash(dn(d), 2166136261), 32), ns, aliases}', 'FParseScope{Con{d, prior}, index_set(index, d, index_hash(dn(d), 2166136261), 32), f_ctor_index_def(d, ctorIndex), ns, aliases}')
for old, new in [('f_ctor_lookup(nm(resolved), prior)', 'f_ctor_index_find(nm(resolved), ctorIndex)'), ('f_ctor_lookup(nm(term), prior)', 'f_ctor_index_find(nm(term), ctorIndex)')]: replace(ctx, old, new)
for old, new in [('f_ctor_lookup(own, prior)', 'f_ctor_index_find(own, ctorIndex)'), ('f_ctor_lookup(name, prior)', 'f_ctor_index_find(name, ctorIndex)'), ('f_ctor_lookup(f_qual_name(name, ns), prior)', 'f_ctor_index_find(f_qual_name(name, ns), ctorIndex)')]: replace(decl, old, new)
helpers = '''# Parser scopes retain the first depth-first constructor for each exact name.
@unsafe
def f_ctor_index(+book: List<&2,KDef>, +tree: KDef) -> KDef:
  match book:
    case Nil{}: tree
    case Con{d, rest}: f_ctor_index_def(d, f_ctor_index(rest, tree))

@unsafe
def f_ctor_index_def(+d: KDef, +tree: KDef) -> KDef:
  +children = f_ctor_index(dc(d), tree)
  f_choose(KDef, f_eq(dk(d), "Ctr"), u => index_set(children, d, index_hash(dn(d), 2166136261), 32), u => children)

@unsafe
def f_ctor_index_find(+name: String, +tree: KDef) -> KDef:
  +found = index_find(tree, name, index_hash(name, 2166136261), 32)
  f_choose(KDef, f_eq(dk(found), "Absent"), u => f_find(name, Nil{}), u => found)

'''
replace(valid, '@unsafe\ndef f_valid_ctor_head', helpers + '@unsafe\ndef f_valid_ctor_head')
changes = []
for name in files:
    assert before[name] != after[name]
    (O / 'project' / name).write_text(after[name])
    patch = O / ('parent-' + name.replace('/', '_') + '.patch')
    patch.write_text(''.join(difflib.unified_diff(before[name].splitlines(True), after[name].splitlines(True), fromfile='a/' + name, tofile='b/' + name)))
    changes.append({'path': name, 'lines': len(after[name].splitlines()) - len(before[name].splitlines()), 'bytes': len(after[name].encode()) - len(before[name].encode()), 'patch': str(patch)})
def ident(p): return {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
inputs = [P / 'manifest.json', R / 'design/phase22/context-constructor-index.md', Path(__file__), *[Path(x['patch']) for x in changes]]
(O / 'parent.json').write_text(json.dumps({'parent': str(P), 'changes': changes, 'newDefinitions': 3, 'newTypes': 0, 'newScopeFields': 1, 'newConcept': 'Constructor-only persistent exact-name index in existing parser scope.', 'changedLookupExpressions': 5, 'retainedRawLookup': True, 'inputs': [ident(p) for p in inputs]}, indent=2) + '\n')
subprocess.run([sys.executable, str(R / 'selfhost/tools/performance/phase22/context-freeze.py'), str(O.relative_to(R))], cwd=R, check=True)
print(O)
