#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,os,stat,shutil,difflib,re
r=Path(__file__).resolve().parents[4];parent=r/'selfhost/build/phase18/cursor-source-02/project';out=r/'selfhost/build/phase19/context-source-01';out.mkdir();project=out/'project'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def inventory(p):
 rows=[]
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   f=Path(base)/name;s=f.lstat();row={'file':str(f.relative_to(p)),'mode':stat.S_IMODE(s.st_mode)}
   if f.is_symlink():rows.append({**row,'kind':'symlink','target':os.readlink(f)})
   elif f.is_file():rows.append({**row,'kind':'file','bytes':s.st_size,'sha256':sha(f)})
 return sorted(rows,key=lambda x:x['file'])
attempt=json.loads((r/'selfhost/build/phase18/cursor-build-01/attempt.json').read_text());assert attempt['checked'];assert attempt['api']['sha256']=='5d19edf596e9ade0bc5d43e5fbcd75bd0cf263d624de6e046a0966627ad9dd18';assert sha(Path(attempt['api']['file']))==attempt['api']['sha256']
for s in attempt['snapshot']['sources']:
 for side in ['original','frozen']:assert sha(Path(s[side]['file']))==s[side]['sha256']
oracle=r/'selfhost/build/phase19/context-oracle-01/oracle/report.json';assert json.loads(oracle.read_text())['pass']
before=inventory(parent);shutil.copytree(parent,project,symlinks=True);assert inventory(project)==before
module='''# Private Stage19 names/state primitives. No contextual body grammar yet.
type FContextSeed is Data:
  FContextSeed{+scope: FParseScope, +parameters: List<&2,KTerm>, next: U32}
type FContextProbe is Data:
  FProbeObserved{+first: FParsed, +opened: FParsed, +inner: FParsed, +after: FParsed, +rewound: FInput}
  FProbeError{+error: KTerm, +rest: FInput}
  FProbeUnsupported{+feature: String, +rest: FInput}

@unsafe
def f_context_resolve(+term: KTerm, +scope: FParseScope) -> KTerm:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      +alias = f_alias(nm(term), aliases)
      +checked = f_alias_named(term, aliases, prior, alias)
      +near = f_choose(String, String.eq(alias, nm(term)), u => f_qual_name(nm(term), ns), u => alias)
      f_choose(KTerm, String.eq(tg(checked), "Error"), u => checked,
        u => kt_span("Ref", f_choose(String, f_declared(near, prior) || Bool.not(f_declared(nm(term), prior)), u => near, u => nm(term)), 0, 1, Nil{}, kb(term), ke(term)))

@unsafe
def f_context_name(+term: KTerm, +input: FInput) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: FParsed{kt("Error", "contextual name requires contextual input", 0, 0, Nil{}), input}
        case FContextual{scope, env, next}:
          +bound = f_env(nm(term), env)
          f_choose(FParsed, String.eq(tg(bound), "Absent"),
            u => f_context_name_resolved(term, input, f_context_resolve(term, scope)),
            u => FParsed{kt_span("Var", nm(bound), ix(bound), 1, Nil{}, kb(term), ke(term)), input})

@unsafe
def f_context_name_resolved(+term: KTerm, +input: FInput, +resolved: KTerm) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: FParsed{kt("Error", "contextual name requires contextual input", 0, 0, Nil{}), input}
        case FContextual{scope, env, next}:
          f_choose(FParsed, String.eq(tg(resolved), "Error") || String.contains(nm(term), "."), u => FParsed{resolved, input},
            u => FParsed{kt_span("FName", nm(term), 0, 1, [kt_span("Var", nm(term), next, 1, Nil{}, kb(term), ke(term)), resolved], kb(term), ke(term)), FInput{tokens, FContextual{scope, env, U32.add(next, 1)}}})

@unsafe
def f_context_open(+term: KTerm, +input: FInput) -> FParsed:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: FParsed{kt("Error", "contextual open requires contextual input", 0, 0, Nil{}), input}
        case FContextual{scope, env, next}:
          +binder = kt_span("Var", nm(term), next, 1, Nil{}, kb(term), ke(term))
          FParsed{binder, FInput{tokens, FContextual{scope, f_choose(List<&2,KTerm>, String.eq(nm(term), "_"), u => env, u => Con{binder, env}), U32.add(next, 1)}}}

@unsafe
def f_context_close(+input: FInput, +outer: List<&2,KTerm>) -> FInput:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: input
        case FContextual{scope, env, next}: FInput{tokens, FContextual{scope, outer, next}}

@unsafe
def f_context_rewind(+old: FInput, +input: FInput) -> FInput:
  match old:
    case FInput{tokens, ignored}:
      match input:
        case FInput{discarded, context}: FInput{tokens, context}

@unsafe
def f_context_probe(+input: FInput, +seed: FContextSeed) -> FContextProbe:
  match input:
    case FInput{tokens, context}:
      match context:
        case FContextual{scope, env, next}: FProbeUnsupported{"raw context required", input}
        case FCursorContext{serial}:
          match seed:
            case FContextSeed{scope, parameters, next}:
              f_context_probe_start(FInput{tokens, FContextual{scope, List.reverse(&2,KTerm,parameters), next}})

@unsafe
def f_context_probe_start(+input: FInput) -> FContextProbe:
  f_choose(FContextProbe, f_valid_name(f_tx(input)) && (String.eq(f_tx(f_tl(input)), "<eof>") || String.is_empty(f_tx(f_tl(input)))),
    u => f_context_probe_first(input, kt_span("Ref", f_tx(input), 0, 1, Nil{}, f_begin(input), f_end(input)), f_context_name(kt_span("Ref", f_tx(input), 0, 1, Nil{}, f_begin(input), f_end(input)), f_tl(input))),
    u => FProbeUnsupported{"one ordinary name only", input})

@unsafe
def f_context_probe_first(+start: FInput, +origin: KTerm, +first: FParsed) -> FContextProbe:
  match first:
    case FParsed{term, rest}:
      f_choose(FContextProbe, String.eq(tg(term), "Error"), u => FProbeError{term, rest},
        u => f_context_probe_opened(start, origin, first, f_context_open(origin, rest)))

@unsafe
def f_context_probe_opened(+start: FInput, +origin: KTerm, +first: FParsed, +opened: FParsed) -> FContextProbe:
  match opened:
    case FParsed{term, rest}: f_context_probe_inner(start, origin, first, opened, f_context_name(origin, rest))

@unsafe
def f_context_probe_inner(+start: FInput, +origin: KTerm, +first: FParsed, +opened: FParsed, +inner: FParsed) -> FContextProbe:
  match start:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: FProbeUnsupported{"contextual start required", start}
        case FContextual{scope, env, next}:
          match inner:
            case FParsed{term, rest}:
              f_choose(FContextProbe, String.eq(tg(term), "Error"), u => FProbeError{term, rest},
                u => f_context_probe_after(start, first, opened, inner, f_context_name(origin, f_context_close(rest, env))))

@unsafe
def f_context_probe_after(+start: FInput, +first: FParsed, +opened: FParsed, +inner: FParsed, +after: FParsed) -> FContextProbe:
  match after:
    case FParsed{term, rest}:
      f_choose(FContextProbe, String.eq(tg(term), "Error"), u => FProbeError{term, rest},
        u => FProbeObserved{first, opened, inner, after, f_context_rewind(start, rest)})
'''
(project/'src/front/contextual.bend').write_text(module)
f=project/'src/front/lexer.bend';s=f.read_text();old='  FCursorContext{serial: U32}\n';assert s.count(old)==1;s=s.replace(old,old+'  FContextual{+scope: FParseScope, +env: List<&2,KTerm>, next: U32}\n');f.write_text(s)
f=project/'src/compiler.json';x=json.loads(f.read_text());x['modules'].insert(x['modules'].index('src/front/lexer.bend')+1,'src/front/contextual.bend');f.write_text(json.dumps(x,indent=2)+'\n')
f=project/'tools/typed-driver.mjs';s=f.read_text();old='  const exports=[...roots];';assert s.count(old)==1;s=s.replace(old,old+'\n  exports.push("f_context_probe");');f.write_text(s)
after=inventory(project);a={x['file']:x for x in before};b={x['file']:x for x in after};changes=[]
for name in sorted(a.keys()|b.keys()):
 if a.get(name)!=b.get(name):
  old=(parent/name).read_text()if name in a else '';new=(project/name).read_text();delta=len(new.splitlines())-len(old.splitlines());changes.append({'file':name,'lineDelta':delta,'byteDelta':len(new.encode())-len(old.encode())});(out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='parent/'+name,tofile='candidate/'+name)))
assert {x['file']for x in changes}=={'src/front/contextual.bend','src/front/lexer.bend','src/compiler.json','tools/typed-driver.mjs'}
assert sum(x['lineDelta']for x in changes)<=150,changes
inputs=[Path(__file__),r/'design/phase19/contextual-parser-slice.md',r/'design/phase19/names-state-stage1.md',r/'selfhost/build/phase19/context-controls-01/manifest.json',oracle]
for p in inputs:shutil.copy2(p,out/('consumed-'+p.name))
(out/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(parent),'parentMembership':before,'candidateMembership':after,'changes':changes,'inputs':[{'file':str(p),'sha256':sha(p)}for p in inputs],'stage':'names/state primitives only; body grammar unimplemented'},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(project),'upstream':attempt['config']['upstream'],'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n')
print(json.dumps({'source':str(project),'changes':changes}))
