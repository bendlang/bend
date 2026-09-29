#!/usr/bin/env python3
"""Fresh checkpoint-A hardening; retains source/build/control attempt 01."""
import hashlib,json,shutil
from pathlib import Path
repo=Path(__file__).resolve().parents[4]
parent=repo/'selfhost/build/phase16/spans-context-source-01/project'
out=repo/'selfhost/build/phase16/spans-context-source-02';assert not out.exists()
p=out/'project';shutil.copytree(parent,p)
f=p/'src/front/declarations.bend';s=f.read_text()
old='''      +key = f_choose(String, f_declared(own, prior) || Bool.not(f_declared(name, prior)), u => own, u => name)
      +found = index_find(index, key, index_hash(key, 2166136261), 32)'''
new='''      +near = index_find(index, own, index_hash(own, 2166136261), 32)
      +far = index_find(index, name, index_hash(name, 2166136261), 32)
      +found = f_choose(KDef, Bool.not(f_eq(dk(near), "Absent")) || f_eq(dk(far), "Absent"), u => near,
        u => f_choose(KDef, Bool.not(f_eq(dk(f_ctor_lookup(own, prior)), "Missing")), u => missing(), u => far))'''
assert s.count(old)==1;s=s.replace(old,new)
old='u => f_def_header_prior(ts, rest, book, imports, unsafe, old, scope)))'
new='''u => f_choose(FRawResult, enabled && Bool.not(f_def_fillable(old)) && f_decl_taken(name, book, scope),
            u => f_result(book, f_pn(fpe_word(ts, "duplicate declaration", "a fresh name (duplicate declaration: " ++ name ++ ")")), imports),
            u => f_def_header_prior(ts, rest, book, imports, unsafe, old, scope))))'''
assert s.count(old)==1;s=s.replace(old,new);f.write_text(s)
f=p/'src/load/modules.bend';s=f.read_text()
s=s.replace('def f_source_body(+source: FSource, +header: FHeader, +scope: FParseScope, +start: U32)', 'def f_source_body(+source: FSource, +header: FHeader, +prior: List<&2,KDef>, +ns: String, +aliases: List<&2,KTerm>, +start: U32)')
s=s.replace('case FSource{name, path, text}: f_body_header(text, header, scope, start)', 'case FSource{name, path, text}: f_body_header(text, header, FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), ns, aliases, True{}}, start)')
s=s.replace('f_source_body(inner, header, scope, begin)', 'f_source_body(inner, header, prior, ns, aliases, begin)')
s=s.replace('f_source_body(source, header, FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), ns, aliases, True{}}, 0)', 'f_source_body(source, header, prior, ns, aliases, 0)')
f.write_text(s)
f=p/'tools/typed-driver.mjs';s=f.read_text()
old='  if(!module.G) return module.default;'
new="  const loadAbi=module.default.compiler_load_abi?.();\n  if(module.default.compiler_load_abi!==undefined&&loadAbi!==1)throw Error('Unknown compiler load ABI: '+loadAbi);\n"+old
assert s.count(old)==1;s=s.replace(old,new)
s=s.replace("FResult:['book','error','imports'],FLoadTrace", "FHeader:['imports','error','body','line','offset'],FCompletion:['graph','parsed'],FGraph:['book','error','done'],FResult:['book','error','imports'],FLoadTrace")
f.write_text(s)
changed=[]
for f in p.rglob('*'):
 if f.is_file() and f.relative_to(p).parts[0] in ['src','tools']:
  old=parent/f.relative_to(p)
  if not old.exists() or old.read_bytes()!=f.read_bytes():changed.append({'path':str(f.relative_to(p)),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(p),'changes':changed,'checkpoint':'A; host discovery remains legacy'},indent=2)+'\n')
c=json.loads((parent.parent/'workflow.json').read_text());c['project']=str(p);(out/'workflow.json').write_text(json.dumps(c,indent=2)+'\n');print(out)
