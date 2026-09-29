#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'selfhost/build/phase16/alias-pattern-controls-02';OUT.mkdir();F=OUT/'fixtures';F.mkdir();shutil.copy2(ROOT/'selfhost/build/phase16/alias-binding-controls-01/fixtures/mod.bend',F/'mod.bend');head='import Base\n';box='type Box is Type:\n  Mk{value:Nat}\n';cases=[
('fresh',head+'def pick(n:Nat) -> Nat:\n  match n:\n    case Foo.bar:\n      0n\n',False),
('bound',head+'def pick(Foo.bar:Nat, n:Nat) -> Nat:\n  match n:\n    case Foo.bar:\n      Foo.bar\n',True),
('canonical-reference',head+'import ./mod.bend as M\ndef pick(n:Nat) -> Nat:\n  match n:\n    case mod.double:\n      0n\n',False),
('canonical-bound',head+'import ./mod.bend as M\ndef pick(mod.double:Nat,n:Nat) -> Nat:\n  match n:\n    case mod.double:\n      mod.double\n',True),
('nested-fresh',head+box+'def pick(box:Box) -> Nat:\n  match box:\n    case Mk{Foo.bar}:\n      0n\n',False),
('nested-bound',head+box+'def pick(Foo.bar:Nat,box:Box) -> Nat:\n  match box:\n    case Mk{Foo.bar}:\n      Foo.bar\n',True),
('ordinary-fresh',head+'def pick(n:Nat) -> Nat:\n  match n:\n    case fresh:\n      fresh\n',True),
]
rows=[]
for name,source,accept in cases:
 p=F/(name+'.bend');p.write_text(source);rows.append({'id':'qualified-pattern/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept,**({}if accept else{'rejectPhase':'parse'})})
(OUT/'selection.json').write_text(json.dumps({'cases':rows},indent=2)+'\n');prior=json.loads((ROOT/'selfhost/build/phase16/alias-binding-lambda-controls-01/selection.json').read_text())['cases'];(OUT/'combined-selection.json').write_text(json.dumps({'cases':prior+rows},indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'plan':'experiments/phase16/P16-qualified-pattern-bindings.md','inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(F.iterdir())]},indent=2)+'\n');print(OUT)
