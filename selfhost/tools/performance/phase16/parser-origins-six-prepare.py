#!/usr/bin/env python3
from pathlib import Path
import difflib,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-span-source-05/project';OUT=ROOT/'selfhost/build/phase16/parser-span-source-06';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def change(file,a,b):
 p=P/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
f='front/parser.bend'
change(f,'law f_equation:\n  for +a: KTerm\n  for +neg: Bool','law f_equation:\n  for +a: KTerm\n  for +neg: Bool\n  for +opBegin: U32\n  for +opEnd: U32')
change(f,'law f_equation_type:\n  for +a: KTerm\n  for +b: KTerm\n  for +neg: Bool','law f_equation_type:\n  for +a: KTerm\n  for +b: KTerm\n  for +neg: Bool\n  for +opBegin: U32\n  for +opEnd: U32')
change(f,'f_equation(a, f_eq(f_tx(ts), "!="), f_expect','f_equation(a, f_eq(f_tx(ts), "!="), f_begin(ts), f_end(ts), f_expect')
change(f,'def f_equation(a, neg, p):','def f_equation(a, neg, opBegin, opEnd, p):')
change(f,'f_equation_type(a, b, neg, f_expect','f_equation_type(a, b, neg, opBegin, opEnd, f_expect')
change(f,'def f_equation_type(a, b, neg, p):','def f_equation_type(a, b, neg, opBegin, opEnd, p):')
change(f,'kt("Ref", "Empty", 0, 1, Nil{})','kt_span("Ref", "Empty", 0, 1, Nil{}, opBegin, opEnd)')
p=P/f;p.write_text(p.read_text()+r'''
# Semantic parser errors carry explicit producer data and an actual term range.
# Their historical fallback remains available to deliberately unlocated callers.
@unsafe
def fpe_message_at(+term: KTerm, +legacy: String, +message: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseMessage", message, 0, 0, Nil{})], kb(term), ke(term))

@unsafe
def fpe_expected_at(+term: KTerm, +legacy: String, +expected: String, +observed: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseObserved", observed, 0, 0, Nil{})], kb(term), ke(term))

@unsafe
def fpe_origin_render(+source: String, +start: U32, +error: KTerm) -> String:
  f_choose(String, U32.is_gt(start, 0) && U32.is_ge(kb(error), start) && U32.is_ge(ke(error), kb(error)) && U32.is_le(U32.sub(ke(error), start), dg_width(source)),
    u => f_choose(String, f_eq(tg(kid(error, 0)), "ParseMessage"),
      u => "Error:\n- message  : " ++ nm(kid(error, 0)) ++ "\nLocation:" ++ dg_snippet(DSpan{source, U32.sub(kb(error), start), U32.sub(ke(error), start)}),
      u => f_choose(String, f_eq(tg(kid(error, 0)), "ParseExpected") && f_eq(tg(kid(error, 1)), "ParseObserved"),
        u => "Error:\n- expected : " ++ nm(kid(error, 0)) ++ "\n- observed : " ++ nm(kid(error, 1)) ++ "\nLocation:" ++ dg_snippet(DSpan{source, U32.sub(kb(error), start), U32.sub(ke(error), start)}), u => fpe_render(source, error))),
    u => fpe_render(source, error))

@unsafe
def fpe_finish_indexed(+start: U32, +source: String, +raw: FRawResult) -> FResult:
  match raw:
    case FRawResult{book, error, imports}: FResult{book, fpe_origin_render(source, start, error), imports}
''')
change('front/declarations.bend','fpe_finish(source, f_tops(f_lex_indexed(start, source), Nil{}, Nil{}, False{}))','fpe_finish_indexed(start, source, f_tops(f_lex_indexed(start, source), Nil{}, Nil{}, False{}))')
changes=[]
for p in sorted(P.rglob('*.bend')):
 before=(BASE/'src'/p.relative_to(P)).read_text();after=p.read_text()
 if before!=after:
  rel='src/'+p.relative_to(P).as_posix();changes.append({'file':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(after.splitlines())-len(before.splitlines())});(OUT/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-parser-semantic-errors.md','changes':changes,'preparerSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(OUT)
