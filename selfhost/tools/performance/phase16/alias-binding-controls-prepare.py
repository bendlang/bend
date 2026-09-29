#!/usr/bin/env python3
from pathlib import Path
import json,shutil,hashlib
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'selfhost/build/phase16/alias-binding-controls-01';OUT.mkdir();F=OUT/'fixtures';F.mkdir();shutil.copy2(ROOT/'selfhost/build/phase16/module-names-controls-01/fixtures/mod.bend',F/'mod.bend')
(F/'lib.bend').write_text('import Base\ntype Box<A:Type> is Type:\n  Mk{value:A}\ndef apply(~f:Nat -> Nat, x:Nat) -> Nat:\n  f(x)\n')
head='import Base\nimport ./mod.bend as M\n';cases=[
 ('direct',head+'def keep(M.double: Nat) -> Nat:\n  M.double\n',True,None),
 ('applied',head+'def apply(M.double: Nat -> Nat, n: Nat) -> Nat:\n  M.double(n)\n',True,None),
 ('nested',head+'def keep(M.double: Nat) -> Nat:\n  (x => M.double)(0n)\n',True,None),
 ('nested-rebinding',head+'def keep(M.double: Nat) -> Nat:\n  (M.double => M.double)(M.double)\n',True,None),
 ('sibling-alias',head+'import ./mod.bend as N\ndef keep(M.double: Nat) -> Nat:\n  N.double(M.double)\n',True,None),
 ('bound-pattern',head+'def keep(M.double: Nat, n: Nat) -> Nat:\n  match n:\n    case M.double:\n      M.double\n',True,None),
 ('unbound-pattern',head+'def keep(n: Nat) -> Nat:\n  match n:\n    case M.double:\n      0n\n',False,'parse'),
 ('constructor-pattern','import Base\nimport ./lib.bend as L\ndef unbox(v:L.Box<Nat>) -> Nat:\n  match v:\n    case L.Mk{n}:\n      n\n',True,None),
 ('family-and-template','import Base\nimport ./lib.bend as L\ndef box(n:Nat) -> L.Box<Nat>:\n  L.Mk{L.apply(~(x => x), n)}\n',True,None),
 ('template-shadow','import Base\nimport ./lib.bend as L\ndef use(L.apply:Nat -> Nat, n:Nat) -> Nat:\n  L.apply(n)\n',True,None),
 ('fresh-qualified-lambda',head+'def bad() -> Nat -> Nat:\n  M.double => M.double\n',False,'parse'),
]
rows=[]
for name,source,accept,phase in cases:
 p=F/(name+'.bend');p.write_text(source);rows.append({'id':'alias-binding/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept,**({'rejectPhase':phase} if phase else {})})
(OUT/'selection.json').write_text(json.dumps({'cases':rows},indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'plan':'experiments/phase16/P16-alias-lexical-bindings.md','inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(F.iterdir())]},indent=2)+'\n');print(OUT)
