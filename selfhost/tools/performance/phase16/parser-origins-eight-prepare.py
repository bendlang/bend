#!/usr/bin/env python3
from pathlib import Path
import difflib,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-span-source-07/project';OUT=ROOT/'selfhost/build/phase16/parser-span-source-08';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def change(file,a,b):
 p=P/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
f='front/declarations.bend'
for a in ['f_match_heads(f_tl(ts), f_col(ts), Nil{})','f_match_heads(f_tl(ts), outer, Nil{})']:
 change(f,a,'f_locate('+a+', f_begin(ts), False{}, True{}, False{})')
change(f,'f_erased_local(f_tl(ts))','f_erased_local(f_tl(ts), f_begin(ts))')
change(f,'f_app(kt("Ref", "Exists", 0, 1, Nil{}), [kid(c, 0), kt_span("Lam", nm(c), ix(c), 1, [f_law_bind(cs, ty)], kb(c), ke(c))])','f_app_span(kt_span("Ref", "Exists", 0, 1, Nil{}, kb(c), ke(c)), [kid(c, 0), kt_span("Lam", nm(c), ix(c), 1, [f_law_bind(cs, ty)], kb(c), ke(c))], kb(c), ke(c))')
change('front/parser.bend','f_do_start(f_tl(ts))','f_do_start(f_tl(ts), f_begin(ts))')
p=P/'front/sugar.bend';s=p.read_text();s=re.sub(r'law f_do_\w+:\n(?:  [^\n]*\n)+\n','',s)
start=s.index('@unsafe\ndef f_do_start(');end=s.index('@unsafe\ndef f_error_term(',start)
s=s[:start]+r'''# A single located monad term carries both the header name and type arguments.
@unsafe
def f_do_start(+ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_do_named(f_space(ts), begin)

@unsafe
def f_do_named(+ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_choose(FParsed, f_valid_name(f_tx(ts)), u => f_do_parameters(f_tx(ts), f_space(f_tl(ts)), begin), u => fpe_name_error(ts))

@unsafe
def f_do_parameters(+name: String, +ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "<>"), u => f_do_types(name, FParsed{kt("Args", "", 0, 1, Nil{}), f_tl(ts)}, begin), u => f_choose(FParsed, f_eq(f_tx(ts), "<"), u => f_do_parameters_open(name, f_space(f_tl(ts)), begin), u => fpe_error(ts, "expected <", "'<'")))

@unsafe
def f_do_parameters_open(+name: String, +ts: List<&2,FToken>, +begin: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ";"), u => fpe_error(ts, "expected term", "a term"), u => f_choose(FParsed, f_eq(f_tx(ts), ">") || f_eq(f_tx(ts), ">op"), u => f_do_types(name, FParsed{kt("Args", "", 0, 1, Nil{}), f_tl(ts)}, begin), u => f_do_types(name, f_args(ts, ">", Nil{}), begin)))

@unsafe
def f_do_bind_types(+types: List<&2,KTerm>, +ty: KTerm) -> List<&2,KTerm>:
  match types:
    case Nil{}: [ty]
    case Con{head, rest}: norm_join(f_init(types), [ty, f_last(types)])

@unsafe
def f_do_types(+name: String, +p: FParsed, +begin: U32) -> FParsed:
  match p:
    case FParsed{types, ts}:
      f_choose(FParsed, f_eq(tg(types), "Error"), u => FParsed{types, ts}, u => f_do_types_at(kt_span("ADT", name, 0, 1, ks(types), begin, f_previous_end(ts)), f_space(ts)))

@unsafe
def f_do_types_at(+monad: KTerm, +ts: List<&2,FToken>) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), ":"), u => f_do(monad, f_skip(f_tl(ts)), f_col(f_skip(f_tl(ts)))), u => f_err(ts, "expected :"))

@unsafe
def f_do(+monad: KTerm, +ts: List<&2,FToken>, +indent: U32) -> FParsed:
  f_choose(FParsed, f_eq(f_tx(ts), "return"), u => f_do_return(monad, f_atid(ts), f_begin(ts), f_expr(f_tl(ts), 0)), u => f_do_statement(monad, f_expr(ts, 0), indent))

@unsafe
def f_do_return(+monad: KTerm, +position: U32, +begin: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{n, ts}:
      FParsed{kt_span("FDo", nm(monad), position, 1, [kt_span("ADT", nm(monad), position, 1, ks(monad), kb(monad), ke(monad)), n], begin, f_begin(f_space(ts))), ts}

@unsafe
def f_do_statement(+monad: KTerm, +p: FParsed, +indent: U32) -> FParsed:
  match p:
    case FParsed{+n, +ts}:
      f_choose(FParsed, f_eq(f_tx(ts), ":") && f_eq(tg(n), "Ref") && f_alias_valid(nm(n)), u => f_do_annotated(monad, n, f_expr(f_tl(ts), 1), indent), u => f_choose(FParsed, f_eq(f_tx(ts), "<-"), u => f_do_value(monad, kt_span("Ref", "_", ix(n), 1, Nil{}, kb(n), ke(n)), n, False{}, f_expr(f_tl(ts), 0), indent), u => f_choose(FParsed, (f_eq(f_tx(ts), ";") || U32.is_eq(f_col(f_skip(ts)), indent)) && Bool.not(f_eq(f_tx(f_skip(ts)), "<eof>")), u => f_do_value(monad, kt_span("Ref", "_", ix(n), 1, Nil{}, kb(n), ke(n)), k_with_span(ref("Unit"), kb(n), ke(n)), False{}, FParsed{n, ts}, indent), u => FParsed{kt_span("FDo", nm(monad), ix(n), 0, [kt_span("ADT", nm(monad), ix(n), 1, ks(monad), kb(monad), ke(monad)), n], kb(n), ke(n)), ts})))

@unsafe
def f_do_annotated(+monad: KTerm, +binder: KTerm, +p: FParsed, +indent: U32) -> FParsed:
  match p:
    case FParsed{ty, +ts}:
      f_choose(FParsed, f_eq(tg(ty), "Error"), u => FParsed{ty, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), "=") || f_eq(f_tx(ts), "<-"), u => f_do_value(monad, binder, ty, f_eq(f_tx(ts), "="), f_expr(f_tl(ts), 0), indent), u => f_err(ts, "expected <-")))

@unsafe
def f_do_value(+monad: KTerm, +binder: KTerm, +ty: KTerm, +pure: Bool, +p: FParsed, +indent: U32) -> FParsed:
  match p:
    case FParsed{v, ts}:
      +end = f_choose(U32, f_eq(f_tx(f_space(ts)), ";"), u => f_end(f_space(ts)), u => f_begin(f_space(ts)))
      f_do_tail(monad, binder, ty, pure, v, end, f_do(monad, f_skip(ts), indent))

@unsafe
def f_do_tail(+monad: KTerm, +binder: KTerm, +ty: KTerm, +pure: Bool, +v: KTerm, +end: U32, +p: FParsed) -> FParsed:
  match p:
    case FParsed{body, ts}:
      FParsed{f_choose(KTerm, pure, u => kt_span("Local", "Do", 0, 1, [binder, kt_span("Ann", "", 0, 1, [v, ty], kb(binder), end), body], kb(binder), end), u => kt_span("FDo", nm(monad), ix(binder), 2, [kt_span("ADT", nm(monad), ix(binder), 1, ks(monad), kb(monad), ke(monad)), ty, v, kt_span("Lam", nm(binder), ix(binder), qt(binder), [body], kb(binder), end)], kb(binder), end)), ts}

''' +s[end:]
s=s.replace('law f_erased_local:\n  for +ts: List<&2, FToken>','law f_erased_local:\n  for +ts: List<&2, FToken>\n  for +begin: U32').replace('def f_erased_local(ts):','def f_erased_local(ts, begin):').replace('kt_span("Ref", f_tx(ts), f_atid(ts), 0, Nil{}, f_begin(ts), f_end(ts))','kt_span("Ref", f_tx(ts), f_atid(ts), 0, Nil{}, begin, f_end(ts))')
a='f_app(ref("Exists"), [ty, kt("Lam", nm(binder), ix(binder), 1, [predicate])])';b='f_app_span(k_with_span(ref("Exists"), kb(binder), ke(binder)), [ty, kt_span("Lam", nm(binder), ix(binder), 1, [predicate], kb(binder), ke(binder))], kb(binder), ke(binder))';assert s.count(a)==1;s=s.replace(a,b);p.write_text(s)
changes=[]
for p in sorted(P.rglob('*.bend')):
 before=(BASE/'src'/p.relative_to(P)).read_text();after=p.read_text()
 if before!=after:
  rel='src/'+p.relative_to(P).as_posix();changes.append({'file':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(after.splitlines())-len(before.splitlines())});(OUT/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'changes':changes,'preparerSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(OUT)
