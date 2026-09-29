#!/usr/bin/env python3
import hashlib,json,shutil,difflib
from pathlib import Path
r=Path(__file__).resolve().parents[4];parent=r/'selfhost/build/phase16/wave9-source-01/project';out=r/'selfhost/build/phase16/spans-context-namespace-source-01';assert not out.exists();p=out/'project';shutil.copytree(parent,p)
f=p/'src/front/declarations.bend';s=f.read_text();old='f_choose(KDef, f_eq(dk(local), "Missing"), u => f_decl_prior(name, scope), u => local)';new='f_choose(KDef, f_eq(dk(local), "Missing"), u => f_decl_local_ctor(name, book, scope, f_decl_prior(name, scope)), u => local)';assert s.count(old)==1;s=s.replace(old,new)
s+='''
# A constructor in this module wins resolution over a far fillable law.
# Missing ordinary definitions do not pay for a local constructor scan.
@unsafe
def f_decl_local_ctor(+name: String, +book: List<&2,KDef>, +scope: FParseScope, +old: KDef) -> KDef:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      f_choose(KDef, f_def_fillable(old),
        u => f_choose(KDef, f_eq(f_alias(name, aliases), name) && Bool.not(f_eq(dk(f_ctor_lookup(name, book)), "Missing")), u => f_find(name, Nil{}), u => old),
        u => old)
'''
a=s.index('def f_type_ctors(');b=s.index('\n\n@unsafe',a)
body=s[a:b];old='u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), ctors)), "Missing"))';new='u => f_choose(FRawResult, Bool.not(f_eq(f_alias(f_tx(ts), imports), f_tx(ts))), u => f_result(book, f_pn(fpe_word(ts, "an import alias cannot name a constructor", "a fresh constructor name (" ++ f_import_alias_head(f_tx(ts)) ++ " is an import\'s alias)")), imports), u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), ctors)), "Missing"))';assert body.count(old)==1;body=body.replace(old,new);old='book, imports, ctors, scope)), u => f_tops';new='book, imports, ctors, scope))), u => f_tops';assert body.count(old)==1;body=body.replace(old,new);s=s[:a]+body+s[b:];f.write_text(s)
old=parent/'src/front/declarations.bend';patch=out/'src_front_declarations.bend.patch';patch.write_text(''.join(difflib.unified_diff(old.read_text().splitlines(True),s.splitlines(True),fromfile='a/src/front/declarations.bend',tofile='b/src/front/declarations.bend')))
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(p),'changes':[{'path':'src/front/declarations.bend','parentSha256':hashlib.sha256(old.read_bytes()).hexdigest(),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'patch':str(patch),'lineDelta':len(s.splitlines())-len(old.read_text().splitlines())}]},indent=2)+'\n')
config={'project':str(p),'upstream':str(r/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':2,'jobs':1};(out/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');print(out)
