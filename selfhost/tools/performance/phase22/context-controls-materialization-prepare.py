#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-controls-materialization-inputs-01';O.mkdir(parents=True);F=O/'fixtures';F.mkdir()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
pre='import Base\n'
cs=[
('discarded-lambda',pre+'def main.out() -> U32:\n  (k => 0)(x => 1 + 2)\n',True,'Unused lambda argument with implicit operator is never forced after beta; accept.'),
('eager-callee-first',pre+'def bad() -> U32:\n  (1 + 2)((x => x)(3 * 4))\n',False,'Higher converts callee before eager argument: plus before multiply.'),
('eager-argument-before-callee-body',pre+'def bad() -> U32:\n  (k => 1 + 2)(3 * 4)\n',False,'Deferred callee lambda body must not precede eager argument multiply.'),
('eager-sibling-before-deferred-child',pre+'def bad() -> Type:\n  Pair{x => 1 + 2, 3 * 4}\n',False,'Ctr eager second child error precedes first lambda body forced only by lower.'),
('returned-lambda-forced',pre+'def bad() -> U32 -> U32:\n  x => x + 1\n',False,'Full body lower phase forces returned lambda and rejects its untyped operator.'),
('raw-computed-pattern',pre+'def bad() -> U32:\n  (k => k)(0) = 1\n  2\n',False,'Pattern checkpoint sees raw App before completion beta can turn it into a literal.'),
('header-applied-lambda',pre+'def bad() -> (k => Unit + Unit)(Type):\n  Unit{}\n)\n',False,'Header higher beta forces selected lambda body before later top syntax.'),
('header-discarded-lambda',pre+'def main.out() -> (k => U32)(x => Unit + Unit):\n  0\n',True,'Header beta discards unused lambda argument without forcing its implicit operator.'),
]
rows=[];fixtures=[]
for n,s,ok,why in cs:
 p=F/(n+'.bend');p.write_text(s);fixtures.append({'id':n,'purpose':why,**ident(p)})
 for lane in ['parse','check']:rows.append({'id':f'context-materialization/{n}/{lane}','file':str(p),'lanes':[lane],'accept':ok,**({} if ok else {'rejectPhase':'parse'})})
for p,x in [(O/'selection.json',{'cases':rows}),(O/'plan.json',{'kind':'phase22-higher-lower-materialization-demand','frozenBeforeOutcomes':True,'observations':16,'pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','fixtures':fixtures,'inputs':[ident(__file__)],'policy':'Freeze prospective acceptance and source before outcomes. Retain actual pinned diagnostics and any disproved predictions. No candidate source edits.'})]:
 with p.open('x') as f:f.write(json.dumps(x,indent=2)+'\n')
p=R/'selfhost/tools/performance/phase22/context-controls-run-v6.mjs';q=p.with_name('context-controls-run-v7.mjs');assert not q.exists();q.write_text(p.read_text().replace('[60,24,20,40,12,4,26,2].includes(expectedCount)','[60,24,20,40,12,4,26,2,16].includes(expectedCount)'))
print(json.dumps({'prepared':True,'observations':16,'root':str(O)}))
