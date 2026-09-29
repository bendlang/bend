#!/usr/bin/env python3
"""Preserve syntax failures and their real source cursor after parser stage 1."""
from pathlib import Path
import difflib, hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'selfhost/build/phase16/parser-source-01/project'
OUT=ROOT/'selfhost/build/phase16/parser-source-02'
OUT.mkdir(); PROJECT=OUT/'project';shutil.copytree(BASE,PROJECT)
changes=[]
def once(s,a,b):
 assert s.count(a)==1,(a,s.count(a))
 return s.replace(a,b)
def edit(name,fn):
 p=PROJECT/'src/front'/name;before=p.read_text();after=fn(before);assert before!=after;p.write_text(after)
 (OUT/(name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='stage1/'+name,tofile='stage2/'+name)))
 changes.append({'file':name,'before':hashlib.sha256(before.encode()).hexdigest(),'after':hashlib.sha256(after.encode()).hexdigest(),'physicalLinesDelta':len(after.splitlines())-len(before.splitlines())})
def parser(s):
 s=once(s,'f_choose(FParsed, f_eq(tg(n), "Error") || f_eq(f_tx(ts), s), u => FParsed{n, f_tl(ts)}, u => f_choose(FParsed, f_eq(s, ")") || f_eq(s, "}") || f_eq(s, "]"), u => fpe_error(ts, "expected " ++ s, "\'" ++ s ++ "\'"), u => f_err(ts, "expected " ++ s)))','f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), s), u => FParsed{n, f_tl(ts)}, u => fpe_error(ts, "expected " ++ s, "\'" ++ s ++ "\'")))')
 s=once(s,'u => f_matcher(f_tl(f_tl(ts))),','u => f_choose(FParsed, f_eq(f_tx(f_tl(ts)), "{"), u => f_matcher(f_tl(f_tl(ts))), u => fpe_error(f_tl(ts), "expected {", "\'{\'")),')
 s=once(s,'f_expr(f_pr(f_expect(FParsed{a, ts}, ":")), 0)','f_expr_after(f_expect(FParsed{a, ts}, ":"))')
 s=once(s,'      f_all_body(name, id, q, exi, a, f_expr(ts, 0))','      f_choose(FParsed, f_eq(tg(a), "Error"), u => FParsed{a, ts}, u => f_all_body(name, id, q, exi, a, f_expr(ts, 0)))')
 old='String.eq(tg(kid(error, 1)), "ParseToken") && U32.is_gt(ix(error), 0), u => fpe_seek(source, source, 1, 0, 0, error), u => nm(error)))'
 new='String.eq(tg(kid(error, 1)), "ParseToken"), u => f_choose(String, U32.is_gt(ix(error), 0), u => fpe_seek(source, source, 1, 0, 0, error), u => f_choose(String, f_eq(nm(kid(error, 1)), "<eof>"), u => fpe_eof(source, source, 0, error), u => nm(error))), u => nm(error)))'
 s=once(s,old,new)
 s=once(s,' || U32.is_gt(Char.to_u32(f_head(rest)), 65535) || (U32.is_ge(Char.to_u32(f_head(rest)), 55296) && U32.is_le(Char.to_u32(f_head(rest)), 57343))','')
 s=once(s,'"\'" ++ SCon{f_head(rest), ""} ++ "\'"','"\'" ++ SCon{fpe_unit(f_head(rest)), ""} ++ "\'"')
 s+='''
@unsafe
def f_expr_after(+p: FParsed) -> FParsed:
  match p:
    case FParsed{n, ts}: f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_expr(ts, 0))

@unsafe
def f_body_after(+p: FParsed) -> FParsed:
  match p:
    case FParsed{n, ts}: f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_body(ts))

@unsafe
def fpe_eof(+source: String, +rest: String, +offset: U32, +error: KTerm) -> String:
  f_choose(String, String.is_empty(rest), u => fpe_message(source, offset, offset, error, "end of input"), u => fpe_eof(source, f_tail(rest), U32.add(offset, dg_units(f_head(rest))), error))

@unsafe
def fpe_unit(+char: Char) -> Char:
  f_choose(Char, U32.is_gt(Char.to_u32(char), 65535), u => Char.from_u32(U32.add(55296, U32.div(U32.sub(Char.to_u32(char), 65536), 1024))), u => char)
'''
 return s
def declarations(s):
 s=once(s,'f_body(f_pr(f_expect(FParsed{ty, ts}, ":")))','f_body_after(f_expect(FParsed{ty, ts}, ":"))')
 s=once(s,'f_expr(f_pr(f_expect(FParsed{pars, ts}, "is")), 0)','f_expr_after(f_expect(FParsed{pars, ts}, "is"))')
 return s
def parallel(s):
 s=once(s,'u => f_parallel_pat(f_expr(ts, 0), pats))','u => f_choose(FParsed, f_binding_head(ts), u => f_parallel_pat(f_expr(ts, 0), pats), u => fpe_error(ts, "expected =", "\'=\'")))')
 s=once(s,'U32.is_eq(f_kind(ts), 1) || f_eq(f_tx(ts), "+bind")','f_binding_head(ts)')
 s=once(s,'      f_choose(FParsed, f_eq(f_tx(ts), "="), u => f_choose(FParsed, f_eq(tg(n), "Ref"), u => f_let_value(n, f_let_ann(ty, f_expr(f_tl(ts), 0))), u => f_err(ts, "a name (a parallel or typed let binds names; destructure in its body)")), u => FParsed{n, old})','      f_choose(FParsed, f_eq(tg(ty), "Error"), u => FParsed{ty, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), "="), u => f_choose(FParsed, f_eq(tg(n), "Ref"), u => f_let_value(n, f_let_ann(ty, f_expr(f_tl(ts), 0))), u => f_err(ts, "a name (a parallel or typed let binds names; destructure in its body)")), u => FParsed{n, old}))')
 s+='''
@unsafe
def f_binding_head(+ts: List<&2,FToken>) -> Bool:
  (f_ascii_alpha(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_') || f_eq(f_tx(ts), "+bind")) && Bool.not(f_reserved(f_tx(ts)))
'''
 return s
def validate(s):
 return once(s,'u => f_err(ts, "! must follow a named definition and precede call parentheses"))','u => fpe_error(ts, "! must follow a named definition and precede call parentheses", "\'def\', \'type\' or \'law\'"))')
edit('parser.bend',parser);edit('declarations.bend',declarations);edit('parallel.bend',parallel);edit('validate.bend',validate)
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(PROJECT)
(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'inputs':[identity(Path(__file__).resolve()),identity(ROOT/'experiments/phase16/P16-parser-propagation.md'),identity(BASE.parent/'manifest.json')],'changes':changes,'config':identity(OUT/'workflow.json')},indent=2)+'\n')
print(OUT)
