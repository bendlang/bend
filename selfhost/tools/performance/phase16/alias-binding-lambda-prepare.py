#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4]; BASE=ROOT/'selfhost/build/phase16/alias-binding-source-02/project'; OUT=ROOT/'selfhost/build/phase16/alias-binding-source-03'; OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def edit(f,a,b):
 p=P/f;s=p.read_text();assert s.count(a)==1,(f,a,s.count(a));p.write_text(s.replace(a,b))
edit('front/parser.bend','f_eq(tg(b), "Error"), u => FParsed{b, ts}, u => f_grow(FParsed{f_binary_plain','f_eq(tg(b), "Error") && Bool.not(f_eq(op, "=>") && (String.contains(nm(a), ".") || Bool.not(f_eq(tg(a), "Ref") && f_valid_name(nm(a))))), u => FParsed{b, ts}, u => f_grow(FParsed{f_binary_plain')
edit('front/parser.bend','k_with_span(f_lambda_valid(a, b), kb(a), ke(a))','f_lambda_valid(a, b, opEnd)')
edit('front/validate.bend','law f_lambda_valid:\n  for +a: KTerm\n  for +body: KTerm\n  KTerm','law f_lambda_valid:\n  for +a: KTerm\n  for +body: KTerm\n  for +cursor: U32\n  KTerm')
edit('front/validate.bend','''def f_lambda_valid(a, body):
  f_choose(KTerm, f_eq(tg(a), "Ref") && f_valid_name(nm(a)), u => kt("Lam", nm(a), ix(a), qt(a), [body]), u => kt("Error", "a lambda binder must be a non-reserved name", 0, 0, Nil{}))''','''def f_lambda_valid(a, body, cursor):
  f_choose(KTerm, f_eq(tg(a), "Ref") && f_valid_name(nm(a)),
    u => f_choose(KTerm, String.contains(nm(a), "."),
      u => kt_span("FLambda", nm(a), ix(a), qt(a), [body, a, kt_span("LambdaCursor", "", 0, 0, Nil{}, cursor, cursor)], kb(a), ke(a)),
      u => kt_span("Lam", nm(a), ix(a), qt(a), [body], kb(a), ke(a))),
    u => fpe_point_at(kt_span("LambdaCursor", "", 0, 0, Nil{}, cursor, cursor), "a lambda binder must be a non-reserved name", "a lambda binder (one name: k => body)"))''')
edit('front/elaborate.bend','f_eq(tg(t), "Lam"), u => f_scope_lambda(t, env, book),','f_eq(tg(t), "Lam") || f_eq(tg(t), "FLambda"), u => f_scope_lambda_eligible(t, env, book),')
p=P/'front/families.bend';s=p.read_text();at=s.index('@unsafe\ndef f_scope_lambda(');s=s[:at]+'''@unsafe
def f_scope_lambda_eligible(+t: KTerm, +env: List<&2,KTerm>, +book: List<&2,KDef>) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "FLambda") && f_eq(tg(f_env(nm(t), env)), "Absent"),
    u => f_scope_lambda_refused(t, f_choose(KTerm, f_eq(tg(kid(t, 1)), "FAliasRef"), u => kid(kid(t, 1), 0), u => kid(t, 1))),
    u => f_scope_lambda(t, env, book))

@unsafe
def f_scope_lambda_refused(+t: KTerm, +ref: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(ref), "Error"), u => ref,
    u => fpe_point_at(kid(t, 2), "a lambda binder must be a non-reserved name", "a lambda binder (one name: k => body)"))

'''+s[at:];p.write_text(s)
changes=[]
for p in sorted(P.rglob('*.bend')):
 a=BASE/'src'/p.relative_to(P)
 if a.read_bytes()!=p.read_bytes():
  x=a.read_text();y=p.read_text();rel='src/'+p.relative_to(P).as_posix();(OUT/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)));changes.append({'file':rel,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(y.splitlines())-len(x.splitlines())})
cfg=json.loads((BASE.parent/'workflow.json').read_text());cfg['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(cfg,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-alias-lambda-cursor.md','changes':changes},indent=2)+'\n');print(OUT)
