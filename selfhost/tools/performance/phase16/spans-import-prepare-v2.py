#!/usr/bin/env python3
from pathlib import Path
import ast,shutil,json,hashlib,difflib
R=Path(__file__).resolve().parents[4]
oldtool=R/'selfhost/tools/performance/phase16/spans-import-prepare.py'
module=ast.parse(oldtool.read_text());env={};exec(compile(ast.Module(body=[n for n in module.body if isinstance(n,ast.FunctionDef)],type_ignores=[]),str(oldtool),'exec'),env)
base=R/'selfhost/build/phase16/wave4-source-02/project';out=R/'selfhost/build/phase16/spans-import-source-02';out.mkdir();P=out/'project';shutil.copytree(base,P);changes=[];rep=env['rep']
for rel,name in [('src/front/parser.bend','parser'),('src/front/declarations.bend','declarations'),('src/load/imports.bend','imports'),('src/front/validate.bend','validate'),('src/load/graph.bend','graph')]:
 p=P/rel;a=p.read_text();b=env[name](a)
 if name=='parser':
  b=rep(b,'dg_snippet(DSpan{source, offset, end})','fpe_snippet(source, offset, end, error)')
  b=b.replace('dg_module_snippet(DSpan{source, U32.sub(kb(error), start), U32.sub(ke(error), start)})','fpe_snippet(source, U32.sub(kb(error), start), U32.sub(ke(error), start), error)')
  b=b.replace('dg_snippet(DSpan{source, U32.sub(kb(error), start), U32.sub(ke(error), start)})','fpe_snippet(source, U32.sub(kb(error), start), U32.sub(ke(error), start), error)')
  b+='''\n@unsafe\ndef fpe_snippet(+source: String, +begin: U32, +end: U32, +error: KTerm) -> String:\n  f_choose(String, f_eq(tg(kid(error, 2)), "ParseLine") || f_eq(tg(kid(error, 3)), "ParseRaw"),\n    u => dg_snippet(DSpan{source, begin, end}),\n    u => dg_module_snippet(DSpan{source, begin, end}))\n'''
 if name=='imports':
  b=rep(b,'path ++ f_tx(ts), book, imports, header','path ++ f_import_token_text(ts), book, imports, header')
  b+='''\n# These spellings are the explicit normalized symbol variants of f_lex_symbol.\n@unsafe\ndef f_import_token_text(+ts: List<&2,FToken>) -> String:\n  f_choose(String, f_eq(f_tx(ts), "+bind"), u => "+",\n    u => f_choose(String, f_eq(f_tx(ts), ">op"), u => ">",\n      u => f_choose(String, f_eq(f_tx(ts), ">>op"), u => ">>", u => f_tx(ts))))\n\n@unsafe\ndef f_import_raw(+error: KTerm) -> KTerm:\n  k_with_children(error, [kid(error, 0), kid(error, 1), kid(error, 2), atom("ParseRaw")])\n'''
 if name=='validate':
  b=rep(b,'f_pn(fpe_span(start, start, "invalid import path", "an import path of plain names (letters, digits, _ and -; the hub\'s files import the hub\'s)", "\'" ++ path ++ "\'"))','f_import_raw(f_pn(fpe_span(start, start, "invalid import path", "an import path of plain names (letters, digits, _ and -; the hub\'s files import the hub\'s)", "\'" ++ path ++ "\'")))')
  b=rep(b,'f_pn(fpe_span(start, start, "an import requires a .bend path and a valid alias", "an import of a .bend file", "\'" ++ path ++ "\'"))','f_import_raw(f_pn(fpe_span(start, start, "an import requires a .bend path and a valid alias", "an import of a .bend file", "\'" ++ path ++ "\'")))')
 if name=='declarations':
  start=b.index('def f_named_top(');end=b.index('\n\n@unsafe',start);block=b[start:end]
  needle='    u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), book)), "Missing"))'
  replacement='    u => f_choose(FRawResult, Bool.not(f_eq(f_alias(f_tx(ts), imports), f_tx(ts))), u => f_result(book, f_pn(fpe_word(ts, "an import alias cannot name a new declaration", "a fresh name (" ++ f_import_alias_head(f_tx(ts)) ++ " is an import\'s alias)")), imports),\n    u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), book)), "Missing"))'
  block=rep(block,needle,replacement)+')';b=b[:start]+block+b[end:]
 assert b!=a;p.write_text(b);changes.append({'relative':rel,'before':hashlib.sha256(a.encode()).hexdigest(),'after':hashlib.sha256(b.encode()).hexdigest()});(out/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='a/'+rel,tofile='b/'+rel)))
for t in [Path(__file__),oldtool]:shutil.copy2(t,out/t.name)
(out/'workflow.json').write_text(json.dumps({'project':str(P),'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'cpu':'2','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'baseline':str(base),'project':str(P),'design':str(R/'design/phase16/import-diagnostics.md'),'changes':changes,'tools':[{'file':str(t),'sha256':hashlib.sha256(t.read_bytes()).hexdigest()}for t in [Path(__file__),oldtool]]},indent=2)+'\n');print(P)
