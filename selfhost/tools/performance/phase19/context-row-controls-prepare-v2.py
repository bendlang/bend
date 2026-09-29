#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[4];old=r/'selfhost/build/phase19/context-row-controls-01';out=r/'selfhost/build/phase19/context-row-controls-02';out.mkdir();shutil.copytree(old/'fixtures',out/'fixtures');sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();data=json.loads((old/'cases.json').read_text())
for c in data['cases']:c['file']=str(out/'fixtures'/Path(c['file']).name)
prefix='import Base\ndef global() -> Nat:\n  0n\n\n'
for name,body in {
 'id-zero-bound-var':'  match n:\n    case x:\n      x\n',
 'id-zero-qualified-ref':'  match Foo.bar:\n    case x:\n      0n\n',
 'id-zero-computed-app':'  match global(n):\n    case x:\n      0n\n',
 'id-zero-constructor':'  match Zero{}:\n    case x:\n      0n\n',
 'hit-error-before-miss-allocation':'  match n:\n    case Zero{}:\n      match global:\n        case x:\n          0n\n    case Succ{Succ{k}}:\n      k\n',
 'hit-success-then-miss-error':'  match n:\n    case Zero{}:\n      0n\n    case Succ{Succ{k}}:\n      match global:\n        case x:\n          k\n',
}.items():
 p=out/'fixtures'/(name+'.bend');p.write_text(prefix+'def use(n:Type) -> Nat:\n'+body);data['cases'].append(dict(id='context-row/'+name,file=str(p),target='use',sourceBegin=1000001,originalLanes=[],supported=True))
data['predecessorControls']=dict(file=str(old/'cases.json'),sha256=sha(old/'cases.json'));data['contract']+='; six explicit Var-id0 and flatten error-demand controls';assert len(data['cases'])==26
(out/'cases.json').write_text(json.dumps(data,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-prepare.py');inputs=[Path(__file__),old/'cases.json',out/'cases.json',*[Path(x['file'])for x in data['cases']]];(out/'manifest.json').write_text(json.dumps(dict(complete=True,inputs=[dict(file=str(p),sha256=sha(p))for p in inputs]),indent=2)+'\n');print(out)
