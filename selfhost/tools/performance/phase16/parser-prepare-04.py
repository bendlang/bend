#!/usr/bin/env python3
"""Shared token-based name errors and first-error propagation."""
from pathlib import Path
import difflib,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'selfhost/build/phase16/parser-source-03'
OUT=ROOT/'selfhost/build/phase16/parser-source-04';OUT.mkdir();PROJECT=OUT/'project';shutil.copytree(BASE/'project',PROJECT)
changes=[]
def once(s,a,b):
 assert s.count(a)==1,(a,s.count(a))
 return s.replace(a,b)
def edit(name,fn):
 p=PROJECT/'src/front'/name;before=p.read_text();s=fn(before);assert s!=before;p.write_text(s)
 (OUT/(name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),s.splitlines(True),fromfile='stage2/'+name,tofile='stage3/'+name)))
 changes.append({'file':name,'before':hashlib.sha256(before.encode()).hexdigest(),'after':hashlib.sha256(s.encode()).hexdigest(),'physicalLinesDelta':len(s.splitlines())-len(before.splitlines())})
def parser(s):
 s=once(s,'f_expr_after(f_expect(FParsed{a, ts}, ":"))','f_expr_after(f_expect(FParsed{a, ts}, ":"), 0)')
 s=once(s,'def f_expr_after(+p: FParsed) -> FParsed:', 'def f_expr_after(+p: FParsed, +min: U32) -> FParsed:')
 s=once(s,'case FParsed{n, ts}: f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_expr(ts, 0))','case FParsed{n, ts}: f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_expr(ts, min))')
 a=s.index('def f_all(ts, exi):');b=s.index('\n\n@unsafe',a)
 s=s[:a]+'''def f_all(ts, exi):
  f_choose(FParsed, Bool.not(f_valid_name(f_tx(f_unmark(ts)))) || f_eq(f_tx(ts), "~"), u => fpe_name_error(f_unmark(ts)), u => f_all_domain(f_tx(f_unmark(ts)), f_atid(ts), f_quant(ts), exi, f_expect(f_expr_after(f_expect(FParsed{atom("Absent"), f_tl(f_unmark(ts))}, ":"), 1), "->")))'''+s[b:]
 s=once(s,'u => f_err(ts, "expected term"), u => fpe_error(ts, "expected term", "a term")','u => f_choose(FParsed, f_eq(f_tx(ts), "return"), u => fpe_word(ts, "return outside do", "a do-block heading this return"), u => fpe_error(ts, "expected term", "a term")), u => fpe_error(ts, "expected term", "a term")')
 s=once(s,'      f_equation_type(a, b, neg, f_expect(f_expr(ts, 0), "}"))','      f_choose(FParsed, f_eq(tg(b), "Error"), u => FParsed{b, ts}, u => f_equation_type(a, b, neg, f_expect(f_expr(ts, 0), "}")))')
 s=once(s,'      f_grow(FParsed{f_binary_plain(a, op, b), ts}, min)','      f_choose(FParsed, f_eq(tg(b), "Error"), u => FParsed{b, ts}, u => f_grow(FParsed{f_binary_plain(a, op, b), ts}, min))')
 s+='''
@unsafe
def fpe_name_error(+ts: List<&2,FToken>) -> FParsed:
  f_choose(FParsed, f_ascii_alpha(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_'),
    u => fpe_word(ts, "invalid name", f_choose(String, f_reserved(f_tx(ts)), u => "a name (got the keyword '" ++ f_tx(ts) ++ "')", u => "a name (words joined by dots, got '" ++ f_tx(ts) ++ "')")),
    u => fpe_error(ts, "expected a name", "a name"))
'''
 return s
def declarations(s):
 s=once(s,'f_expr_after(f_expect(FParsed{pars, ts}, "is"))','f_expr_after(f_expect(FParsed{pars, ts}, "is"), 0)')
 s=once(s,'f_law(f_tx(f_tl(ts)), f_skip(f_tl(f_tl(f_tl(ts)))), book, imports, Nil{})','f_named_top(f_space(f_tl(ts)), book, imports, False{})')
 s=once(s,'f_type(f_tx(f_tl(ts)), f_tl(f_tl(ts)), book, imports)','f_named_top(f_space(f_tl(ts)), book, imports, True{})')
 s=once(s,'fpe_word(ts, "invalid definition name", "a name (words joined by dots, got \'" ++ f_tx(ts) ++ "\')")','fpe_name_error(ts)')
 s=once(s,'u => f_err(ts, "expected : (a marked parameter requires its type)")))','u => fpe_error(ts, "expected : (a marked parameter requires its type)", "\':\'")))')
 s=once(s,'      f_let_body(pat, v, f_body(ts))','      f_choose(FParsed, f_eq(tg(v), "Error"), u => FParsed{v, ts}, u => f_let_body(pat, v, f_body(ts)))')
 s=once(s,'      FParsed{kt("Local", "", 0, 1, [pat, v, b]), ts}','      FParsed{f_choose(KTerm, f_eq(tg(b), "Error"), u => b, u => kt("Local", "", 0, 1, [pat, v, b])), ts}')
 s+='''
@unsafe
def f_named_top(+ts: List<&2,FToken>, +book: List<&2,KDef>, +imports: List<&2,KTerm>, +datatype: Bool) -> FRawResult:
  f_choose(FRawResult, Bool.not(f_valid_name(f_tx(ts))), u => f_result(book, f_pn(fpe_name_error(ts)), imports),
    u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), book)), "Missing")), u => f_result(book, f_pn(fpe_word(ts, "duplicate declaration", "a fresh name (duplicate declaration: " ++ f_tx(ts) ++ ")")), imports),
      u => f_choose(FRawResult, datatype, u => f_type(f_tx(ts), f_tl(ts), book, imports), u => f_law_header(f_tx(ts), f_expect(FParsed{atom("Absent"), f_space(f_tl(ts))}, ":"), book, imports))))

@unsafe
def f_law_header(+name: String, +p: FParsed, +book: List<&2,KDef>, +imports: List<&2,KTerm>) -> FRawResult:
  match p:
    case FParsed{n, ts}: f_choose(FRawResult, f_eq(tg(n), "Error"), u => f_result(book, n, imports), u => f_law(name, f_skip(ts), book, imports, Nil{}))
'''
 return s
def validate(s):
 s=once(s,'u => f_err(ts, "~ is only allowed on def or law template parameters")','u => fpe_name_error(ts)')
 s=once(s,'u => f_err(ts, "reserved parameter name")','u => fpe_name_error(f_choose(List<&2,FToken>, f_eq(f_tx(ts), "->"), u => Con{FToken{">", f_line(ts), U32.add(f_col(ts), 1), 0}, f_tl(ts)}, u => f_unmark(ts)))')
 s=once(s,'fpe_error(f_unmark(ts), "duplicate constructor field",','fpe_word(f_unmark(ts), "duplicate constructor field",')
 s=once(s,'u => f_err(ts, "only leading parameters may use ~")','u => fpe_error(ts, "only leading parameters may use ~", "a plain binder (only leading binders take ~)")')
 return s
def sugar(s):
 return once(s,'u => f_err(ts, "expected a name"))','u => fpe_name_error(ts))')
edit('parser.bend',parser);edit('declarations.bend',declarations);edit('validate.bend',validate);edit('sugar.bend',sugar)
config=json.loads((BASE/'workflow.json').read_text());config['project']=str(PROJECT);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'inputs':[identity(Path(__file__)),identity(BASE/'manifest.json'),identity(ROOT/'experiments/phase16/P16-parser-names.md')],'changes':changes,'config':identity(OUT/'workflow.json')},indent=2)+'\n');print(OUT)
