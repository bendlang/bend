#!/usr/bin/env python3
from pathlib import Path
import difflib,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-span-source-01/project';OUT=ROOT/'selfhost/build/phase16/parser-span-source-02';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def change(file,a,b):
 p=P/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
p=OUT/'project/tools/typed-driver.mjs';s=p.read_text();assert s.count("const roots=['f_parse',")==1;p.write_text(s.replace("const roots=['f_parse',","const roots=['f_parse_indexed','f_parse',"))
# Attach only actual producer ranges; parenthesized terms retain their inner span.
change('front/parser.bend','def f_atom(ts):\n  f_choose','def f_atom_raw(+ts: List<&2,FToken>) -> FParsed:\n  f_choose')
p=P/'front/parser.bend';p.write_text(p.read_text()+'''
@unsafe
def f_atom(ts):
  f_locate(f_atom_raw(ts), f_begin(ts), f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind") || f_eq(f_tx(ts), "++"), f_eq(f_tx(ts), "@") || (f_eq(f_tx(ts), "&") && Bool.not(f_eq(f_tx(f_tl(ts)), "0") || f_eq(f_tx(f_tl(ts)), "1") || f_eq(f_tx(f_tl(ts)), "2"))) || f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind"))

@unsafe
def f_locate(+p: FParsed, +begin: U32, +force: Bool, +spaced: Bool) -> FParsed:
  match p:
    case FParsed{n, ts}:
      FParsed{f_choose(KTerm, U32.is_eq(begin, 0) || f_eq(tg(n), "Error") || (U32.is_gt(kb(n), 0) && Bool.not(force)), u => n, u => k_with_span(n, begin, f_choose(U32, spaced, u => f_begin(f_space(ts)), u => f_previous_end(ts)))), ts}

@unsafe
def f_family_range(+p: FParsed, +end: U32) -> FParsed:
  match p:
    case FParsed{n, ts}: FParsed{k_with_span(n, end, end), ts}
''')
change('front/parser.bend','u => f_arg_next(FParsed{n, ts}, ">", Nil{})))','u => f_family_range(f_arg_next(FParsed{n, ts}, ">", Nil{}), f_begin(f_space(ts)))))')
change('front/parser.bend','u => kt("Call", "", 0, 1, Con{n, ks(args)}), u => kt("ADT", nm(n), ix(n), qt(n), ks(args))','u => kt_span("Call", "", 0, 1, Con{n, ks(args)}, kb(n), f_previous_end(ts)), u => kt_span("ADT", nm(n), ix(n), qt(n), ks(args), kb(n), f_choose(U32, U32.is_gt(ke(args), 0), u => ke(args), u => f_previous_end(ts)))')
change('front/parser.bend','f_binary_plain(a, op, b), ts','k_with_span(f_binary_plain(a, op, b), kb(a), f_choose(U32, f_eq(op, "=>"), u => ke(a), u => f_begin(f_space(ts)))), ts')
# Parameter position is the name after any quantity prefix, as upstream tele spans.
change('front/declarations.bend','law f_tele_type:\n  for +name: String\n  for +id: U32\n  for +q: U32','law f_tele_type:\n  for +binder: KTerm')
change('front/declarations.bend','def f_tele_binder(\n  +name: String,\n  +id: U32,\n  +q: U32,','def f_tele_binder(\n  +binder: KTerm,')
change('front/declarations.bend','f_tele_type(name, id, q, temp, f_expr(f_tl(ts), 0), end, acc), u => f_choose(FParsed, U32.is_eq(q, 1) && Bool.not(temp), u => f_tele_type(name, id, 0, temp, FParsed{atom("Qnt"), ts}, end, acc)','f_tele_type(binder, temp, f_expr(f_tl(ts), 0), end, acc), u => f_choose(FParsed, U32.is_eq(qt(binder), 1) && Bool.not(temp), u => f_tele_type(kt_span(tg(binder), nm(binder), ix(binder), 0, Nil{}, kb(binder), ke(binder)), temp, FParsed{k_with_span(atom("Qnt"), kb(binder), ke(binder)), ts}, end, acc)')
change('front/declarations.bend','def f_tele_type(name, id, q, temp, p, end, acc):','def f_tele_type(binder, temp, p, end, acc):')
change('front/declarations.bend','kt(f_choose(String, temp, u => "Template", u => "Bind"), name, id, q, [ty])','kt_span(f_choose(String, temp, u => "Template", u => "Bind"), nm(binder), ix(binder), qt(binder), [ty], kb(binder), ke(binder))')
change('front/validate.bend','f_tele_binder(f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts),','f_tele_binder(kt_span("Bind", f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts), Nil{}, f_begin(f_unmark(ts)), f_end(f_unmark(ts))),')
change('front/declarations.bend','kt("All", nm(p), ix(p), qt(p), [kid(p, 0), f_tbind(ps, result)])','kt_span("All", nm(p), ix(p), qt(p), [kid(p, 0), f_tbind(ps, result)], kb(p), ke(p))')
change('front/declarations.bend','kt("Lam", nm(p), ix(p), qt(p), [f_lbind(ps, body)])','kt_span("Lam", nm(p), ix(p), qt(p), [f_lbind(ps, body)], kb(p), ke(p))')
change('front/declarations.bend','kt("Ref", nm(p), ix(p), qt(p), Nil{})','kt_span("Ref", nm(p), ix(p), qt(p), Nil{}, kb(p), ke(p))')
# Law clauses and their generated binders retain the original declared name.
change('front/declarations.bend','f_quant(ts), Nil{}), f_expr(f_tl(f_tl(f_unmark(ts))), 0)','f_quant(ts), Nil{}, f_begin(f_unmark(ts)), f_end(f_unmark(ts))), f_expr(f_tl(f_tl(f_unmark(ts))), 0)')
change('front/declarations.bend','f_law_type(name, kt(f_choose(String, exi','f_law_type(name, kt_span(f_choose(String, exi')
change('front/declarations.bend','kt(tg(binder), nm(binder), ix(binder), qt(binder), [ty])','k_with_children(binder, [ty])')
change('front/declarations.bend','kt("All", nm(c), ix(c), qt(c), [kid(c, 0), f_law_bind(cs, ty)])','kt_span("All", nm(c), ix(c), qt(c), [kid(c, 0), f_law_bind(cs, ty)], kb(c), ke(c))')
change('front/declarations.bend','kt("Lam", nm(c), ix(c), 1, [f_law_bind(cs, ty)])','kt_span("Lam", nm(c), ix(c), 1, [f_law_bind(cs, ty)], kb(c), ke(c))')
change('front/parallel.bend','kt("Bind", nm(p), ix(p), qt(p), [terms_at(vals, 0)])','kt_span("Bind", nm(p), ix(p), qt(p), [terms_at(vals, 0)], kb(p), ke(p))')
change('front/parallel.bend','kt("Let", "", 0, 1, norm_join(f_parallel_binds(ks(kid(t, 0)), ks(kid(t, 1))), [f_unlamb(f_flat(kid(t, 2), ks(kid(t, 0))), terms_len(ks(kid(t, 0))))]))','kt_span("Let", "", 0, 1, norm_join(f_parallel_binds(ks(kid(t, 0)), ks(kid(t, 1))), [f_unlamb(f_flat(kid(t, 2), ks(kid(t, 0))), terms_len(ks(kid(t, 0))))]), kb(t), ke(t))')
change('front/sugar.bend','kt("Ref", f_tx(ts), f_atid(ts), 0, Nil{})','kt_span("Ref", f_tx(ts), f_atid(ts), 0, Nil{}, f_begin(ts), f_end(ts))')
changes=[]
for p in sorted((OUT/'project').rglob('*')):
 if not p.is_file():continue
 parent=BASE/p.relative_to(OUT/'project');before=parent.read_text();after=p.read_text()
 if before!=after:
  rel=p.relative_to(OUT/'project').as_posix();changes.append({'file':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(after.splitlines())-len(before.splitlines())});(OUT/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'changes':changes,'preparerSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(OUT)
