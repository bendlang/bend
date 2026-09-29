#!/usr/bin/env python3
"""Freeze an unconsumed contextual candidate and its exact source delta."""
from pathlib import Path
import sys,json,hashlib,difflib
R=Path(__file__).resolve().parents[4]
O=R/sys.argv[1]; N=O/'project'; P=R/'selfhost/build/phase21/group-range-source-02/project'
assert not (O/'manifest.json').exists()
def identity(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def members(root):return [{'path':str(p.relative_to(root)),**identity(p)}for p in sorted(root.rglob('*'))if p.is_file()]
changes=[]
for p in sorted(N.rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(N); old=P/rel
 if not old.exists()or old.read_bytes()!=p.read_bytes():
  before=old.read_text()if old.exists()else'';after=p.read_text()
  changes.append({'path':str(rel),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(p.read_bytes())-(old.stat().st_size if old.exists()else 0)})
  (O/(str(rel).replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='a/'+str(rel),tofile='b/'+str(rel))))
(O/'manifest.json').write_text(json.dumps({'complete':True,'stage':'isolated contextual production-route candidate; correctness and cost unproven','parent':str(P),'parentMembership':members(P),'candidateMembership':members(N),'changes':changes,'inputs':[identity(Path(__file__)),identity(R/'design/phase22/context-production-boundary.md')]},indent=2)+'\n')
(O/'workflow.json').write_text(json.dumps({'project':str(N),'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'3','jobs':1,'strictExact':True},indent=2)+'\n')
print(json.dumps({'changes':len(changes),'lines':sum(x['physicalLineDelta']for x in changes)}))
