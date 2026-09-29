#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-controls-inputs-01';O.mkdir(parents=True);(O/'fixtures').mkdir()
def identity(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def read(p):return json.loads(Path(p).read_text())
def write(p,x):
 with p.open('x') as f:f.write(json.dumps(x,indent=2)+'\n')
old=R/'selfhost/build/phase18/cursor-controls-01/selection.json';comma=R/'selfhost/build/phase21/group-comma-controls-01/selection.json';constructors=R/'selfhost/build/phase21/group-range-controls-inputs-02/selection.json'
lookup={c['id']:c for p in [old,comma] for c in read(p)['cases']}
ids=['group/body-comma','group-comma/completed-nested-local-tuple','group-comma/raw-parallel-comma','group-comma/completed-parallel-tuple','group-comma/raw-typed-local-comma','group-comma/completed-typed-local-tuple','group-comma/invalid-type-pattern-comma','group-comma/rhs-before-pattern-comma','parser-checkpoint/parallel-frame','parser-checkpoint/lambda-frame','parser-checkpoint/all-frame','parser-checkpoint/do-frame','parser-checkpoint/module-alias-frame','parser-checkpoint/alias-shadow-frame','rejected-stage/body-before-later-syntax','rejected-stage/group-before-later-syntax','rejected-stage/body-before-later-pattern','rejected-stage/group-before-later-pattern','marked-pattern/alias-bound','marked-pattern/empty-unbound','group/local-bang','check/monad_do_destructure.bend']
reused=[lookup[k] for k in ids]+read(constructors)['cases'];assert sum(len(c['lanes']) for c in reused)==48
pre='import Base\n'
programs=[
 ('parallel-outer-scope',pre+'def combine(x:U32) -> U32:\n  x y = {3 : U32} x\n  U32.add(x, y)\ndef main() -> U32:\n  combine(5)\n#|8\n','second RHS must see outer x=5, not new x=3'),
 ('parallel-global-shadow',pre+'def value() -> U32:\n  41\ndef main() -> U32:\n  value copied = {1 : U32} {value : U32}\n  U32.add(value, copied)\n#|42\n','second RHS resolves prior global value before simultaneous binders open'),
 ('nested-lambda-capture',pre+'def main() -> U32:\n  (x = {10 : U32}; f = {y => U32.add(x, y) : U32 -> U32}; (x = {100 : U32}; f(2)))\n#|12\n','closure captures outer x and survives same-name nested binder'),
 ('erased-marked-local',pre+'def main() -> U32:\n  (-discarded = {99 : U32}; +value = {6 : U32}; U32.add(value, value))\n#|12\n','erased local and explicit unrestricted binder retain their quantities'),
 ('annotation-group-type',pre+'def main() -> U32:\n  {(value = {11 : U32}; value) : (T = {U32 : Type}; T)}\n#|11\n','completed groups in both annotation value and type retain stage and scope'),
]
front=list(reused);execution=[];descriptions=[]
for name,source,why in programs:
 f=O/'fixtures'/f'{name}.bend';f.write_text(source)
 front.append({'id':'context-program/'+name,'file':str(f),'lanes':['parse','check']})
 execution.append({'id':'context-program/'+name,'file':str(f),'lanes':['check','interpreter','js','native']})
 descriptions.append({'id':name,'purpose':why,**identity(f)})
do=R/'selfhost/.bootstrap/upstream-phase8/tests/eval/do_notation_result.bend'
front.append({'id':'eval/do_notation_result.bend','lanes':['parse','check']});execution.append({'id':'eval/do_notation_result.bend','lanes':['check','interpreter','js','native']})
write(O/'selection.json',{'cases':front});write(O/'program-selection.json',{'cases':execution});assert sum(len(c['lanes']) for c in front)==60
fixtures={Path(c['file']).resolve() for c in front if c.get('file')};fixtures.add(do)
# Bind original source fixtures and imported siblings without copying prior payloads.
siblings=set()
for f in fixtures:
 if not str(f).startswith(str(R/'selfhost/.bootstrap/')):siblings.update(p for p in f.parent.iterdir() if p.is_file())
inputs=[identity(p) for p in [Path(__file__),old,comma,constructors,R/'design/phase19/saved-row-group-frontier.md',R/'design/phase21/group-boundaries.md',R/'design/phase21/group-comma-controls.md',do]+sorted(siblings)]
write(O/'plan.json',{'kind':'phase22-independent-context-controls-plan','status':'frozen-before-baseline-and-migration-candidate','parentAttempt':'selfhost/build/phase21/group-range-build-02','parentApi':'44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0','pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','frontendObservations':60,'executionObservations':24,'reusedBoundaryFixtures':24,'newOrdinaryPrograms':5,'reusedOrdinaryPrograms':1,'newPrograms':descriptions,'scope':'Real public parse/check and emitted/interpreted user programs; no partial contextual probe counts as production success. Original fixture bytes/oracles/statuses remain.','comparison':'Full pinned observation protocol must remain equal between runs. Preserve every prior exact match. Any primitive behavior change must become exactly the pinned primitive outcome; no new semantic mismatch is allowed. Report raw false suites separately from healthy collection.','resourcePolicy':{'cpu':2,'heapMb':4096,'stackKb':4096,'jobs':1},'inputs':inputs})
print(json.dumps({'prepared':True,'root':str(O),'frontend':60,'execution':24}))
