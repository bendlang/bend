#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4]; BASE=ROOT/'selfhost/build/phase16/alias-binding-source-03/project'; OUT=ROOT/'selfhost/build/phase16/alias-binding-source-04'; OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def edit(f,a,b):
 p=P/f;s=p.read_text();assert s.count(a)==1,(f,a,s.count(a));p.write_text(s.replace(a,b))
edit('front/elaborate.bend','f_eq(tg(x), "Ref") || (f_eq(tg(x), "FAliasRef") && Bool.not(f_eq(tg(f_env(nm(x), env)), "Absent")))','f_choose(Bool, f_eq(tg(x), "Ref"), u => True{}, u => f_choose(Bool, f_eq(tg(x), "FAliasRef"), u => Bool.not(f_eq(tg(f_env(nm(x), env)), "Absent")), u => False{}))')
edit('front/families.bend','''  f_choose(KTerm, f_eq(tg(t), "FLambda") && f_eq(tg(f_env(nm(t), env)), "Absent"),
    u => f_scope_lambda_refused(t, f_choose(KTerm, f_eq(tg(kid(t, 1)), "FAliasRef"), u => kid(kid(t, 1), 0), u => kid(t, 1))),
    u => f_scope_lambda(t, env, book))''','''  f_choose(KTerm, f_eq(tg(t), "FLambda"),
    u => f_choose(KTerm, f_eq(tg(f_env(nm(t), env)), "Absent"),
      u => f_scope_lambda_refused(t, f_choose(KTerm, f_eq(tg(kid(t, 1)), "FAliasRef"), u => kid(kid(t, 1), 0), u => kid(t, 1))),
      u => f_scope_lambda(t, env, book)),
    u => f_scope_lambda(t, env, book))''')
edit('front/parser.bend','f_eq(tg(b), "Error") && Bool.not(f_eq(op, "=>") && (String.contains(nm(a), ".") || Bool.not(f_eq(tg(a), "Ref") && f_valid_name(nm(a)))))','f_choose(Bool, f_eq(tg(b), "Error"), u => f_choose(Bool, f_eq(op, "=>"), u => Bool.not(String.contains(nm(a), ".") || Bool.not(f_eq(tg(a), "Ref") && f_valid_name(nm(a)))), u => True{}), u => False{})')
changes=[]
for p in sorted(P.rglob('*.bend')):
 a=BASE/'src'/p.relative_to(P)
 if a.read_bytes()!=p.read_bytes():
  x=a.read_text();y=p.read_text();rel='src/'+p.relative_to(P).as_posix();(OUT/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)));changes.append({'file':rel,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(y.splitlines())-len(x.splitlines())})
cfg=json.loads((BASE.parent/'workflow.json').read_text());cfg['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(cfg,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-alias-lambda-cursor.md','changes':changes},indent=2)+'\n');print(OUT)
