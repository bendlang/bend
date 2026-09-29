#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,os,stat,shutil,difflib
r=Path(__file__).resolve().parents[4];parent=r/'selfhost/build/phase19/context-body-source-03/project';out=r/'selfhost/build/phase19/context-row-source-05';out.mkdir();project=out/'project';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def inventory(p):
 rows=[]
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   f=Path(base)/name;s=f.lstat();row={'file':str(f.relative_to(p)),'mode':stat.S_IMODE(s.st_mode)}
   if f.is_symlink():rows.append({**row,'kind':'symlink','target':os.readlink(f)})
   elif f.is_file():rows.append({**row,'kind':'file','bytes':s.st_size,'sha256':sha(f)})
 return sorted(rows,key=lambda x:x['file'])
attempt=json.loads((r/'selfhost/build/phase19/context-body-build-03/attempt.json').read_text());assert attempt['checked'];assert attempt['api']['sha256']=='0fdb615a5ebdd1ba5f3e5f5acc04c275707a6a3c117930fd98b492b3c814664c'
for x in attempt['snapshot']['sources']:
 for side in ['original','frozen']:assert sha(Path(x[side]['file']))==x[side]['sha256']
oracle=r/'selfhost/build/phase19/context-row-oracle-05/oracle/report.json';assert json.loads(oracle.read_text())['pass'];before=inventory(parent);shutil.copytree(parent,project,symlinks=True);assert inventory(project)==before
s=''
def replace(old,new):
 global s
 assert s.count(old)==1,(old,s.count(old));s=s.replace(old,new)
f=project/'src/front/contextual.bend';s=f.read_text()
replace(' && Bool.not(Char.is_digit(f_head(f_tx(input))))) && Bool.not(String.eq(f_tx(f_tl(input)), "{")))', ')) || Char.is_digit(f_head(f_tx(input))) || U32.is_eq(f_kind_token(input), 2) || String.eq(f_tx(input), "Type") || String.eq(f_tx(input), "Data") || String.eq(f_tx(input), "(")')
replace(' || String.eq(f_tx(f_space(rest)), ":")', '')
replace('&& String.eq(f_tx(rest), "=")', '&& (String.eq(f_tx(rest), "=") || String.eq(f_tx(rest), ":"))')
replace('u => f_context_pattern_computed(pattern, input, cursor, f_fresh_term(pattern, f_context_free_env(env), 0)))', 'u => f_choose(FParsed, core_literal(pattern), u => f_context_pattern(core_literal_step(pattern), input, cursor), u => f_choose(FParsed, String.eq(tg(pattern), "Ctr"), u => f_context_pattern_ctor(pattern, input, cursor, scope), u => f_context_pattern_computed(pattern, input, cursor, f_fresh_term(pattern, f_context_free_env(env), 0)))))')
replace('[pattern, value, body]), f_context_close', '[pattern, f_choose(KTerm, String.eq(tg(pattern), "Ctr"), u => f_context_head(value), u => value), body]), f_context_close')
s+='''
# Private scoped heads preserve the parser's syntax/value distinction.
@unsafe
def f_context_head(+term: KTerm) -> KTerm:
  f_choose(KTerm, String.eq(tg(term), "FName"), u => kid(term, 0), u => f_choose(KTerm, String.eq(tg(term), "Ref"), u => kt_span("FComputedHead", "", 0, 1, [term], kb(term), ke(term)), u => term))

@unsafe
def f_context_atom_done(+p: FParsed) -> FParsed:
  match p:
    case FParsed{term, rest}: FParsed{f_choose(KTerm, Bool.not(f_context_raw(rest)) && String.eq(tg(term), "Literal"), u => f_literal_at(term), u => term), rest}

@unsafe
def f_context_constructor(+term: KTerm, +input: FInput) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: FParsed{term, input}
        case FContextual{scope, env, next}: f_context_constructor_done(term, input, f_context_resolve(k_with_span(term, f_previous_end(input), f_previous_end(input)), scope))

@unsafe
def f_context_constructor_done(+term: KTerm, +input: FInput, +resolved: KTerm) -> FParsed:
  f_choose(FParsed, f_context_stop(resolved), u => f_context_error_at(resolved, input, f_previous_end(input)), u => FParsed{kt_span("Ctr", nm(resolved), 0, 1, ks(term), kb(term), ke(term)), input})

@unsafe
def f_context_pattern_ctor(+term: KTerm, +input: FInput, +cursor: U32, +scope: FParseScope) -> FParsed:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      match f_valid_ctor_head(term, f_ctor_lookup(nm(term), prior)):
        case Some{error}: f_context_error_at(error, input, cursor)
        case None{}: f_context_patterns(term, ks(term), input, cursor, Nil{})

@unsafe
def f_context_patterns(+owner: KTerm, +patterns: List<&2,KTerm>, +input: FInput, +cursor: U32, +acc: List<&2,KTerm>) -> FParsed:
  match patterns:
    case Nil{}: FParsed{k_with_children(owner, List.reverse(&2, KTerm, acc)), input}
    case Con{pattern, rest}: f_context_patterns_next(owner, rest, cursor, acc, f_context_pattern(pattern, input, cursor))

@unsafe
def f_context_patterns_next(+owner: KTerm, +patterns: List<&2,KTerm>, +cursor: U32, +acc: List<&2,KTerm>, +parsed: FParsed) -> FParsed:
  match parsed:
    case FParsed{term, rest}: f_choose(FParsed, f_context_stop(term), u => parsed, u => f_context_patterns(owner, patterns, rest, cursor, Con{term, acc}))

@unsafe
def f_context_case(+input: FInput, +indent: U32, +heads: List<&2,KTerm>, +rows: List<&2,KTerm>, +patterns: List<&2,KTerm>) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: f_case_body(f_body_context(f_tl(input), U32.add(indent, 1)), indent, heads, rows, patterns)
        case FContextual{scope, env, next}: f_context_case_open(indent, heads, rows, env, f_context_patterns(kt("Patterns", "", 0, 1, Nil{}), patterns, f_tl(input), f_end(input), Nil{}))

@unsafe
def f_context_case_open(+indent: U32, +heads: List<&2,KTerm>, +rows: List<&2,KTerm>, +outer: List<&2,KTerm>, +parsed: FParsed) -> FParsed:
  match parsed:
    case FParsed{patterns, rest}: f_choose(FParsed, f_context_stop(patterns), u => parsed, u => f_case_body(f_context_close_done(f_body_context(rest, U32.add(indent, 1)), outer), indent, heads, rows, ks(patterns)))

@unsafe
def f_context_close_done(+parsed: FParsed, +outer: List<&2,KTerm>) -> FParsed:
  match parsed:
    case FParsed{term, rest}: f_choose(FParsed, f_context_stop(term), u => parsed, u => FParsed{term, f_context_close(rest, outer)})

@unsafe
def f_context_flat(+parsed: FParsed, +vars: List<&2,KTerm>) -> FParsed:
  match parsed:
    case FParsed{term, rest}:
      f_choose(FParsed, f_context_stop(term), u => parsed, u => f_context_flat_input(term, f_space(rest), vars))

@unsafe
def f_context_flat_input(+term: KTerm, +input: FInput, +vars: List<&2,KTerm>) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: f_context_unsupported(input, "contextual flatten requires context")
        case FContextual{scope, env, next}:
          match ff_flat(term, vars, next):
            case FFlatten{body, after}: FParsed{body, FInput{tokens, FContextual{scope, env, after}}}

@unsafe
def f_context_group_done(+parsed: FParsed) -> FParsed:
  match parsed:
    case FParsed{term, rest}: f_choose(FParsed, f_context_stop(term), u => parsed, u => f_choose(FParsed, String.eq(f_tx(rest), ":"), u => f_context_unsupported(rest, "group annotation owner"), u => f_expect(parsed, ")")))

@unsafe
def f_context_block(+input: FInput, +seed: FContextSeed, +outer: U32) -> FContextSyntax:
  match seed:
    case FContextSeed{scope, parameters, next}:
      match f_context_body_syntax(input, seed, outer):
        case FContextParsed{term, rest}: f_context_syntax_done(f_context_flat(FParsed{term, rest}, parameters))
        case FContextError{error, rest}: FContextError{error, rest}
        case FContextUnsupported{feature, rest}: FContextUnsupported{feature, rest}
''';f.write_text(s)
f=project/'src/front/parser.bend';s=f.read_text();replace('u => f_atom_existing(ts), u => f_context_unsupported', 'u => f_context_atom_done(f_atom_existing(ts)), u => f_context_unsupported')
replace('f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), s)', 'f_choose(FParsed, f_context_stop(n), u => FParsed{n, ts}, u => f_choose(FParsed, f_eq(f_tx(ts), s)')
replace('f_choose(FParsed, f_eq(tg(args), "Error"), u => FParsed{args, ts}, u => FParsed{kt("Ctr", name, id, 1, ks(args)), ts})', 'f_choose(FParsed, f_context_stop(args), u => FParsed{args, ts}, u => f_context_constructor(kt("Ctr", name, id, 1, ks(args)), ts))')
replace('def f_group(p):\n', '''def f_group(p):
  match p:
    case FParsed{term, rest}:
      f_choose(FParsed, f_context_raw(rest), u => f_group_existing(p), u => f_choose(FParsed, f_context_stop(term), u => p, u => f_choose(FParsed, String.eq(f_tx(rest), ",") && Bool.not(String.eq(tg(term), "Local") || String.eq(tg(term), "Match")), u => f_group_existing(p), u => f_context_group_done(f_context_flat(p, Nil{})))))

@unsafe
def f_group_existing(+p: FParsed) -> FParsed:
''')
replace('FParsed{kt("Ctr", "Tuple", 0, 1, [n, m]), ts}', 'FParsed{f_choose(KTerm, f_context_stop(m), u => m, u => kt("Ctr", "Tuple", 0, 1, [n, m])), ts}');f.write_text(s)
f=project/'src/front/declarations.bend';s=f.read_text();replace('(f_eq(f_tx(ts), "match") || f_eq(f_tx(ts), "-")), u => f_context_unsupported(ts, "match or erased local owner")', 'f_eq(f_tx(ts), "-"), u => f_context_unsupported(ts, "erased local owner")')
replace('u => f_case_body(f_body_context(f_tl(ts), U32.add(indent, 1)), indent, heads, rows, List.reverse(&2, KTerm, pats))', 'u => f_context_case(ts, indent, heads, rows, List.reverse(&2, KTerm, pats))')
replace('f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_match_heads(ts, indent, Con{n, acc})', 'f_context_stop(n), u => FParsed{n, ts}, u => f_match_heads(ts, indent, Con{f_choose(KTerm, f_context_raw(ts), u => n, u => f_context_head(n)), acc})')
replace('f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_case_pats', 'f_context_stop(n), u => FParsed{n, ts}, u => f_case_pats')
replace('f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_match_cases', 'f_context_stop(n), u => FParsed{n, ts}, u => f_match_cases');f.write_text(s)
f=project/'src/front/validate.bend';s=f.read_text();replace('def f_valid_ctor_pattern(p, ctr, book):\n', '''def f_valid_ctor_pattern(p, ctr, book):
  match f_valid_ctor_head(p, ctr):
    case Some{error}: Some{error}
    case None{}: f_valid_patterns(ks(p), book)

@unsafe
def f_valid_ctor_head(+p: KTerm, +ctr: KDef) -> Maybe<&2,KTerm>:
''');replace('u => f_valid_patterns(ks(p), book), u => Some{fpe_message_at(p, "constructor', 'u => None{}, u => Some{fpe_message_at(p, "constructor');f.write_text(s)
f=project/'src/front/flatten.bend';s=f.read_text();replace('def ff_flat(\n', 'def ff_flat(\n')
start=s.index('  f_choose(FFlatten, f_eq(tg(t), "Match")',s.index('def ff_flat('));end=s.index('\n\n@unsafe',start);body=s[start:end];s=s[:start]+'  f_choose(FFlatten, ff_failed(t), u => FFlatten{t, next}, u => '+body.strip()+')'+s[end:]
replace('&& f_has_id(vars, ix(h))', '&& ff_variable(h) && f_has_id(vars, ix(h))');replace('f_choose(FFlatten, U32.is_eq(ix(h), ix(v)),', 'f_choose(FFlatten, ff_variable(h) && U32.is_eq(ix(h), ix(v)),')
for name,field in [('ff_let','body'),('ff_parallel','body'),('ff_lam','body'),('ff_hit_done','hit'),('ff_miss_done','miss')]:
 start=s.index('def '+name+'(');start=s.index('\n      ',s.index('case FFlatten',start))+len('\n      ');end=s.index('\n\n@unsafe',start);expr=s[start:end];s=s[:start]+'f_choose(FFlatten, ff_failed('+field+'), u => FFlatten{'+field+', next}, u => '+expr+')'+s[end:]
s+='''
@unsafe
def ff_failed(+term: KTerm) -> Bool:
  String.eq(tg(term), "Error")

@unsafe
def ff_variable(+term: KTerm) -> Bool:
  String.eq(tg(term), "Var")
''';f.write_text(s)
f=project/'tools/typed-driver.mjs';s=f.read_text();replace('exports.push("f_context_term", "f_context_body_syntax");', 'exports.push("f_context_term", "f_context_body_syntax", "f_context_block");');f.write_text(s)
f=project/'src/front/contextual.bend';s=f.read_text()
replace('      match f_valid_ctor_head(term, f_ctor_lookup(nm(term), prior)):\n        case Some{error}: f_context_error_at(error, input, cursor)\n        case None{}: f_context_patterns(term, ks(term), input, cursor, Nil{})', '      f_context_ctor_checked(term, input, cursor, f_valid_ctor_head(term, f_ctor_lookup(nm(term), prior)))')
replace('          match ff_flat(term, vars, next):\n            case FFlatten{body, after}: FParsed{body, FInput{tokens, FContextual{scope, env, after}}}', '          f_context_flat_done(input, ff_flat(term, vars, next))')
replace('      match f_context_body_syntax(input, seed, outer):\n        case FContextParsed{term, rest}: f_context_syntax_done(f_context_flat(FParsed{term, rest}, parameters))\n        case FContextError{error, rest}: FContextError{error, rest}\n        case FContextUnsupported{feature, rest}: FContextUnsupported{feature, rest}', '      f_context_block_done(f_context_body_syntax(input, seed, outer), parameters)')
s+="""
@unsafe
def f_context_ctor_checked(+term: KTerm, +input: FInput, +cursor: U32, +error: Maybe<&2,KTerm>) -> FParsed:
  match error:
    case Some{error}: f_context_error_at(error, input, cursor)
    case None{}: f_context_patterns(term, ks(term), input, cursor, Nil{})

@unsafe
def f_context_flat_done(+input: FInput, +flat: FFlatten) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: f_context_unsupported(input, "contextual flatten requires context")
        case FContextual{scope, env, next}:
          match flat:
            case FFlatten{body, after}: FParsed{body, FInput{tokens, FContextual{scope, env, after}}}

@unsafe
def f_context_block_done(+syntax: FContextSyntax, +parameters: List<&2,KTerm>) -> FContextSyntax:
  match syntax:
    case FContextParsed{term, rest}: f_context_syntax_done(f_context_flat(FParsed{term, rest}, parameters))
    case FContextError{error, rest}: FContextError{error, rest}
    case FContextUnsupported{feature, rest}: FContextUnsupported{feature, rest}
""";f.write_text(s)
f=project/'src/front/validate.bend';s=f.read_text()
replace('  match f_valid_ctor_head(p, ctr):\n    case Some{error}: Some{error}\n    case None{}: f_valid_patterns(ks(p), book)', '  f_valid_ctor_fields(p, book, f_valid_ctor_head(p, ctr))')
s+="""
@unsafe
def f_valid_ctor_fields(+p: KTerm, +book: List<&2,KDef>, +error: Maybe<&2,KTerm>) -> Maybe<&2,KTerm>:
  match error:
    case Some{error}: Some{error}
    case None{}: f_valid_patterns(ks(p), book)
""";f.write_text(s)
f=project/'src/front/contextual.bend';s=f.read_text()
replace('kt("Local", "", 0, 1, [pattern, f_choose(KTerm, String.eq(tg(pattern), "Ctr"), u => f_context_head(value), u => value), body])', 'kt_span("Local", "", 0, 1, [pattern, f_choose(KTerm, String.eq(tg(pattern), "Ctr"), u => f_context_head(value), u => value), body], kb(pattern), ke(pattern))')
f.write_text(s)
f=project/'src/front/declarations.bend';s=f.read_text();pre_guard=s
for fun,acc in [('f_match_heads','acc'),('f_case_pats','pats')]:
 start=s.index('\n  ',s.index('def '+fun+'('))+3;end=s.index('\n\n@unsafe',start);body=s[start:end]
 s=s[:start]+'f_choose(FParsed, List.is_empty(&2, KTerm, '+acc+') && (f_eq(f_tx(ts), ":") || f_eq(f_tx(ts), ",")), u => fpe_error(ts, "expected term", "a term"), u => '+body+')'+s[end:]
f.write_text(s)
(out/'first-element-only.patch').write_text(''.join(difflib.unified_diff(pre_guard.splitlines(True),s.splitlines(True),fromfile='parent/src/front/declarations.bend',tofile='candidate/src/front/declarations.bend')))
after=inventory(project);a={x['file']:x for x in before};b={x['file']:x for x in after};changes=[]
for name in sorted(a.keys()|b.keys()):
 if a.get(name)!=b.get(name):
  old=(parent/name).read_text()if name in a else '';new=(project/name).read_text();changes.append(dict(file=name,lineDelta=len(new.splitlines())-len(old.splitlines()),byteDelta=len(new.encode())-len(old.encode()),definitionDelta=new.count('\ndef ')-old.count('\ndef ')));(out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='parent/'+name,tofile='candidate/'+name)))
inputs=[Path(__file__),r/'design/phase19/saved-row-group-frontier.md',r/'design/phase19/shared-flatten-checkpoints.md',r/'design/phase19/scoped-block-equivalence.md',r/'selfhost/build/phase19/context-row-controls-05/manifest.json',r/'selfhost/build/phase19/context-flatten-controls-03/manifest.json',oracle]
for p in inputs:shutil.copy2(p,out/('consumed-'+p.parent.name+'-'+p.name))
(out/'manifest.json').write_text(json.dumps(dict(complete=True,parent=str(parent),parentMembership=before,candidateMembership=after,changes=changes,inputs=[dict(file=str(p),sha256=sha(p))for p in inputs],stage='private rows/groups and explicit block flatten; no Core/loader routing'),indent=2)+'\n');(out/'workflow.json').write_text(json.dumps(dict(project=str(project),upstream=attempt['config']['upstream'],cpu='3',jobs=1,profile='equality',timeoutMs=30000),indent=2)+'\n');print(json.dumps(dict(source=str(project),changes=changes)));assert sum(x['lineDelta']for x in changes if x['file'].endswith('.bend'))<=180
