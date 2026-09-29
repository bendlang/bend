#!/usr/bin/env python3
from pathlib import Path
import difflib,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-span-source-02/project';OUT=ROOT/'selfhost/build/phase16/parser-span-source-03';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def change(file,a,b):
 p=P/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
f='front/parser.bend'
change(f,'law f_binary:\n  for +a: KTerm\n  for +op: String','law f_binary:\n  for +a: KTerm\n  for +op: String\n  for +opBegin: U32\n  for +opEnd: U32')
change(f,'f_binary(n, f_tx(ts), min,','f_binary(n, f_tx(ts), f_begin(ts), f_end(ts), min,')
change(f,'def f_binary(a, op, min, p):','def f_binary(a, op, opBegin, opEnd, min, p):')
change(f,'k_with_span(f_binary_plain(a, op, b), kb(a), f_choose(U32, f_eq(op, "=>"), u => ke(a), u => f_begin(f_space(ts))))','f_binary_plain(a, op, b, opBegin, opEnd, kb(a), f_begin(f_space(ts)))')
change(f,'law f_binary_plain:\n  for +a: KTerm\n  for +op: String\n  for +b: KTerm\n  KTerm','law f_binary_plain:\n  for +a: KTerm\n  for +op: String\n  for +b: KTerm\n  for +opBegin: U32\n  for +opEnd: U32\n  for +begin: U32\n  for +end: U32\n  KTerm')
change(f,'''def f_binary_plain(a, op, b):
  f_choose(KTerm, f_eq(op, "=>"), u => f_lambda_valid(a, b),
    u => f_choose(KTerm, f_eq(op, "->"), u => kt("All", "_", ix(a), 1, [a, b]),
    u => f_choose(KTerm, f_eq(op, "<>"), u => kt("Ctr", "Con", 0, 1, [a, b]),
    u => f_choose(KTerm, f_eq(op, "<&>"), u => kt("Min", "", 0, 1, [a, b]),
    u => f_app(kt("Ref", f_operator(op), 0, 1, Nil{}), [a, b])))))''','''def f_binary_plain(a, op, b, opBegin, opEnd, begin, end):
  f_choose(KTerm, f_eq(op, "=>"), u => k_with_span(f_lambda_valid(a, b), kb(a), ke(a)),
    u => f_choose(KTerm, f_eq(op, "->"), u => kt_span("All", "_", ix(a), 1, [a, b], begin, end),
    u => f_choose(KTerm, f_eq(op, "<>"), u => kt_span("Ctr", "Con", 0, 1, [a, b], begin, end),
    u => f_choose(KTerm, f_eq(op, "<&>"), u => kt_span("Min", "", 0, 1, [a, b], begin, end),
    u => f_app_span(kt_span("Ref", f_operator(op), 0, 1, Nil{}, f_choose(U32, f_eq(op, "&") || f_eq(op, "|"), u => begin, u => opBegin), f_choose(U32, f_eq(op, "&") || f_eq(op, "|"), u => end, u => opEnd)), [a, b], begin, end)))))''')
# Use the trailing whitespace cursor for immediate natural offset expressions.
change(f,'|| f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind"))\n\n@unsafe\ndef f_locate', '|| f_eq(f_tx(ts), "+") || f_eq(f_tx(ts), "+bind") || (String.ends_with(f_tx(ts), "n") && f_eq(f_tx(f_tl(ts)), "+")), f_eq(f_tx(ts), "[") || f_eq(f_tx(ts), "(") || f_eq(f_tx(ts), "&") || f_eq(f_tx(ts), "\\\\"))\n\n@unsafe\ndef f_locate')
change(f,'+force: Bool, +spaced: Bool) -> FParsed:', '+force: Bool, +spaced: Bool, +created: Bool) -> FParsed:')
change(f,'u => k_with_span(n, begin, f_choose(U32, spaced, u => f_begin(f_space(ts)), u => f_previous_end(ts))))','u => f_located_term(n, begin, f_choose(U32, spaced, u => f_begin(f_space(ts)), u => f_previous_end(ts)), created)))')
p=P/f;p.write_text(p.read_text()+'''
# Only explicitly desugared list/tuple/existential/matcher trees use this walk.
# Existing child origins are boundaries, so parsed subtrees are never revisited.
@unsafe
def f_located_term(+t: KTerm, +begin: U32, +end: U32, +created: Bool) -> KTerm:
  f_choose(KTerm, created, u => f_span_created(t, begin, end), u => k_with_span(t, begin, end))

@unsafe
def f_span_created(+t: KTerm, +begin: U32, +end: U32) -> KTerm:
  f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(kb(t), 0), u => t, u => k_with_span(k_with_children(t, f_spans_created(ks(t), begin, end)), begin, end))

@unsafe
def f_spans_created(+terms: List<&2,KTerm>, +begin: U32, +end: U32) -> List<&2,KTerm>:
  match terms:
    case Nil{}: Nil{}
    case Con{term, rest}: Con{f_span_created(term, begin, end), f_spans_created(rest, begin, end)}

@unsafe
def f_app_span(+f: KTerm, +xs: List<&2,KTerm>, +begin: U32, +end: U32) -> KTerm:
  match xs:
    case Nil{}: f
    case Con{x, rest}: f_app_span(kt_span("App", "", 0, 1, [f, x], begin, end), rest, begin, end)
''')
f='front/literals_arrays.bend'
change(f,'u => f_power_depth(nm(size), 0),','u => k_with_span(f_power_depth(nm(size), 0), kb(size), ke(size)),')
change(f,'law f_index_value:\n  for +n: KTerm\n  for +idx: KTerm','law f_index_value:\n  for +n: KTerm\n  for +idx: KTerm\n  for +end: U32')
change(f,'u => f_index_value(n, idx, f_expr(f_tl(ts), 2), min), u => f_grow(FParsed{f_app(ref("Array.get"), [ref("U32"), n, f_namespace(idx, ref("U32"))]), ts}, min)','u => f_index_value(n, idx, f_previous_end(ts), f_expr(f_tl(ts), 2), min), u => f_grow(FParsed{f_app_span(k_with_span(ref("Array.get"), kb(n), f_previous_end(ts)), [k_with_span(ref("U32"), kb(n), f_previous_end(ts)), n, f_namespace(idx, ref("U32"))], kb(n), f_previous_end(ts)), ts}, min)')
change(f,'def f_index_value(n, idx, p, min):','def f_index_value(n, idx, end, p, min):')
change(f,'u => kt("Write", nm(n), ix(n), 1, [f_app(ref("Array.set"), [ref("U32"), n, f_namespace(idx, ref("U32")), v])]), u => f_app(ref("Array.set"), [ref("U32"), n, f_namespace(idx, ref("U32")), v]))','u => kt_span("Write", nm(n), ix(n), 1, [f_app_span(k_with_span(ref("Array.set"), kb(n), end), [k_with_span(ref("U32"), kb(n), end), n, f_namespace(idx, ref("U32")), v], kb(n), end)], kb(n), end), u => f_app_span(k_with_span(ref("Array.set"), kb(n), end), [k_with_span(ref("U32"), kb(n), end), n, f_namespace(idx, ref("U32")), v], kb(n), end))')
changes=[]
for p in sorted(P.rglob('*.bend')):
 before=(BASE/'src'/p.relative_to(P)).read_text();after=p.read_text()
 if before!=after:
  rel='src/'+p.relative_to(P).as_posix();changes.append({'file':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(after.splitlines())-len(before.splitlines())});(OUT/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'changes':changes,'preparerSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(OUT)
