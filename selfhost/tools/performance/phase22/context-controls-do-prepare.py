#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-controls-do-inputs-01';O.mkdir(parents=True);F=O/'fixtures';F.mkdir()
def identity(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def write(p,x):
 with p.open('x') as f:f.write(json.dumps(x,indent=2)+'\n')
pre='import Base\n';run=lambda body,header='Result<U32,U32>':pre+'def run() -> Result<U32,U32>:\n  do '+header+':\n'+body+'\n'
lib=F/'box.bend';lib.write_text(pre+'type Id<-A:Type> is Type:\n  MkId{value:A}\ndef Id.pure(-A:Type, value:A) -> Id<A>:\n  MkId{value}\ndef Id.bind(-A:Type, -B:Type, value:Id<A>, next:A -> Id<B>) -> Id<B>:\n  match value:\n    case MkId{value}:\n      next(value)\n')
cases=[
 ('alias-typed-assign-bind',pre+'import ./box.bend as Box\ndef run() -> Box.Id<U32>:\n  do Box.Id<U32>:\n    first:U32 = 4\n    next:U32 <- Box.MkId{5}\n    return U32.add(first, next)\n',None,'Real imported alias on monad head; typed assignment followed by typed bind.'),
 ('untyped-discard-bind',run('    U32 <- Done{3}\n    return 4'),None,'Untyped <- treats lhs as per-line result type, with an anonymous binder.'),
 ('implicit-unit-steps',run('    Done{Unit{}}\n    Done{Unit{}}; return 4'),None,'Newline and semicolon implicit steps infer Unit before final return.'),
 ('shadow-capture',pre+'def run(value:U32) -> Result<U32,U32>:\n  do Result<U32,U32>:\n    value:U32 = U32.add(value, 1)\n    next:U32 <- Done{value}\n    return next\n',None,'Assignment RHS sees outer value before the new same-name binder opens.'),
 ('repeated-underscore',run('    _:U32 <- Done{1}\n    _:U32 <- Done{2}\n    return 3'),None,'Repeated underscore binders must not become a usable shared binding.'),
 ('terminal-value',run('    Done{7}'),None,'A final constructor is checked against the header annotation, not dropped.'),
 ('rhs-error-before-return',run('    value:U32 <- )\n    return missing'),'parse','Earlier invalid RHS must win before later return/name interpretation.'),
 ('return-body-error',run('    value:U32 = 1\n    return )'),'parse','Valid assignment must preserve a later return expression syntax error.'),
 ('parenthesized-binder-comment',run('    # 😀 comment before the actual binder\n    (value):U32 <- Done{6}\n    # continuation comment\n    return value'),None,'Parenthesized single binder and UTF16/comment cursor preservation.'),
]
rows=[];fixtures=[]
for name,source,phase,purpose in cases:
 p=F/(name+'.bend');p.write_text(source);fixtures.append({'id':name,'purpose':purpose,**identity(p)})
 for lane in ['parse','check']:rows.append({'id':f'context-do/{name}/{lane}','file':str(p),'lanes':[lane],'accept':phase is None,**({} if phase is None else {'rejectPhase':phase})})
pin=R/'selfhost/.bootstrap/upstream-phase8/tests/check/do_header_quantity_span.bend'
for lane in ['parse','check']:rows.append({'id':f'context-do/implicit-leading-quantities/{lane}','file':str(pin),'lanes':[lane],'accept':lane=='parse',**({} if lane=='parse' else {'rejectPhase':'check'})})
assert len(rows)==20
write(O/'selection.json',{'cases':rows});write(O/'plan.json',{'kind':'phase22-independent-do-boundaries','status':'frozen-before-first-do-boundary-probe','parentAttempt':'selfhost/build/phase21/group-range-build-02','parentApi':'44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0','pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','observations':20,'fixtures':fixtures,'inputs':[identity(__file__),identity(lib),identity(pin)],'scope':'Public supplied-file loader parse/check controls for upcoming real do owner; exact pinned diagnostics and original raw statuses retained. Original main monad_destructure remains in initial60; no replacement fixture.','comparison':'Preserve original pinned protocol and parent exacts. Any acceptance/phase change must agree with pin. No fixture/oracle modification after consumption.'})
print(json.dumps({'prepared':True,'observations':20,'root':str(O)}))
