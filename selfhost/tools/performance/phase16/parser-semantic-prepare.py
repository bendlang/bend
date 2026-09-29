#!/usr/bin/env python3
from pathlib import Path
import difflib,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/spans-integration-source-03/project';PAR=ROOT/'selfhost/build/phase16/parser-span-source-10/project';OUT=ROOT/'selfhost/build/phase16/parser-semantic-source-01';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
for f in ['parser.bend','declarations.bend','sugar.bend']:shutil.copy2(PAR/'src/front'/f,P/'front'/f)
def change(file,a,b):
 p=P/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
change('front/parser.bend','kt_span("Ref", "Empty", 0, 1, Nil{}, opBegin, opEnd)','kt_span("FGlobal", "Empty", 0, 1, Nil{}, opBegin, opEnd)')
# Carry a structured first failure directly, with a small None success marker.
f='front/validate.bend';p=P/f;s=p.read_text()
for name in ['f_valid_ctor_pattern','f_valid_patterns','f_valid_patterns_mode','f_valid_binding_pattern','f_valid_patterns_mode_next']:
 pattern=r'(law '+name+r':\n(?:  [^\n]*\n)+)';m=re.search(pattern,s);assert m,name;old=m.group();new=old.replace('for +err: String','for +err: Maybe<&2,KTerm>').replace('\n  String\n','\n  Maybe<&2,KTerm>\n');s=s.replace(old,new)
for name in ['f_scope_row_valid','f_scope_local_valid']:
 m=re.search(r'(law '+name+r':\n(?:  [^\n]*\n)+)',s);assert m,name;s=s.replace(m.group(),m.group().replace('for +err: String','for +err: Maybe<&2,KTerm>'))
a=s.index('@unsafe\ndef f_valid_pattern(');b=s.index('@unsafe\ndef f_pattern_env(',a)
s=s[:a]+'''@unsafe
def f_valid_pattern(+p: KTerm, +book: List<&2,KDef>) -> Maybe<&2,KTerm>:
  f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Var"),
    u => f_choose(Maybe<&2,KTerm>, Bool.not(f_valid_name(nm(p))), u => Some{kt("Error", "reserved pattern binder: " ++ nm(p), 0, 0, Nil{})},
      u => f_choose(Maybe<&2,KTerm>, f_eq(dk(f_ctor_lookup(nm(p), book)), "Missing"), u => None{}, u => Some{fpe_message_at(p, "a constructor pattern requires braces: " ++ nm(p), "a braced constructor pattern (" ++ nm(p) ++ " is a constructor: write " ++ nm(p) ++ "{}, or rename the binder)")})),
    u => f_choose(Maybe<&2,KTerm>, f_eq(tg(p), "Ctr"), u => f_valid_ctor_pattern(p, f_ctor_lookup(nm(p), book), book), u => Some{fpe_expected_at(p, "expected a binder or constructor pattern", "a pattern (a binder or a constructor)", kp_show(f_scope(p, Nil{}, book)))}))

@unsafe
def f_valid_ctor_pattern(p, ctr, book):
  f_choose(Maybe<&2,KTerm>, f_eq(dk(ctr), "Missing"), u => Some{fpe_message_at(p, "unknown constructor pattern: " ++ nm(p), "a declared constructor (unknown: " ++ nm(p) ++ ")")},
    u => f_choose(Maybe<&2,KTerm>, U32.is_eq(da(ctr), terms_len(ks(p))), u => f_valid_patterns(ks(p), book), u => Some{fpe_message_at(p, "constructor pattern field count differs: " ++ nm(p), "a " ++ nm(p) ++ " pattern with " ++ U32.show(da(ctr)) ++ f_choose(String, U32.is_eq(da(ctr), 1), u => " field", u => " fields"))}))

@unsafe
def f_valid_patterns(ps, book):
  f_valid_patterns_mode(ps, book, False{})

@unsafe
def f_valid_patterns_mode(ps, book, names):
  match ps:
    case Nil{}: None{}
    case Con{p, rest}: f_valid_patterns_mode_next(f_valid_binding_pattern(p, book, names), rest, book, names)

@unsafe
def f_valid_binding_pattern(p, book, names):
  f_choose(Maybe<&2,KTerm>, names && Bool.not(f_eq(tg(p), "Var")), u => Some{fpe_message_at(p, "a parallel let binds names; destructure in its body", "a name (a parallel or typed let binds names; destructure in its body)")}, u => f_valid_pattern(p, book))

@unsafe
def f_valid_patterns_mode_next(err, ps, book, names):
  match err:
    case None{}: f_valid_patterns_mode(ps, book, names)
    case Some{error}: Some{error}

''' +s[b:]
a='''def f_scope_row_valid(r, pats, env, book, err):
  f_choose(KTerm, String.is_empty(err), u => f_scoped_row(pats, f_scope_body(kid(r, 1), f_pattern_env(pats, env), book)), u => kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, pats), kt("Error", err, 0, 0, Nil{})]))'''
b='''def f_scope_row_valid(r, pats, env, book, err):
  match err:
    case None{}: f_scoped_row(pats, f_scope_body(kid(r, 1), f_pattern_env(pats, env), book))
    case Some{error}: kt("Row", "", 0, 1, [kt("Patterns", "", 0, 1, pats), error])''';assert s.count(a)==1;s=s.replace(a,b)
a='''def f_scope_local_valid(t, pats, env, book, err):
  f_choose(KTerm, String.is_empty(err),
    u => kt("Local", "", 0, qt(t), [terms_at(pats, 0), f_scope(kid(t, 1), env, book), f_scope_body(kid(t, 2), f_pattern_env(pats, env), book)]),
    u => kt("Error", err, 0, 0, Nil{}))'''
b='''def f_scope_local_valid(t, pats, env, book, err):
  match err:
    case None{}: kt_span("Local", "", 0, qt(t), [terms_at(pats, 0), f_scope(kid(t, 1), env, book), f_scope_body(kid(t, 2), f_pattern_env(pats, env), book)], kb(t), ke(t))
    case Some{error}: error''';assert s.count(a)==1;s=s.replace(a,b);p.write_text(s)
f='front/parallel.bend';p=P/f;s=p.read_text();m=re.search(r'(law f_scope_parallel_valid:\n(?:  [^\n]*\n)+)',s);assert m;s=s.replace(m.group(),m.group().replace('for +err: String','for +err: Maybe<&2,KTerm>'))
a='''def f_scope_parallel_valid(t, pats, env, book, err):
  f_choose(KTerm, String.is_empty(err),
    u => kt("Parallel", "", 0, 1, [kt("Patterns", "", 0, 1, pats), kt("Values", "", 0, 1, f_scope_terms(ks(kid(t, 1)), env, book)), f_scope_body(kid(t, 2), f_pattern_env(pats, env), book)]),
    u => kt("Error", err, 0, 0, Nil{}))'''
b='''def f_scope_parallel_valid(t, pats, env, book, err):
  match err:
    case None{}: kt_span("Parallel", "", 0, 1, [kt("Patterns", "", 0, 1, pats), kt("Values", "", 0, 1, f_scope_terms(ks(kid(t, 1)), env, book)), f_scope_body(kid(t, 2), f_pattern_env(pats, env), book)], kb(t), ke(t))
    case Some{error}: error''';assert s.count(a)==1;s=s.replace(a,b);p.write_text(s)
change(f,'u => f_err(ts, "a name (a parallel or typed let binds names; destructure in its body)")','u => FParsed{fpe_message_at(n, nm(f_pn(f_err(ts, "a name (a parallel or typed let binds names; destructure in its body)"))), "a name (a parallel or typed let binds names; destructure in its body)"), Nil{}}')
change('front/elaborate.bend','u => k_with_span(f_pattern_literal(nm(x)), kb(x), ke(x)), u => k_with_children(x, f_patterns(ks(x))))','u => f_span_created(f_pattern_literal(nm(x)), kb(x), ke(x)), u => f_choose(KTerm, f_eq(tg(x), "Ctr"), u => k_with_children(x, f_patterns(ks(x))), u => x))')
# Same classification in the legacy and threaded flattening paths.
for f in ['front/flatten.bend','front/elaborate.bend']:
 change(f,'kt("Error", "match requires an unconsumed parameter or constructor field", 0, 0, Nil{})','f_match_error(h, origin)')
 change(f,'kt("Error", "a match cannot scrutinize a local binding", 0, 0, Nil{})','fpe_message_at(kid(t, 0), "a match cannot scrutinize a local binding", "a parameter or field scrutinee (a match cannot scrutinize a local binder: give it its own def)")')
p=P/'front/validate.bend';p.write_text(p.read_text()+'''
@unsafe
def f_match_error(+head: KTerm, +origin: KTerm) -> KTerm:
  +legacy = "match requires an unconsumed parameter or constructor field"
  f_choose(KTerm, f_eq(tg(head), "Var") || f_eq(tg(head), "Ref"),
    u => fpe_message_at(head, legacy, "a match on a parameter or field (this name is a def or a consumed binder: give the value its own def)"),
    u => f_choose(KTerm, f_eq(tg(head), "Ctr") || f_eq(tg(head), "Literal") || core_word(head) || core_nat(head),
      u => fpe_message_at(origin, legacy, "an undestructed scrutinee (this value is already a constructor: bind its fields directly; if an outer match destructed it, fold the pattern into the outer case)"),
      u => fpe_message_at(f_choose(KTerm, U32.is_gt(kb(head), 0), u => head, u => origin), legacy, "a parameter or field scrutinee (a match cannot scrutinize a computed value: give it its own def)")))
''')
f='front/families.bend';p=P/f;s=p.read_text();a='kt("Error", "a type for this operator (write (a " ++ f_operator_display(nm(t), ["+", "-", "*", "/", "%", "<", ">op", "<=", ">=", "<<", ">>op", ".&.", ".|.", ".^."]) ++ " b : Nat))", ix(t), 0, Nil{})';assert s.count(a)==1;s=s.replace(a,'f_operator_error(t)');s+='''
@unsafe
def f_operator_error(+t: KTerm) -> KTerm:
  +message = "a type for this operator (write (a " ++ f_operator_display(nm(t), ["+", "-", "*", "/", "%", "<", ">op", "<=", ">=", "<<", ">>op", ".&.", ".|.", ".^."]) ++ " b : Nat))"
  fpe_message_at(t, message, message)
''';p.write_text(s)
f='front/literals_arrays.bend';change(f,'f_choose(KTerm, f_eq(tg(size), "Literal"), u => k_with_span(f_power_depth(nm(size), 0), kb(size), ke(size)), u => kt("Error", "array count must be a literal power of two", 0, 0, Nil{}))','f_array_depth_at(size, f_choose(KTerm, f_eq(tg(size), "Literal"), u => f_power_depth(nm(size), 0), u => kt("Error", "array count must be a literal power of two", 0, 0, Nil{})))')
p=P/f;p.write_text(p.read_text()+'''
@unsafe
def f_array_depth_at(+size: KTerm, +value: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(value), "Error"), u => fpe_message_at(size, nm(value), "a power of two count (^d takes a depth)"), u => k_with_span(value, kb(size), ke(size)))
''')
changes=[]
for p in sorted(P.rglob('*.bend')):
 before=(BASE/'src'/p.relative_to(P)).read_text();after=p.read_text()
 if before!=after:
  rel='src/'+p.relative_to(P).as_posix();changes.append({'file':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(after.splitlines())-len(before.splitlines())});(OUT/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)))
config={'project':str(OUT/'project'),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000};(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'parserOverlay':str(PAR),'plan':'experiments/phase16/P16-parser-semantic-errors.md','changes':changes,'preparerSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(OUT)
