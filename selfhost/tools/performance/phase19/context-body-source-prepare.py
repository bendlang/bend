#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,os,stat,shutil,difflib
r=Path(__file__).resolve().parents[4];parent=r/'selfhost/build/phase19/context-grammar-source-02/project';out=r/'selfhost/build/phase19/context-body-source-01';out.mkdir();project=out/'project'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def inventory(p):
 rows=[]
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   f=Path(base)/name;s=f.lstat();row={'file':str(f.relative_to(p)),'mode':stat.S_IMODE(s.st_mode)}
   if f.is_symlink():rows.append({**row,'kind':'symlink','target':os.readlink(f)})
   elif f.is_file():rows.append({**row,'kind':'file','bytes':s.st_size,'sha256':sha(f)})
 return sorted(rows,key=lambda x:x['file'])
attempt=json.loads((r/'selfhost/build/phase19/context-grammar-build-02/attempt.json').read_text());assert attempt['checked'];assert attempt['api']['sha256']=='780ed907d85441ccb2e1a7ad04fe076a0446c01972641cea9d78a5512c5a9a52';assert sha(Path(attempt['api']['file']))==attempt['api']['sha256']
for s in attempt['snapshot']['sources']:
 for side in ['original','frozen']:assert sha(Path(s[side]['file']))==s[side]['sha256']
oracle=r/'selfhost/build/phase19/context-body-oracle-01/oracle/report.json';assert json.loads(oracle.read_text())['pass']
before=inventory(parent);shutil.copytree(parent,project,symlinks=True);assert inventory(project)==before
f=project/'src/front/contextual.bend';s=f.read_text()
def replace(old,new):
 global s
 assert s.count(old)==1,(old,s.count(old));s=s.replace(old,new)
for a,b in [('FNamesResult','FContextSyntax'),('FNamesParsed','FContextParsed'),('FNamesError','FContextError'),('FNamesUnsupported','FContextUnsupported')]:s=s.replace(a,b)
replace('def f_context_term_probe(+input: FInput, +seed: FContextSeed) -> FContextSyntax:', 'def f_context_start(+input: FInput, +seed: FContextSeed, +body: Bool, +outer: U32) -> FContextSyntax:')
replace('f_context_term_done(f_expr(FInput{tokens, FContextual{scope, f_context_parameters(parameters, Nil{}), next}}, 0))', '+seeded = FInput{tokens, FContextual{scope, f_context_parameters(parameters, Nil{}), next}}\n              f_context_finish(f_choose(FParsed, body, u => f_body_context(seeded, outer), u => f_expr(seeded, 0)), body)')
replace('def f_context_term_done(+parsed: FParsed) -> FContextSyntax:', 'def f_context_syntax_done(+parsed: FParsed) -> FContextSyntax:')
replace('FContextParsed{term, rest}', 'FContextParsed{term, f_space(rest)}')
replace(' || String.eq(f_tx(f_space(rest)), "=")', '')
replace('u => FParsed{term, f_space(rest)}, u => f_grow_existing(p, min)', 'u => p, u => f_grow_existing(p, min)')
replace('f_choose(FParsed, String.eq(tg(resolved), "Error") || String.contains(nm(term), "."), u => FParsed{resolved, input},', 'f_choose(FParsed, String.eq(tg(resolved), "Error"), u => f_context_error_at(resolved, input, ke(term)), u => f_choose(FParsed, String.contains(nm(term), "."), u => FParsed{resolved, input},')
replace('U32.add(next, 1)}}})\n\n@unsafe\ndef f_context_open', 'U32.add(next, 1)}}}))\n\n@unsafe\ndef f_context_open')
module='''
@unsafe
def f_context_term(+input: FInput, +seed: FContextSeed) -> FContextSyntax:
  f_context_start(input, seed, False{}, 0)

@unsafe
def f_context_body_syntax(+input: FInput, +seed: FContextSeed, +outer: U32) -> FContextSyntax:
  f_context_start(input, seed, True{}, outer)

@unsafe
def f_context_finish(+parsed: FParsed, +body: Bool) -> FContextSyntax:
  match parsed:
    case FParsed{term, rest}:
      f_choose(FContextSyntax, Bool.not(body) && Bool.not(f_context_stop(term)) && String.eq(f_tx(rest), "="), u => FContextUnsupported{"body owner outside names/calls", rest}, u => f_context_syntax_done(parsed))

@unsafe
def f_context_error_at(+error: KTerm, +input: FInput, +cursor: U32) -> FParsed:
  FParsed{error, f_prepend(FToken{"", f_line(input), f_col(input), 0, cursor, cursor, cursor}, f_empty(input))}

@unsafe
def f_context_pattern(+pattern: KTerm, +input: FInput, +cursor: U32) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: f_context_unsupported(input, "contextual pattern requires context")
        case FContextual{scope, env, next}:
          +syntax = f_choose(KTerm, String.eq(tg(pattern), "FName"), u => kid(pattern, 0), u => pattern)
          f_choose(FParsed, String.eq(tg(syntax), "Var"),
            u => f_context_pattern_named(syntax, input, cursor, f_context_resolve(k_with_span(syntax, cursor, cursor), scope)),
            u => f_context_pattern_computed(pattern, input, cursor, f_fresh_term(pattern, Nil{}, 0)))

@unsafe
def f_context_pattern_named(+pattern: KTerm, +input: FInput, +cursor: U32, +resolved: KTerm) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: f_context_unsupported(input, "contextual pattern requires context")
        case FContextual{scope, env, next}:
          match scope:
            case FParseScope{prior, index, ns, aliases, enabled}:
              f_choose(FParsed, String.eq(tg(resolved), "Error"), u => f_context_error_at(resolved, input, cursor),
                u => f_context_pattern_checked(pattern, input, cursor, f_valid_var_pattern(pattern, f_ctor_lookup(nm(resolved), prior))))

@unsafe
def f_context_pattern_checked(+pattern: KTerm, +input: FInput, +cursor: U32, +error: Maybe<&2,KTerm>) -> FParsed:
  match error:
    case Some{error}: f_context_error_at(error, input, cursor)
    case None{}: f_context_open(pattern, input)

@unsafe
def f_context_pattern_computed(+pattern: KTerm, +input: FInput, +cursor: U32, +fresh: FFresh) -> FParsed:
  match fresh:
    case FFresh{term, next}: f_context_error_at(f_computed_pattern_error(pattern, term), input, cursor)

@unsafe
def f_context_let(+pattern: KTerm, +value: KTerm, +input: FInput) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: f_context_unsupported(input, "contextual local requires context")
        case FContextual{scope, env, next}:
          +spaced = f_space(input)
          +semi = String.eq(f_tx(spaced), ";")
          f_context_let_open(value, env, f_context_pattern(pattern, f_choose(FInput, semi, u => f_tl(spaced), u => spaced), f_choose(U32, semi, u => f_end(spaced), u => f_begin(spaced))))

@unsafe
def f_context_let_open(+value: KTerm, +outer: List<&2,KTerm>, +opened: FParsed) -> FParsed:
  match opened:
    case FParsed{pattern, input}:
      f_choose(FParsed, f_context_stop(pattern), u => opened, u => f_context_let_done(pattern, value, outer, f_body(input)))

@unsafe
def f_context_let_done(+pattern: KTerm, +value: KTerm, +outer: List<&2,KTerm>, +parsed: FParsed) -> FParsed:
  match parsed:
    case FParsed{body, rest}:
      f_choose(FParsed, f_context_stop(body), u => parsed, u => FParsed{kt("Local", "", 0, 1, [pattern, value, body]), f_context_close(rest, outer)})
'''
f.write_text(s+module)
f=project/'src/front/parser.bend';s=f.read_text()
replace('u => kt_span("Call", "", 0, 1, Con{n, ks(args)}, kb(n), f_previous_end(ts)),', 'u => f_choose(KTerm, f_context_raw(ts), u => kt_span("Call", "", 0, 1, Con{n, ks(args)}, kb(n), f_previous_end(ts)), u => f_app_span(n, ks(args), kb(n), f_previous_end(ts))),')
f.write_text(s)
f=project/'src/front/declarations.bend';s=f.read_text()
replace('def f_statement(p):\n', 'def f_statement(p):\n  match p:\n    case FParsed{term, rest}:\n      f_choose(FParsed, f_context_stop(term), u => p, u => f_choose(FParsed, Bool.not(f_context_raw(rest)) && (f_eq(f_tx(rest), ":") || f_binding_head(rest)), u => f_context_unsupported(rest, "typed or parallel local owner"), u => f_statement_existing(p)))\n\n@unsafe\ndef f_statement_existing(+p: FParsed) -> FParsed:\n')
replace('f_choose(FParsed, f_eq(tg(v), "Error"), u => FParsed{v, ts}, u => f_let_body(pat, v, f_body(ts)))', 'f_choose(FParsed, f_context_stop(v), u => FParsed{v, ts}, u => f_choose(FParsed, f_context_raw(ts), u => f_let_body(pat, v, f_body(ts)), u => f_context_let(pat, v, ts)))')
replace('def f_body_context_at(ts, outer):\n', 'def f_body_context_at(ts, outer):\n  f_choose(FParsed, Bool.not(f_context_raw(ts)) && (f_eq(f_tx(ts), "match") || f_eq(f_tx(ts), "-")), u => f_context_unsupported(ts, "match or erased local owner"), u => f_body_context_existing(ts, outer))\n\n@unsafe\ndef f_body_context_existing(+ts: FInput, +outer: U32) -> FParsed:\n')
f.write_text(s)
f=project/'src/front/validate.bend';s=f.read_text()
old='''    u => f_choose(Maybe<&2,KTerm>, Bool.not(f_valid_name(nm(p))), u => Some{kt("Error", "reserved pattern binder: " ++ nm(p), 0, 0, Nil{})},
      u => f_choose(Maybe<&2,KTerm>, f_eq(dk(f_ctor_lookup(nm(p), book)), "Missing"), u => None{}, u => Some{fpe_message_at(p, "a constructor pattern requires braces: " ++ nm(p), "a braced constructor pattern (" ++ nm(p) ++ " is a constructor: write " ++ nm(p) ++ "{}, or rename the binder)")})),'''
replace(old, '    u => f_valid_var_pattern(p, f_ctor_lookup(nm(p), book)),')
replace('Some{fpe_expected_at(p, "expected a binder or constructor pattern", "a pattern (a binder or a constructor)", kp_show(f_scope(p, Nil{}, book)))}', 'Some{f_computed_pattern_error(p, f_scope(p, Nil{}, book))}')
s+='''
@unsafe
def f_valid_var_pattern(+p: KTerm, +constructor: KDef) -> Maybe<&2,KTerm>:
  f_choose(Maybe<&2,KTerm>, Bool.not(f_valid_name(nm(p))), u => Some{kt("Error", "reserved pattern binder: " ++ nm(p), 0, 0, Nil{})},
    u => f_choose(Maybe<&2,KTerm>, f_eq(dk(constructor), "Missing"), u => None{}, u => Some{fpe_message_at(p, "a constructor pattern requires braces: " ++ nm(p), "a braced constructor pattern (" ++ nm(p) ++ " is a constructor: write " ++ nm(p) ++ "{}, or rename the binder)")}))

@unsafe
def f_computed_pattern_error(+pattern: KTerm, +observed: KTerm) -> KTerm:
  fpe_expected_at(pattern, "expected a binder or constructor pattern", "a pattern (a binder or a constructor)", kp_show(observed))
'''
f.write_text(s)
f=project/'src/front/fresh_work.bend';s=f.read_text();replace('def ffw_walk(term, env, next, stack):\n', 'def ffw_walk(term, env, next, stack):\n  f_choose(FFresh, String.eq(tg(term), "FName"), u => ffw_walk(kid(term, 1), env, next, stack), u => ffw_walk_existing(term, env, next, stack))\n@unsafe\ndef ffw_walk_existing(+term: KTerm, +env: List<&2,KTerm>, +next: U32, +stack: List<&2,FFFrame>) -> FFresh:\n')
f.write_text(s)
f=project/'tools/typed-driver.mjs';s=f.read_text();replace('  exports.push("f_context_term_probe");','  exports.push("f_context_term", "f_context_body_syntax");');f.write_text(s)
after=inventory(project);a={x['file']:x for x in before};b={x['file']:x for x in after};changes=[]
for name in sorted(a.keys()|b.keys()):
 if a.get(name)!=b.get(name):
  old=(parent/name).read_text()if name in a else '';new=(project/name).read_text();changes.append(dict(file=name,lineDelta=len(new.splitlines())-len(old.splitlines()),byteDelta=len(new.encode())-len(old.encode()),definitionDelta=new.count('\ndef ')-old.count('\ndef ')));(out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='parent/'+name,tofile='candidate/'+name)))
assert sum(x['lineDelta']for x in changes)<=150,changes
inputs=[Path(__file__),r/'design/phase19/body-pattern-checkpoints.md',r/'design/phase19/body-pattern-stage3-interface.md',r/'selfhost/build/phase19/context-body-controls-01/manifest.json',oracle]
for p in inputs:shutil.copy2(p,out/('consumed-'+p.name))
(out/'manifest.json').write_text(json.dumps(dict(complete=True,parent=str(parent),parentMembership=before,candidateMembership=after,changes=changes,inputs=[dict(file=str(p),sha256=sha(p))for p in inputs],stage='private ordinary-local Body syntax; no Core or loader routing'),indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps(dict(project=str(project),upstream=attempt['config']['upstream'],cpu='3',jobs=1,profile='equality',timeoutMs=30000),indent=2)+'\n')
print(json.dumps(dict(source=str(project),changes=changes)))
