#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
r=Path(__file__).resolve().parents[4];old=r/'selfhost/build/phase19/context-row-controls-03';out=r/'selfhost/build/phase19/context-row-controls-04';out.mkdir();shutil.copytree(old/'fixtures',out/'fixtures');sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();data=json.loads((old/'cases.json').read_text())
for c in data['cases']:c['file']=str(out/'fixtures'/Path(c['file']).name)
prefix='import Base\ndef global() -> Nat:\n  0n\n\ndef use(n:Nat) -> Nat:\n'
for name,body in {'zero-head':'  match:\n','zero-pattern-row':'  match n:\n    case:\n      0n\n','bound-head-no-rows':'  match n:\n'}.items():
 p=out/'fixtures'/(name+'.bend');p.write_text(prefix+body);data['cases'].append(dict(id='context-row/'+name,file=str(p),target='use',sourceBegin=1000001,originalLanes=[],supported=True))
data['predecessorControls']=dict(file=str(old/'cases.json'),sha256=sha(old/'cases.json'));assert len(data['cases'])==32
(out/'cases.json').write_text(json.dumps(data,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-prepare.py');inputs=[Path(__file__),old/'cases.json',out/'cases.json',*[Path(x['file'])for x in data['cases']]];(out/'manifest.json').write_text(json.dumps(dict(complete=True,inputs=[dict(file=str(p),sha256=sha(p))for p in inputs]),indent=2)+'\n');print(out)
