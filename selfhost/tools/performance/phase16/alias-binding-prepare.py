#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/wave6-source-01/project';OUT=ROOT/'selfhost/build/phase16/alias-binding-source-01';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def edit(file,a,b):
 p=P/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
f='load/graph.bend';edit(f,'f_alias_named(t, imports, scope, f_choose(String, f_eq(tg(t), "Ref") || f_eq(tg(t), "ADT") || f_eq(tg(t), "Ctr") || f_eq(tg(t), "Mat"), u => f_alias(nm(t), imports), u => nm(t)))','f_alias_deferred(t, imports, scope, f_choose(String, f_eq(tg(t), "Ref") || f_eq(tg(t), "ADT") || f_eq(tg(t), "Ctr") || f_eq(tg(t), "Mat"), u => f_alias(nm(t), imports), u => nm(t)))')
p=P/f;s=p.read_text();point=s.index('@unsafe\ndef f_alias_named(');s=s[:point]+'''# An import alias is an alternative until the lexical scope has its say.
@unsafe
def f_alias_deferred(+t: KTerm, +imports: List<&2,KTerm>, +scope: List<&2,KDef>, +name: String) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Ref") && Bool.not(String.eq(name, nm(t))),
    u => kt_span("FAliasRef", nm(t), ix(t), qt(t), [f_alias_named(t, imports, scope, name)], kb(t), ke(t)),
    u => f_alias_named(t, imports, scope, name))

'''+s[point:];p.write_text(s)
f='front/elaborate.bend';p=P/f;s=p.read_text();a='''def f_patterns(
  +xs: List<&2, KTerm>,
) -> List<&2, KTerm>:''';b='''def f_patterns(
  +xs: List<&2, KTerm>,
  +env: List<&2,KTerm>,
) -> List<&2, KTerm>:''';assert s.count(a)==1;s=s.replace(a,b)
a='''Con{f_choose(KTerm, f_eq(tg(x), "Ref"), u => kt_span("Var", nm(x), ix(x), qt(x), Nil{}, kb(x), ke(x)), u => f_choose(KTerm, f_eq(tg(x), "Literal"), u => f_span_created(f_pattern_literal(nm(x)), kb(x), ke(x)), u => f_choose(KTerm, f_eq(tg(x), "Ctr"), u => k_with_children(x, f_patterns(ks(x))), u => x))), f_patterns(xt)}'''
b='''Con{f_choose(KTerm, f_eq(tg(x), "Ref") || (f_eq(tg(x), "FAliasRef") && Bool.not(f_eq(tg(f_env(nm(x), env)), "Absent"))), u => kt_span("Var", nm(x), ix(x), qt(x), Nil{}, kb(x), ke(x)), u => f_choose(KTerm, f_eq(tg(x), "FAliasRef"), u => kid(x, 0), u => f_choose(KTerm, f_eq(tg(x), "Literal"), u => f_span_created(f_pattern_literal(nm(x)), kb(x), ke(x)), u => f_choose(KTerm, f_eq(tg(x), "Ctr"), u => k_with_children(x, f_patterns(ks(x), env)), u => x)))), f_patterns(xt, env)}''';assert s.count(a)==1;s=s.replace(a,b)
for a,b in [('f_patterns([kid(t, 0)])','f_patterns([kid(t, 0)], env)'),('f_patterns(ks(kid(r, 0)))','f_patterns(ks(kid(r, 0)), env)')]:assert s.count(a)==1;s=s.replace(a,b)
a='''def f_scope(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "FDo"), u => f_scope_do(t, env, book), u => f_choose(KTerm, f_eq(tg(t), "Call"), u => f_scope_call(t, env, book), u => f_choose(KTerm, f_eq(tg(t), "TemplateArg"), u => kt("Error", "~ is only valid in a named template call", 0, 0, Nil{}), u => f_scope_lower(t, env, book))))''';b='''def f_scope(t, env, book):
  f_choose(KTerm, f_eq(tg(t), "FAliasRef"), u => f_scope_alias(t, f_env(nm(t), env), book, False{}), u => f_choose(KTerm, f_eq(tg(t), "FDo"), u => f_scope_do(t, env, book), u => f_choose(KTerm, f_eq(tg(t), "Call"), u => f_scope_call(t, env, book), u => f_choose(KTerm, f_eq(tg(t), "TemplateArg"), u => kt("Error", "~ is only valid in a named template call", 0, 0, Nil{}), u => f_scope_lower(t, env, book)))))''';assert s.count(a)==1;s=s.replace(a,b);s+='''
@unsafe
def f_scope_alias(+t: KTerm, +bound: KTerm, +book: List<&2,KDef>, +called: Bool) -> KTerm:
  f_scope_alias_selected(f_choose(KTerm, f_eq(tg(bound), "Absent"), u => kid(t, 0), u => kt_span("Ref", nm(t), ix(t), qt(t), Nil{}, kb(t), ke(t))), bound, book, called)

@unsafe
def f_scope_alias_selected(+t: KTerm, +bound: KTerm, +book: List<&2,KDef>, +called: Bool) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Error"), u => t,
    u => f_choose(KTerm, called, u => f_scope_marked(t, bound, f_find(nm(t), book), True{}), u => f_scope_reference(t, bound, book)))
''';p.write_text(s)
edit('front/parallel.bend','f_patterns(ks(kid(t, 0)))','f_patterns(ks(kid(t, 0)), env)')
f='front/families.bend';edit(f,'f_eq(tg(head), "Ref") && f_eq(tg(kid(t, 0)), "Ref")','f_eq(tg(head), "Ref") && (f_eq(tg(kid(t, 0)), "Ref") || f_eq(tg(kid(t, 0)), "FAliasRef"))')
a='''def f_scope_marked_call(+t: KTerm, +env: List<&2,KTerm>, +book: List<&2,KDef>) -> KTerm:
  f_choose(KTerm, f_eq(tg(t), "Call") && U32.is_eq(terms_len(ks(t)), 1), u => f_scope_marked_call(kid(t, 0), env, book),
    u => f_choose(KTerm, f_eq(tg(t), "Ref") && Bool.not(U32.is_eq(qt(t), 3)), u => f_scope_marked(t, f_env(nm(t), env), f_find(nm(t), book), True{}),
    u => f_choose(KTerm, f_eq(tg(t), "ADT"), u => f_adt(KTerm{tg(t), nm(t), ix(t), 2, ks(t), rm(t), kb(t), ke(t)}, f_scope_terms(ks(t), env, book), f_find(nm(t), book)),
    u => kt("Error", "a quantified datatype after + (+D<..> sets D's leading quantities to &2)", ix(t), 0, Nil{}))))''';b=a.replace('  f_choose(KTerm, f_eq(tg(t), "Call")','  f_choose(KTerm, f_eq(tg(t), "FAliasRef") && Bool.not(U32.is_eq(qt(t), 3)), u => f_scope_alias(t, f_env(nm(t), env), book, True{}), u => f_choose(KTerm, f_eq(tg(t), "Call")')+')';edit(f,a,b)
f='front/validate.bend';p=P/f;s=p.read_text();a='''def f_valid_pattern(+p: KTerm, +book: List<&2,KDef>) -> Maybe<&2,KTerm>:
  f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Var"),''';assert s.count(a)==1;s=s.replace(a,'''def f_valid_pattern(+p: KTerm, +book: List<&2,KDef>) -> Maybe<&2,KTerm>:
  f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Error"), u => Some{p}, u => f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Var"),''');a='kp_show(f_scope(p, Nil{}, book)))}))';assert s.count(a)==1;s=s.replace(a,'kp_show(f_scope(p, Nil{}, book)))})))');p.write_text(s)
changes=[]
for p in sorted(P.rglob('*.bend')):
 a=BASE/'src'/p.relative_to(P)
 if a.read_bytes()!=p.read_bytes():
  x=a.read_text();y=p.read_text();rel='src/'+p.relative_to(P).as_posix();patch=OUT/(rel.replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)));changes.append({'file':rel,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(y.splitlines())-len(x.splitlines())})
config={'project':str(OUT/'project'),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000};(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-alias-lexical-bindings.md','changes':changes},indent=2)+'\n');print(OUT)
