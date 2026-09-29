"""Freeze independent first-element and separator controls for the original parser."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';O=P/'import-diagnostic-first-controls-01';O.mkdir();(O/'fixtures').mkdir()
head='def main(a: Type, b: Type, c: Type) -> Type:\n'
cases=[
 ('empty-head','  match:\n    case : Type\n',False),
 ('empty-pattern','  match a:\n    case : Type\n',False),
 ('leading-head-comma','  match ,a:\n    case x: Type\n',False),
 ('leading-pattern-comma','  match a:\n    case ,x: Type\n',False),
 ('single','  match a:\n    case x: Type\n',True),
 ('multiple-comma','  match a,b:\n    case x,y: Type\n',True),
 ('multiple-space','  match a b:\n    case x y: Type\n',True),
 ('multiple-mixed','  match a,b c:\n    case x y,z: Type\n',True),
 ('trailing-head-comma','  match a,:\n    case x: Type\n',False),
 ('trailing-pattern-comma','  match a:\n    case x,: Type\n',False),
 ('double-head-comma','  match a,,b:\n    case x,y: Type\n',False),
 ('double-pattern-comma','  match a,b:\n    case x,,y: Type\n',False),
 ('newline-empty-head','  match\n  :\n    case x: Type\n',False),
 ('newline-empty-pattern','  match a:\n    case\n    : Type\n',False),
 ('head-eof','  match',False),
 ('pattern-eof','  match a:\n    case',False),
 ('bound-head-zero-rows','  match a:\n',True),
 ('comment-first-head','  match # 😀\n    a:\n    case x: Type\n',True),
]
raw=[];loaded=[]
for name,body,accept in cases:
 source=head+body;d=O/'fixtures'/name;d.mkdir();f=d/'main.bend';f.write_text(source)
 raw.append({'name':name,'source':source,'expectedReferenceAccept':accept})
 loaded.append({'name':name,'directory':str(d),'main':str(f),'files':['main.bend'],'expectedReads':['main.bend'],'referenceAccept':accept})
(O/'raw-cases.json').write_text(json.dumps(raw,indent=2)+'\n')
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
files=[Path(__file__),R/'design/phase20/import-diagnostic-first-elements.md',R/'design/phase20/declaration-checkpoints-integration.md',O/'raw-cases.json',*[Path(x['main'])for x in loaded]]
(O/'plan.json').write_text(json.dumps({'kind':'phase20-first-element-controls','frozen':True,'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'rawCases':str(O/'raw-cases.json'),'cases':loaded,'inputs':[identity(p)for p in files]},indent=2)+'\n');print(O)
