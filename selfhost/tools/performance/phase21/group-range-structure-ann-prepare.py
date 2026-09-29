from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parents[4];O=R/'selfhost/build/phase21/group-range-structure-ann-controls-01';O.mkdir();(O/'fixtures').mkdir()
h='def main() -> Type:\n'
rows=[
 ('bare',h+'  x: Type = Type; x\n'),
 ('grouped-local',h+'  (x: Type = Type; x)\n'),
 ('rhs-spaces',h+'  (x: Type = Type   ; x)\n'),
 ('rhs-comment',h+'  (x: Type = Type # comment\n    ; x)\n'),
 ('rhs-newline',h+'  x: Type = Type\n  x\n'),
 ('rhs-group',h+'  (x: Type = (Type); x)\n'),
 ('rhs-nested-group',h+'  (x: Type = ((Type)); x)\n'),
 ('rhs-local-group',h+'  (x: Type = (y = Type; y); x)\n'),
 ('binder-group',h+'  ((x): Type = Type; x)\n'),
 ('binder-nested-group',h+'  (((x)): Type = Type; x)\n'),
 ('erased',h+'  (-x: Type = Type; x)\n'),
 ('erased-group',h+'  (-(x): Type = Type; x)\n'),
 ('marked',h+'  (+x: Type = Type; x)\n'),
 ('marked-group',h+'  ((+x): Type = Type; x)\n'),
 ('astral-prefix',h+'  (# 😀 before\n    x: Type = Type; x)\n'),
 ('rhs-astral-comment',h+'  (x: Type = Type # 😀 after\n    ; x)\n'),
 ('constructor-rejected','type Box is Data:\n  Mk{value: Type}\ndef main(box: Box) -> Type:\n  (Mk{x}: Box = box; x)\n')]
cases=[]
for name,text in rows:
 p=O/'fixtures'/f'ann-{name}.bend';p.write_text(text);cases.append({'name':'ann-'+name,'file':str(p),'base':False})
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
old=json.loads((R/'selfhost/build/phase21/group-range-structure-controls-01/plan.json').read_text())
plan={**old,'kind':'phase21-independent-ann-cursor-controls','cases':cases,'inputs':[identity(Path(__file__)),identity(R/'design/phase21/group-range-structure-ann.md'),identity(R/'selfhost/tools/performance/phase21/group-range-structure-run.mjs'),*[identity(Path(x['file']))for x in cases]]}
(O/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');print(O)
