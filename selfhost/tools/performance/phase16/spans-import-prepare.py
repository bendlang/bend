#!/usr/bin/env python3
from pathlib import Path
import shutil,json,hashlib,difflib,re
R=Path(__file__).resolve().parents[4];base=R/'selfhost/build/phase16/spans-integration-source-04/project';out=R/'selfhost/build/phase16/spans-import-source-01';out.mkdir();P=out/'project';shutil.copytree(base,P)
changed=[]
def change(rel,fn):
 p=P/rel;a=p.read_text();b=fn(a);assert a!=b,rel;p.write_text(b);changed.append({'relative':rel,'before':hashlib.sha256(a.encode()).hexdigest(),'after':hashlib.sha256(b.encode()).hexdigest()});(out/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='a/'+rel,tofile='b/'+rel)))
def rep(s,a,b):
 assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def parser(s):
 s=rep(s,'  f_choose(String, f_eq(tg(kid(error, 2)), "ParseRange"), u => fpe_range(source, rest, ix(error), qt(error), offset, offset, error, ""), u => fpe_message(source, offset, offset, error, observed))','  f_choose(String, f_eq(tg(kid(error, 2)), "ParseLine"), u => fpe_message(source, offset, offset, error, "\'" ++ fpe_line_text(String.lines(source), ix(error)) ++ "\'"), u => f_choose(String, f_eq(tg(kid(error, 2)), "ParseRange"), u => fpe_range(source, rest, ix(error), qt(error), offset, offset, error, ""), u => fpe_message(source, offset, offset, error, observed)))')
 s=rep(s,'f_eq(tg(kid(error, 0)), "ParseExpected") && f_eq(tg(kid(error, 1)), "ParseObserved")','f_eq(tg(kid(error, 0)), "ParseExpected") && (f_eq(tg(kid(error, 1)), "ParseObserved") || f_eq(tg(kid(error, 1)), "ParseObservedPoint"))')
 s=rep(s,'++ nm(kid(error, 1)) ++ "\\nLocation:" ++ dg_snippet(DSpan{source, U32.sub(kb(error), start), U32.sub(ke(error), start)})','++ f_choose(String, f_eq(tg(kid(error, 1)), "ParseObservedPoint"), u => fpe_point_observed(source, U32.sub(kb(error), start)), u => nm(kid(error, 1))) ++ "\\nLocation:" ++ dg_module_snippet(DSpan{source, U32.sub(kb(error), start), U32.sub(ke(error), start)})')
 # Only semantic expected/observed errors select the module view; lexical/header stays raw.
 return s+r'''

# Failure payloads request an original line or exact UTF16 cursor observation.
@unsafe
def fpe_line(+ts: List<&2,FToken>, +legacy: String, +expected: String) -> KTerm:
  kt("Error", legacy, f_line(ts), f_col(ts), [kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseToken", f_tx(ts), 0, 0, Nil{}), atom("ParseLine")])

@unsafe
def fpe_line_text(+lines: List<&2,String>, +line: U32) -> String:
  match lines:
    case Nil{}: ""
    case Con{text, rest}: f_choose(String, U32.is_le(line, 1), u => String.trim(text), u => fpe_line_text(rest, U32.sub(line, 1)))

@unsafe
def fpe_point_at(+term: KTerm, +legacy: String, +expected: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseExpected", expected, 0, 0, Nil{}), atom("ParseObservedPoint")], kb(term), ke(term))

@unsafe
def fpe_point_observed(+source: String, +offset: U32) -> String:
  match source:
    case SNil{}: "end of input"
    case SCon{c, rest}:
      f_choose(String, U32.is_lt(offset, dg_units(c)),
        u => "'" ++ SCon{fpe_utf16_char(c, offset), ""} ++ "'",
        u => fpe_point_observed(rest, U32.sub(offset, dg_units(c))))

@unsafe
def fpe_utf16_char(+c: Char, +offset: U32) -> Char:
  f_choose(Char, U32.is_le(Char.to_u32(c), 65535), u => c,
    u => Char.from_u32(f_choose(U32, U32.is_eq(offset, 0),
      u => U32.add(55296, U32.div(U32.sub(Char.to_u32(c), 65536), 1024)),
      u => U32.add(56320, U32.mod(U32.sub(Char.to_u32(c), 65536), 1024)))))
'''
def declarations(s):
 a=s.index('law f_def:\n');b=s.index('\n\nlaw ',a);block=s[a:b];s=s[:a]+block.replace('  FRawResult','  for +nameTokens: List<&2,FToken>\n  FRawResult')+s[b:]
 s=rep(s,'f_def(f_tx(ts), f_tele(f_tl(rest), ")", Nil{}), book, imports, unsafe || suffix)','f_def(f_tx(ts), f_tele(f_tl(rest), ")", Nil{}), book, imports, unsafe || suffix, ts)')
 s=rep(s,'f_import_path(ts, ts, "", book, imports)','f_import_path(f_tl(ts), f_tl(ts), "", book, imports, ts)')
 s=rep(s,'u => f_import(f_tl(ts), book, imports)','u => f_import(ts, book, imports)')
 s=rep(s,'def f_def(name, p, book, imports, unsafe):','def f_def(name, p, book, imports, unsafe, nameTokens):')
 s=rep(s,'f_def_prior(name, p, book, imports, unsafe, f_find(name, book))','f_def_prior(name, p, book, imports, unsafe, f_find(name, book), nameTokens)')
 return s

def imports(s):
 a=s.index('law f_import_path:\n');b=s.index('\n\n@unsafe',a);block=s[a:b];s=s[:a]+block.replace('  FRawResult','  for +header: List<&2,FToken>\n  FRawResult')+s[b:]
 a=s.index('def f_import_path(');b=s.index('\n\n',a)
 s=s[:a]+r'''def f_import_path(ts, start, path, book, imports, header):
  f_choose(FRawResult, f_eq(f_tx(ts), "as"),
    u => f_import_alias(ts, start, path, book, imports, header),
    u => f_choose(FRawResult, f_eq(f_tx(ts), "\n") || f_eq(f_tx(ts), "<eof>"),
      u => f_choose(FRawResult, f_eq(path, "Base"), u => f_tops(ts, book, Con{kt("Import", path, f_line(start), f_col(start), Nil{}), imports}, False{}),
        u => f_result(book, f_import_header_error(start), imports)),
      u => f_choose(FRawResult, String.is_empty(path) || U32.is_eq(f_col(ts), U32.add(f_col(start), U32.from_nat(String.length(path)))),
        u => f_import_path(f_tl(ts), start, path ++ f_tx(ts), book, imports, header),
        u => f_result(book, f_import_header_error(header), imports))))

@unsafe
def f_import_header_error(+ts: List<&2,FToken>) -> KTerm:
  fpe_line(ts, "a module import requires as followed by an alias", "an import ('import Base', or 'import <path> as <Name>')")

@unsafe
def f_import_alias_head(+name: String) -> String:
  match name:
    case SNil{}: ""
    case SCon{c, rest}: f_choose(String, Char.is_eq(c, '.'), u => "", u => SCon{c, f_import_alias_head(rest)})
''' +s[b:]
 return s

def validate(s):
 a=s.index('def f_import_alias(');b=s.index('\n\n@unsafe',a)
 s=s[:a]+r'''def f_import_alias(
  +ts: List<&2, FToken>,
  +start: List<&2, FToken>,
  +path: String,
  +book: List<&2,KDef>,
  +imports: List<&2,KTerm>,
  +header: List<&2,FToken>,
) -> FRawResult:
  +alias = f_tx(f_tl(ts))
  +rest = f_tl(f_tl(ts))
  f_choose(FRawResult, f_alias_valid(alias) && (f_eq(f_tx(rest), "\n") || f_eq(f_tx(rest), "<eof>")) && U32.is_eq(f_line(ts), f_line(f_tl(ts))) && U32.is_gt(f_col(ts), U32.add(f_col(start), U32.from_nat(String.length(path)))),
    u => f_choose(FRawResult, String.ends_with(path, ".bend"),
      u => f_choose(FRawResult, f_import_used(alias, imports),
        u => f_result(book, fpe_line(start, "expected a fresh alias (" ++ alias ++ " names an earlier import)", "a fresh alias (" ++ alias ++ " names an earlier import)"), imports),
        u => f_choose(FRawResult, f_import_valid(path),
          u => f_tops(rest, book, Con{kt("Import", path, f_line(start), f_col(start), [kt("Alias", alias, 0, 0, Nil{})]), imports}, False{}),
          u => f_result(book, f_pn(fpe_span(start, start, "invalid import path", "an import path of plain names (letters, digits, _ and -; the hub's files import the hub's)", "'" ++ path ++ "'")), imports))),
      u => f_result(book, f_pn(fpe_span(start, start, "an import requires a .bend path and a valid alias", "an import of a .bend file", "'" ++ path ++ "'")), imports)),
    u => f_result(book, f_import_header_error(header), imports))''' +s[b:]
 a=s.index('law f_def_prior:\n');b=s.index('\n\n@unsafe',a);block=s[a:b];s=s[:a]+block.replace('  FRawResult','  for +nameTokens: List<&2,FToken>\n  FRawResult')+s[b:]
 s=rep(s,'def f_def_prior(name, p, book, imports, unsafe, old):','def f_def_prior(name, p, book, imports, unsafe, old, nameTokens):')
 s=rep(s,'f_pn(f_err(f_pr(p), "an import alias can only name a law fill without a return annotation"))','f_pn(fpe_word(nameTokens, "an import alias can only name a law fill without a return annotation", "a fresh name (" ++ f_import_alias_head(name) ++ " is an import\'s alias)"))')
 return s

def graph(s):
 return rep(s,'u => kt("Error", "expected an unambiguous name (an import alias shadows " ++ nm(t) ++ ")", 0, 0, Nil{}),','u => fpe_point_at(k_with_span(t, ke(t), ke(t)), "expected an unambiguous name (an import alias shadows " ++ nm(t) ++ ")", "an unambiguous name (the alias " ++ f_import_alias_head(nm(t)) ++ " shadows " ++ nm(t) ++ ")"),')
for rel,fn in [('src/front/parser.bend',parser),('src/front/declarations.bend',declarations),('src/load/imports.bend',imports),('src/front/validate.bend',validate),('src/load/graph.bend',graph)]:change(rel,fn)
shutil.copy2(__file__,out/Path(__file__).name)
(out/'workflow.json').write_text(json.dumps({'project':str(P),'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'cpu':'2','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'baseline':str(base),'project':str(P),'experiment':str(R/'experiments/phase16/P16-002E-import-diagnostics.md'),'changes':changed},indent=2)+'\n');print(P)
