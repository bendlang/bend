from pathlib import Path
import re,json
P=Path('selfhost/build/phase22/context-source-08/project/src/front')
def replace_once(s,a,b):
 assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
def remove_block(s,name):
 pat=re.compile(r'(?m)^(?:@unsafe\n)?(?:def|law) '+re.escape(name)+r'\b')
 while m:=pat.search(s):
  n=re.search(r'(?m)^(?:@unsafe\n)?(?:def|law|type) ',s[m.end():]); end=m.end()+n.start() if n else len(s)
  s=s[:m.start()]+s[end:]
 return s
# Delimited expression scanner, quoted literals and escaped characters preserved.
def close(s,pos):
 stack=[];quote=None;i=pos
 while i<len(s):
  c=s[i]
  if quote:
   if c=='\\': i+=2;continue
   if c==quote:quote=None
  elif c in "\"'":quote=c
  elif c in '([{<':stack.append(c)
  elif c in ')]}>':
   if stack and c=={'(':')','[':']','{':'}','<':'>'}[stack[-1]]:
    stack.pop()
    if not stack:return i
  i+=1
 raise Exception(s[pos:pos+100])
def args(s):
 out=[];at=0;i=0
 while i<len(s):
  if s[i] in '([{<':i=close(s,i)+1;continue
  if s[i] in "\"'":
   q=s[i];i+=1
   while i<len(s):
    if s[i]=='\\':i+=2;continue
    if s[i]==q:i+=1;break
    i+=1
   continue
  if s[i]==',':out.append(s[at:i].strip());at=i+1
  i+=1
 out.append(s[at:].strip());return out
for p in P.glob('*.bend'):
 s=p.read_text()
 # Semantic raw route is removed; cursor-only import scanning remains contextual.
 while m:=re.search(r'\bf_context_raw\(',s):
  if s[max(0,m.start()-4):m.start()]=='def ':break
  end=close(s,m.end()-1);s=s[:m.start()]+'False{}'+s[end+1:]
 # Remove definition before other calls to the same name.
 s=remove_block(s,'f_context_raw')
 while m:=re.search(r'\bf_context_raw\(',s):
  end=close(s,m.end()-1);s=s[:m.start()]+'False{}'+s[end+1:]
 s=s.replace('Bool.not(False{})','True{}')
 # Fold innermost explicit choices. These conditions come only from removed raw forks.
 while True:
  changed=False
  for m in reversed(list(re.finditer(r'\bf_choose\(',s))):
   end=close(s,m.end()-1);a=args(s[m.end():end])
   if len(a)!=4:continue
   cond=a[1]
   if cond=='False{}' or cond.startswith('False{} &&'):
    assert a[3].startswith('u => ');s=s[:m.start()]+a[3][5:]+s[end+1:];changed=True;break
   if cond=='True{}':
    assert a[2].startswith('u => ');s=s[:m.start()]+a[2][5:]+s[end+1:];changed=True;break
  if not changed:break
 s=s.replace('True{} && ','').replace('False{} || ','')
 s=s.replace('(False{} && f_eq(f_tx(ts), "<") && Char.is_upper(f_head(nm(n))))','False{}').replace(' || False{}','')
 # Grammar no longer needs the raw state constructor. A single contextual state remains.
 s=re.sub(r'(?m)^\s*case FCursorContext\{serial\}:.*\n','',s)
 s=s.replace('FParseScope{prior, index, ns, aliases, enabled}','FParseScope{prior, index, ns, aliases}')
 s=s.replace('FParseScope{Nil{}, missing(), "", Nil{}, False{}}','FParseScope{Nil{}, missing(), "", Nil{}}')
 s=s.replace('FParseScope{Con{d, prior}, index_set(index, d, index_hash(dn(d), 2166136261), 32), ns, aliases, True{}}','FParseScope{Con{d, prior}, index_set(index, d, index_hash(dn(d), 2166136261), 32), ns, aliases}')
 s=s.replace(', +enabled: Bool','')
 p.write_text(s)
# Explicit root and wrapper retirement.
p=P/'declarations.bend';s=p.read_text()
for name in ['f_parse','f_parse_indexed']:s=remove_block(s,name)
s=replace_once(s,'f_choose(KTerm, f_eq(tg(body), "FCompleted"), u => body, u => kt("Body", "", fc_start(pars, ty, body, Bool.not(f_eq(dk(f_find(name, book)), "Missing"))), 0, [kt("Params", "", 0, 0, pars), body]))','body')
s=s.replace('enabled && ','')
s=s.replace('# A module body sees completed dependencies; legacy parsers supply an empty scope.','# A module body sees completed dependencies and its actual namespace and aliases.')
p.write_text(s)
p=P/'contextual.bend';s=p.read_text()
s=replace_once(s,'f_choose(FParseScope, enabled,\n        u => f_context_declared(f_context_header(d, ns, aliases), prior, index, ns, aliases),\n        u => scope)','f_context_declared(f_context_header(d, ns, aliases), prior, index, ns, aliases)')
s=replace_once(s,'f_choose(FInput, enabled, u => f_space(ts), u => f_skip(ts))','f_space(ts)')
s=replace_once(s,'f_choose(FParsed, enabled,\n        u => f_context_definition_start(pars, ty, p, f_context_declare(KDef{name, "Def", terms_len(pars), f_choose(U32, f_def_fillable(f_decl_prior(name, scope)), u => dx(f_decl_prior(name, scope)), u => f_templates(pars)), ty, atom("Absent"), Nil{}, False{}, False{}}, scope)),\n        u => f_body_after(p))','f_context_definition_start(pars, ty, p, f_context_declare(KDef{name, "Def", terms_len(pars), f_choose(U32, f_def_fillable(f_decl_prior(name, scope)), u => dx(f_decl_prior(name, scope)), u => f_templates(pars)), ty, atom("Absent"), Nil{}, False{}, False{}}, scope))')
s=s.replace('f_context_definition_done(FCursorContext{0}, ','f_context_definition_done(')
s=s.replace('def f_context_definition_done(+outer: FCursorContext, +p: FParsed)','def f_context_definition_done(+p: FParsed)')
s=replace_once(s,'FParsed{f_choose(KTerm, f_context_stop(checked), u => checked, u => kt("FCompleted", "", 0, 0, [checked])), FInput{tokens, outer}}','FParsed{checked, rest}')
s=replace_once(s,'f_choose(FInput, enabled, u => FInput{tokens, FContextual{scope, Nil{}, 0}}, u => input)','FInput{tokens, FContextual{scope, Nil{}, 0}}')
s=s.replace('f_context_completed(f_choose(KTerm, complete, u => f_context_lower(dt(d)), u => dt(d)))','f_choose(KTerm, complete, u => f_context_lower(dt(d)), u => dt(d))').replace('f_context_completed(dv(d))','dv(d)').replace('f_context_unwrap(dt(d))','dt(d)').replace('f_context_unwrap(dv(d))','dv(d)')
for n in ['f_context_completed','f_context_unwrap']:s=remove_block(s,n)
s=replace_once(s,'f_context_pattern_computed(pattern, input, cursor, f_fresh_term(pattern, f_context_free_env(env), 0))','f_context_pattern_computed(pattern, input, cursor, f_context_higher(pattern))')
s=replace_once(s,'def f_context_pattern_computed(+pattern: KTerm, +input: FInput, +cursor: U32, +fresh: FFresh) -> FParsed:\n  match fresh:\n    case FFresh{term, next}: f_context_error_at(f_computed_pattern_error(pattern, term), input, cursor)','def f_context_pattern_computed(+pattern: KTerm, +input: FInput, +cursor: U32, +observed: KTerm) -> FParsed:\n  f_choose(FParsed, f_context_stop(observed), u => FParsed{observed, input},\n    u => f_context_pattern_observed(pattern, input, cursor, f_fresh_term(observed, f_context_free_env(f_context_outer(input)), 0)))\n\n@unsafe\ndef f_context_pattern_observed(+pattern: KTerm, +input: FInput, +cursor: U32, +fresh: FFresh) -> FParsed:\n  match fresh:\n    case FFresh{term, next}: f_context_error_at(f_computed_pattern_error(pattern, term), input, cursor)')
s=s.replace('# Contextual parser primitives retained for the pending production migration.','# Contextual parser state, lexical binding and completion boundaries.')
s=re.sub(r'\n{3,}','\n\n',s)
p.write_text(s)
p=P/'lexer.bend';s=p.read_text();s=s.replace('  FCursorContext{serial: U32}\n','');s=s.replace('FCursorContext{0}','FContextual{f_parse_scope_empty(), Nil{}, 0}');p.write_text(s)
# Rename the materializer now that it also owns beta/deferred conversion.
for p in P.glob('*.bend'):
 s=p.read_text().replace('f_context_validate_operators','f_context_materialize');p.write_text(s)
