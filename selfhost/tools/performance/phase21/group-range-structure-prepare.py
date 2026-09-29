"""Freeze independent R1 graph fixtures without changing compiler sources."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase21/group-range-structure-controls-01';O.mkdir();(O/'fixtures').mkdir()
h='def main() -> Type:\n';box='type Box is Data:\n  Mk{value: Type}\n';wrap='type Wrap is Data:\n  Wrap{box: Box}\n'
rows=[
 ('plain',h+'  x = Type\n  x\n'),('grouped',h+'  (x = Type; x)\n'),
 ('multi-name',h+'  (variable = Type; variable)\n'),('nested',h+'  ((outer = Type; outer))\n'),
 ('same-name',h+'  (x = Type; (x = x; x))\n'),
 ('typed-ann',h+'  (x: Type = Type; x)\n'),('typed-plain',h+'  x: Type = Type\n  x\n'),
 ('parallel',h+'  (x y = Type Type; x)\n'),('nested-parallel',h+'  ((x y = Type Type; y))\n'),
 ('erased',h+'  (-x = Type; x)\n'),('marked',h+'  (+x = Type; x)\n'),
 ('astral-comment',h+'  (# 😀\n    long_name = Type; long_name)\n'),
 ('callee','def identity(x: Type) -> Type: x\n'+h+'  (f = identity; f)(Type)\n'),
 ('argument','def identity(x: Type) -> Type: x\n'+h+'  identity((x = Type; x))\n'),
 ('outer-pattern',h+'  (x = Type; x) = Type\n  Type\n'),
 ('typed-outer-pattern',h+'  (x: Type = Type; x) = Type\n  Type\n'),
 ('constructor-plain',box+'def main(box: Box) -> Type:\n  Mk{x} = box\n  x\n'),
 ('constructor-group',box+'def main(box: Box) -> Type:\n  (Mk{x} = box; x)\n'),
 ('constructor-group-pattern',box+'def main(box: Box) -> Type:\n  (Mk{x} = box; x) = Type\n  Type\n'),
 ('nested-constructor',box+wrap+'def main(w: Wrap) -> Type:\n  Wrap{Mk{x}} = w\n  x\n'),
 ('typed-constructor',box+'def main(box: Box) -> Type:\n  (Mk{x}: Box = box; x)\n'),
 ('bound-empty-call','def main(x: Type) -> Type:\n  (x() = Type; x)\n'),
 ('unbound-empty-call',h+'  (x() = Type; x)\n'),
]
cases=[]
for name,source in rows:
 p=O/'fixtures'/f'{name}.bend';p.write_text(source);cases.append({'name':name,'file':str(p),'base':False})
for name in ['local','local-annotated','local-callee','parallel']:
 p=R/'selfhost/build/phase17/group-controls-03/fixtures'/f'{name}.bend';assert p.is_file(),p;cases.append({'name':'base-'+name,'file':str(p),'base':True})
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
plan={'kind':'phase21-independent-r1-structure-controls','frozen':True,'parentAttempt':str(R/'selfhost/build/phase20/import-diagnostic-build-04'),'parentApiSha256':'40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c','indexedStart':4097,'cases':cases,'inputs':[identity(Path(__file__)),identity(R/'design/phase21/group-range-structure.md'),identity(R/'selfhost/build/phase21/group-start-state-01.json'),*[identity(Path(c['file']))for c in cases]]}
(O/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');print(O)
