#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib,re
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/wave4-source-02/project';OUT=ROOT/'selfhost/build/phase16/parser-declaration-source-01';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src/front'
p=P/'declarations.bend';s=p.read_text();a='''law f_def:
  for +name: String
  for +p: FParsed
  for +book: List<&2, KDef>
  for +imports: List<&2, KTerm>
  for +unsafe: Bool
  FRawResult

''';assert s.count(a)==1;s=s.replace(a,'')
a='''    u => f_choose(FRawResult, f_eq(f_tx(rest), "("),
      u => f_def(f_tx(ts), f_tele(f_tl(rest), ")", Nil{}), book, imports, unsafe || suffix),
      u => f_result(book, f_pn(fpe_error(rest, "expected (", "'('")), imports)))''';b='''    u => f_def_header_prior(ts, rest, book, imports, unsafe || suffix, f_find(f_tx(ts), book)))''';assert s.count(a)==1;s=s.replace(a,b)
a='''@unsafe
def f_def(name, p, book, imports, unsafe):
  f_choose(FRawResult, Bool.not(f_valid_name(name)), u => f_result(book, kt("Error", "reserved definition name: " ++ name, 0, 0, Nil{}), imports), u => f_def_prior(name, p, book, imports, unsafe, f_find(name, book)))
''';b='''@unsafe
def f_def_header_prior(+nameTokens: List<&2,FToken>, +rest: List<&2,FToken>, +book: List<&2,KDef>, +imports: List<&2,KTerm>, +unsafe: Bool, +old: KDef) -> FRawResult:
  f_choose(FRawResult, f_eq(dk(old), "Missing") || f_def_fillable(old),
    u => f_choose(FRawResult, f_eq(f_tx(rest), "("),
      u => f_def_prior(f_tx(nameTokens), f_tele(f_tl(rest), ")", Nil{}), book, imports, unsafe, old, nameTokens),
      u => f_result(book, f_pn(fpe_error(rest, "expected (", "'('")), imports)),
    u => f_result(book, f_pn(fpe_word(nameTokens, "a definition must uniquely fill its law with plain parameter names", "a fresh name (duplicate declaration: " ++ f_tx(nameTokens) ++ ")")), imports))

@unsafe
def f_def_fillable(+old: KDef) -> Bool:
  f_eq(dk(old), "Def") && f_eq(tg(dv(old)), "Absent") && Bool.not(db(old))
''';assert s.count(a)==1;s=s.replace(a,b)
a='f_result(book, kt("Error", "definition without return type needs a law: " ++ name, 0, 0, Nil{}), imports)';b='f_result(book, f_pn(fpe_error(ts, "definition without return type needs a law: " ++ name, "\'->\' (a def with no return type fills a law; no law named " ++ name ++ " is in scope)")), imports)';assert s.count(a)==1;s=s.replace(a,b);p.write_text(s)
p=P/'validate.bend';s=p.read_text();a='  for +old: KDef\n  FRawResult';assert s.count(a)==1;s=s.replace(a,'  for +old: KDef\n  for +nameTokens: List<&2,FToken>\n  FRawResult');a='def f_def_prior(name, p, book, imports, unsafe, old):';assert s.count(a)==1;s=s.replace(a,'def f_def_prior(name, p, book, imports, unsafe, old, nameTokens):');a='f_eq(dk(old), "Def") && f_eq(tg(dv(old)), "Absent") && f_bare_params';assert s.count(a)==1;s=s.replace(a,'f_def_fillable(old) && f_bare_params');a='f_err(f_pr(p), "expected : (a definition filling a law has no return annotation)")';assert s.count(a)==1;s=s.replace(a,'fpe_error(f_pr(p), "expected : (a definition filling a law has no return annotation)", "\':\'")');p.write_text(s)
changes=[]
for f in ['declarations.bend','validate.bend']:
 a=BASE/'src/front'/f;b=P/f;x=a.read_text();y=b.read_text();patch=OUT/(f+'.patch');patch.write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/src/front/'+f,tofile='candidate/src/front/'+f)));changes.append({'file':'src/front/'+f,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(b.read_bytes()).hexdigest(),'lineDelta':len(y.splitlines())-len(x.splitlines())})
config={'project':str(OUT/'project'),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000};(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');ids=['comptime/err_dup.bend','parse/foreign_refill.bend','parse/def_untyped_refused.bend','parse/law_fill_arrow.bend'];(OUT/'selection.json').write_text(json.dumps({'cases':[{'id':x,'lanes':['parse','check']} for x in ids]},indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-parser-declarations.md','changes':changes,'target':ids},indent=2)+'\n');print(OUT)
