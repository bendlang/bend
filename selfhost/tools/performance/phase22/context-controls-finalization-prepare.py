#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase22/context-controls-finalization-inputs-01';O.mkdir(parents=True);F=O/'fixtures';F.mkdir();P=R/'selfhost/.bootstrap/upstream-phase8/tests'
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
def save(p,x):
 with p.open('x') as f:f.write(json.dumps(x,indent=2)+'\n')
pre='import Base\n'; cases=[];members=[]
new={
'outer-annotation':(pre+'def main.out() -> U32:\n  (1 + (2 * 3) : U32)\n',None,'Nested bare operator is legal until the outer annotation namespaces it.'),
'body-before-later-syntax':(pre+'def bad() -> U32:\n  1 + 2\n)\n','parse','Completed body materialization must refuse its unresolved operator before later top syntax.'),
'header-lazy-before-later-syntax':(pre+'def bad(x:Type) -> Unit + Unit:\n  x\n)\n','parse','Pin term_higher stores dependent header codomain lazily; determine actual precedence against later top syntax without guessing.'),
'erased-local-use':(pre+'def bad() -> U32:\n  -x = 1\n  x\n','check','Erased local span includes its quantity marker and preserves usage refusal.'),
'marked-term-astral':(pre+'def bad(x:U32) -> U32:\n  # 😀 preceding comment\n  U32.add(+x, 1)\n','check','Negative lexical Var identity preserves marked written span after astral/comment source.'),
}
for n,(s,phase,why) in new.items():
 p=F/(n+'.bend');p.write_text(s);members.append({'id':n,'purpose':why,**ident(p)})
 for lane in ['parse','check']:
  bad=phase=='parse' or phase=='check' and lane=='check'
  cases.append({'id':f'context-finalization/{n}/{lane}','file':str(p),'lanes':[lane],'accept':not bad,**({'rejectPhase':phase} if bad else {})})
(F/'lib').mkdir();(F/'cases').mkdir();lib=F/'lib/math.bend';lib.write_text(pre+'def value() -> U32:\n  6\n');p=F/'cases/relative.bend';p.write_text(pre+'import ../lib/math.bend as M\ndef main.out() -> U32:\n  (M.value() + 1 : U32)\n');members.append({'id':'relative-canonical-ref','purpose':'Canonical ../lib/math.value reference must not become U32../lib/math.value.','inputs':[ident(lib)],**ident(p)})
for lane in ['parse','check']:cases.append({'id':f'context-finalization/relative-canonical-ref/{lane}','file':str(p),'lanes':[lane],'accept':True})
reuse=[('bare-op','check/op_bare_refused.bend','parse'),('brace-op','check/op_brace_refused.bend','parse'),('call-arg-op','check/op_ns_call_arg.bend','parse'),('template-header-op','check/template_ns_late.bend','parse'),('marked-term','parse/plus_binder_term.bend','check'),('marked-local','check/cop_let_formation.bend','check'),('relative-upstream','parse/op_parent_import.bend',None)]
for n,rel,phase in reuse:
 p=P/rel;members.append({'id':n,'reused':True,**ident(p)})
 for lane in ['parse','check']:
  bad=phase=='parse' or phase=='check' and lane=='check'
  cases.append({'id':f'context-finalization/{n}/{lane}','file':str(p),'lanes':[lane],'accept':not bad,**({'rejectPhase':phase} if bad else {})})
assert len(cases)==26
save(O/'selection.json',{'cases':cases});save(O/'plan.json',{'kind':'phase22-finalization-independent-neighbors','frozenBeforeOutcomes':True,'observations':26,'parentAttempt':'selfhost/build/phase21/group-range-build-02','pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','inputs':[ident(__file__),ident(P/'import/unsafe_lib.bend')],'fixtures':members,'policy':'Keep all prospective assumptions, exact pinned output and raw statuses; no source edits. Materialization refusal and namespace resolution are separate checkpoints.','cause':'FCompleted bypassed old f_scope_reference operator refusal. Pin rejects a Ref only when its last dot is the leading dot; canonical relative-import references must remain ordinary names. Body higher/lower traversal forces bodies before later declarations; header higher traversal may leave binder codomains lazy.'})
p=R/'selfhost/tools/performance/phase22/context-controls-run-v4.mjs';q=p.with_name('context-controls-run-v5.mjs');assert not q.exists();q.write_text(p.read_text().replace('[60,24,20,40,12,4].includes(expectedCount)','[60,24,20,40,12,4,26].includes(expectedCount)'))
print(json.dumps({'prepared':True,'observations':26,'root':str(O)}))
