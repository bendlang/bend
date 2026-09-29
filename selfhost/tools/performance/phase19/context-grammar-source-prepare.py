#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,os,stat,shutil,difflib
r=Path(__file__).resolve().parents[4];parent=r/'selfhost/build/phase19/context-source-02/project';out=r/'selfhost/build/phase19/context-grammar-source-01';out.mkdir();project=out/'project'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def inventory(p):
 rows=[]
 for base,dirs,files in os.walk(p,followlinks=False):
  for name in dirs+files:
   f=Path(base)/name;s=f.lstat();row={'file':str(f.relative_to(p)),'mode':stat.S_IMODE(s.st_mode)}
   if f.is_symlink():rows.append({**row,'kind':'symlink','target':os.readlink(f)})
   elif f.is_file():rows.append({**row,'kind':'file','bytes':s.st_size,'sha256':sha(f)})
 return sorted(rows,key=lambda x:x['file'])
attempt=json.loads((r/'selfhost/build/phase19/context-build-02/attempt.json').read_text());assert attempt['checked'];assert attempt['api']['sha256']=='7c4d83bdb535eb1ed8cac7c60a773ec5942ad75549fa983e727de71517eac77e';assert sha(Path(attempt['api']['file']))==attempt['api']['sha256']
for s in attempt['snapshot']['sources']:
 for side in ['original','frozen']:assert sha(Path(s[side]['file']))==s[side]['sha256']
oracle=r/'selfhost/build/phase19/context-grammar-oracle-01/oracle/report.json';assert json.loads(oracle.read_text())['pass']
before=inventory(parent);shutil.copytree(parent,project,symlinks=True);assert inventory(project)==before
module='''
# Private names-stage route through the existing expression grammar; never Core.
type FNamesResult is Data:
  FNamesParsed{+term: KTerm, +rest: FInput}
  FNamesError{+error: KTerm, +rest: FInput}
  FNamesUnsupported{+feature: String, +rest: FInput}

@unsafe
def f_context_raw(+input: FInput) -> Bool:
  match input:
    case FInput{tokens, context}:
      match context:
        case FCursorContext{serial}: True{}
        case FContextual{scope, env, next}: False{}

@unsafe
def f_context_stop(+term: KTerm) -> Bool:
  String.eq(tg(term), "Error") || String.eq(tg(term), "FNamesStop")

@unsafe
def f_context_unsupported(+input: FInput, +feature: String) -> FParsed:
  FParsed{kt_span("FNamesStop", feature, 0, 0, Nil{}, f_begin(input), f_end(input)), input}

@unsafe
def f_context_atom_name(+input: FInput) -> FParsed:
  f_choose(FParsed, f_context_raw(input),
    u => FParsed{kt("Ref", f_tx(input), f_atid(input), 1, Nil{}), f_tl(input)},
    u => f_context_name(kt_span("Ref", f_tx(input), 0, 1, Nil{}, f_begin(input), f_end(input)), f_tl(input)))

@unsafe
def f_context_atom_ready(+input: FInput) -> Bool:
  ((U32.is_eq(f_kind_token(input), 1) && f_valid_name(f_tx(input)) && Bool.not(f_reserved(f_tx(input))) && Bool.not(Char.is_digit(f_head(f_tx(input))))) && Bool.not(String.eq(f_tx(f_tl(input)), "{"))) || String.eq(f_tx(input), ")") || String.eq(f_tx(input), ",") || String.eq(f_tx(input), ";") || String.eq(f_tx(input), "<eof>") || String.is_empty(f_tx(input)) || String.eq(f_tx(input), "return")

@unsafe
def f_context_call_head(+term: KTerm) -> KTerm:
  f_choose(KTerm, String.eq(tg(term), "FName"), u => kid(term, 1), u => term)

@unsafe
def f_context_grow(+p: FParsed, +min: U32) -> FParsed:
  match p:
    case FParsed{term, rest}:
      f_choose(FParsed, f_context_stop(term), u => p, u =>
        f_choose(FParsed, U32.is_gt(f_prec(f_tx(f_space(rest))), 0) || String.eq(f_tx(f_space(rest)), "[") || String.eq(f_tx(f_space(rest)), "!") || String.eq(f_tx(f_space(rest)), "=") || String.eq(f_tx(f_space(rest)), ":") || String.eq(f_tx(f_space(rest)), "<-"),
          u => f_context_unsupported(rest, "expression owner outside names/calls"),
          u => f_choose(FParsed, String.eq(f_tx(rest), "\\n"), u => FParsed{term, f_space(rest)}, u => f_grow_existing(p, min))))

@unsafe
def f_context_failure_rest(+start: FInput, +end: FInput) -> FInput:
  f_choose(FInput, f_context_raw(start), u => f_empty(start), u => end)

@unsafe
def f_context_term_probe(+input: FInput, +seed: FContextSeed) -> FNamesResult:
  match input:
    case FInput{tokens, context}:
      match context:
        case FContextual{scope, env, next}: FNamesUnsupported{"raw context required", input}
        case FCursorContext{serial}:
          match seed:
            case FContextSeed{scope, parameters, next}:
              f_context_term_done(f_expr(FInput{tokens, FContextual{scope, f_context_parameters(parameters, Nil{}), next}}, 0))

@unsafe
def f_context_term_done(+parsed: FParsed) -> FNamesResult:
  match parsed:
    case FParsed{term, rest}:
      f_choose(FNamesResult, String.eq(tg(term), "Error"), u => FNamesError{term, rest},
        u => f_choose(FNamesResult, String.eq(tg(term), "FNamesStop"), u => FNamesUnsupported{nm(term), rest}, u => FNamesParsed{term, rest}))
'''
f=project/'src/front/contextual.bend';f.write_text(f.read_text()+module)
f=project/'src/front/parser.bend';s=f.read_text()
def replace(old,new):
 global s
 assert s.count(old)==1,(old,s.count(old));s=s.replace(old,new)
replace('u => FParsed{kt("Ref", f_tx(ts), f_atid(ts), 1, Nil{}), f_tl(ts)})))','u => f_context_atom_name(ts))))')
replace('def f_atom(ts):\n','def f_atom(ts):\n  f_choose(FParsed, f_context_raw(ts) || f_context_atom_ready(ts), u => f_atom_existing(ts), u => f_context_unsupported(ts, "atom owner outside names/calls"))\n\n@unsafe\ndef f_atom_existing(ts):\n')
replace('def f_grow(p, min):\n','def f_grow(p, min):\n  f_choose(FParsed, f_context_raw(f_pr(p)), u => f_grow_existing(p, min), u => f_context_grow(p, min))\n\n@unsafe\ndef f_grow_existing(p, min):\n')
replace('def f_args(ts, end, acc):\n','def f_args(ts, end, acc):\n  f_choose(FParsed, Bool.not(f_context_raw(ts)) && f_eq(f_tx(f_space(ts)), "~"), u => f_context_unsupported(ts, "template argument owner"), u => f_args_existing(ts, end, acc))\n\n@unsafe\ndef f_args_existing(ts, end, acc):\n')
replace('f_grow_args(n, f_tx(ts), min,','f_grow_args(f_context_call_head(n), f_tx(ts), min,')
replace('f_choose(FParsed, f_eq(tg(n), "Error"), u => FParsed{n, ts}, u => f_args(', 'f_choose(FParsed, f_context_stop(n), u => FParsed{n, ts}, u => f_args(')
replace('f_choose(FParsed, f_eq(tg(args), "Error"), u => FParsed{args, ts}, u => f_grow(', 'f_choose(FParsed, f_context_stop(args), u => FParsed{args, ts}, u => f_grow(')
replace('f_eq(tg(n), "Error") || (U32.is_gt(kb(n), 0)', 'f_context_stop(n) || (U32.is_gt(kb(n), 0)')
replace('[kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseToken", f_tx(ts), 0, 0, Nil{})]), f_empty(ts)}','[kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseToken", f_tx(ts), 0, 0, Nil{})]), f_context_failure_rest(ts, ts)}')
replace('kt("ParseRange", observed, f_line(end), f_col(end), Nil{})]), f_empty(start)}','kt("ParseRange", observed, f_line(end), f_col(end), Nil{})]), f_context_failure_rest(start, end)}')
f.write_text(s)
f=project/'tools/typed-driver.mjs';s=f.read_text();old='  exports.push("f_context_probe");';assert s.count(old)==1;f.write_text(s.replace(old,old+'\n  exports.push("f_context_term_probe");'))
after=inventory(project);a={x['file']:x for x in before};b={x['file']:x for x in after};changes=[]
for name in sorted(a.keys()|b.keys()):
 if a.get(name)!=b.get(name):
  old=(parent/name).read_text()if name in a else '';new=(project/name).read_text();changes.append(dict(file=name,lineDelta=len(new.splitlines())-len(old.splitlines()),byteDelta=len(new.encode())-len(old.encode()),definitionDelta=new.count('\ndef ')-old.count('\ndef ')));(out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='parent/'+name,tofile='candidate/'+name)))
assert {x['file']for x in changes}=={'src/front/contextual.bend','src/front/parser.bend','tools/typed-driver.mjs'}
assert sum(x['lineDelta']for x in changes)<=150,changes
inputs=[Path(__file__),r/'design/phase19/names-grammar-routing.md',r/'selfhost/build/phase19/context-grammar-controls-01/manifest.json',oracle]
for p in inputs:shutil.copy2(p,out/('consumed-'+p.name))
(out/'manifest.json').write_text(json.dumps(dict(complete=True,parent=str(parent),parentMembership=before,candidateMembership=after,changes=changes,inputs=[dict(file=str(p),sha256=sha(p))for p in inputs],stage='private names/calls only; no Core or loader routing'),indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps(dict(project=str(project),upstream=attempt['config']['upstream'],cpu='3',jobs=1,profile='equality',timeoutMs=30000),indent=2)+'\n')
print(json.dumps(dict(source=str(project),changes=changes)))
