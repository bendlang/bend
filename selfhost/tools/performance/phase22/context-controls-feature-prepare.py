#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4]; O=R/'selfhost/build/phase22/context-controls-feature-inputs-01';O.mkdir(parents=True);F=O/'fixtures';F.mkdir();P=R/'selfhost/.bootstrap/upstream-phase8/tests'
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
def save(p,x):
 with p.open('x') as f:f.write(json.dumps(x,indent=2)+'\n')
pre='import Base\n'; main='def main() -> IO(Unit):\n  IO.print(U32.show(main.out()))\n'
new={
'rewrite-shadow':(pre+'def shadow(h:U32, e:{Type == Type : Type}) -> U32:\n  %h@e : U32; h\ndef main.out() -> U32:\n  shadow(7, {==})\n'+main+'#|7\n',None),
'rewrite-proof-error':(pre+'def bad(e:{Type == Type : Type}) -> U32:\n  %h@) : ); )\n','parse'),
'rewrite-motive-error':(pre+'def bad(e:{Type == Type : Type}) -> U32:\n  %h@e : ); )\n','parse'),
'rewrite-body-error':(pre+'def bad(e:{Type == Type : Type}) -> U32:\n  %h@e : U32; )\n','parse'),
'array-u32-count':(pre+'def run() -> Array<U32>:\n  [0 : U32*4]\n','parse'),
'array-explicit-succ':(pre+'def run() -> Array<U32>:\n  [0 : U32*Succ{Succ{Zero{}}}]\n',None),
'array-namespace-before-count':(pre+'def bad() -> Array<U32>:\n  [(x = 1; x + 1) : 0*3n]\n','parse'),
'array-close-before-namespace':(pre+'def bad() -> Array<U32>:\n  [(x = 1; x + 1) : 0*3n)\n','parse'),
'index-alias-before-bad-rhs':(pre+'import ./words.bend as U32\ndef bad(a:Array<U32>) -> Array<U32>:\n  a[1 + 1] <- )\n','parse'),
'index-alias-before-good-rhs':(pre+'import ./words.bend as U32\ndef bad(a:Array<U32>) -> Array<U32>:\n  a[1 + 1] <- 7\n','parse'),
'array-set-written':(pre+'def finish(r:Array<U32> & U32) -> U32:\n  (a, value) = r\n  value\ndef main.out() -> U32:\n  a = [0 : U32*2n]\n  Array.set(U32, a, 0, 9)\n  finish(a[0])\n'+main+'#|9\n',None),
'array-set-nonvar':(pre+'def bad() -> U32:\n  Array.set(U32, [0 : U32*2n], 0, 9);\n  0\n','parse'),
}
lib=F/'words.bend';lib.write_text('def only() -> Type:\n  Type\n')
reuse=[('rewrite-explicit','proof/rewrite_explicit_motive.bend',None),('rewrite-evidence','proof/rewrite_motive_evidence.bend',None),('rewrite-motive-type-error','check/error_window_rewrite_proof.bend','check'),('array-literal','parse/array_literal.bend',None),('array-count-odd','parse/array_count_odd.bend','parse'),('array-count-overflow','parse/array_count_sum.bend','parse'),('array-write-statement','parse/array_write_stmt.bend',None),('array-set-wildcard','eval/array_set_wildcard.bend',None)]
fixtures=[]; cases=[]; by={}
for name,(source,phase) in new.items():
 p=F/(name+'.bend');p.write_text(source);fixtures.append({'id':name,'reused':False,**ident(p)});by[name]=p
 for lane in ['parse','check']:
  reject=phase=='parse' or phase=='check' and lane=='check'
  cases.append({'id':f'context-feature/{name}/{lane}','file':str(p),'lanes':[lane],'accept':not reject,**({'rejectPhase':phase} if reject else {})})
for name,rel,phase in reuse:
 p=P/rel;fixtures.append({'id':name,'reused':True,**ident(p)});by[name]=p
 for lane in ['parse','check']:
  reject=phase=='parse' or phase=='check' and lane=='check'
  cases.append({'id':f'context-feature/{name}/{lane}','file':str(p),'lanes':[lane],'accept':not reject,**({'rejectPhase':phase} if reject else {})})
assert len(cases)==40
programs=[{'id':f'context-feature-program/{name}','file':str(by[name]),'lanes':['check','interpreter','js','native']} for name in ['rewrite-shadow','array-set-written','array-set-wildcard']]
save(O/'selection.json',{'cases':cases});save(O/'program-selection.json',{'cases':programs})
save(O/'plan.json',{'kind':'phase22-independent-rewrite-array-boundaries','frozenBeforeOutcomes':True,'parentAttempt':'selfhost/build/phase21/group-range-build-02','pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','observations':40,'programObservations':12,'newFixtures':12,'reusedFixtures':8,'fixtures':fixtures,'inputs':[ident(__file__),ident(lib)],'scope':['Rewrite endpoint _ and named evidence scope; scope closes before body; proof/motive/body error order.','Nat versus U32 array counts, explicit Succ/Zero counts, overflow/non-power counts and closing-delimiter precedence.','Completed Let namespace failure before count; module alias resolution of index operators before a malformed RHS.','Written Array.set and sugar implicit rebinding, including no binder for a non-variable array argument.'],'predictions':['Shared pre-fix namespace Let rebuild can hide Error and allow count error to win; root has prepared shallow propagation correction, to be tested only on later image.','Raw production route is not the new contextual parser. Its unchanged failures must remain visible.'],'policy':'Frozen prospective accept/refusal expectations are retained even if the pinned oracle disproves them; do not change fixtures or protocol. Compare exact pin outcomes and parent no-regression separately.'})
print(json.dumps({'prepared':True,'observations':40,'programObservations':12,'root':str(O)}))
