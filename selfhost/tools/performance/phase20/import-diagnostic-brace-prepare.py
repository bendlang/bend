"""Freeze reviewer counterexamples and prior-error neighbors before source04."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';O=P/'import-diagnostic-brace-controls-01';O.mkdir();(O/'fixtures').mkdir()
h='type T is Data:\n';raw=[];cases=[]
rows=[
 ('semicolon',h+'  C;{}\n',False),('double-semicolon',h+'  C;;{}\n',False),
 ('newline-semicolon',h+'  C\n  ;\n  {}\n',False),
 ('spaces',h+'  C   {}\n',True),('comment-newline',h+'  C # comment 😀\n  {}\n',True),
 ('duplicate-semicolon',h+'  C{}\n  C;{}\n',False),
 ('invalid-name-semicolon',h+'  C..D;{}\n',False),
 ('reserved-name-semicolon',h+'  return;{}\n',False),
]
for name,source,accept in rows:
 d=O/'fixtures'/name;d.mkdir();(d/'main.bend').write_text(source)
 raw.append({'name':name,'source':source,'expectedReferenceAccept':accept});cases.append({'name':name,'directory':str(d),'main':str(d/'main.bend'),'files':['main.bend'],'expectedReads':['main.bend'],'referenceAccept':accept})
d=O/'fixtures/alias-semicolon';d.mkdir();(d/'main.bend').write_text('import ./dep.bend as D\n'+h+'  D.C;{}\n');(d/'dep.bend').write_text('def value() -> Type: Type\n');cases.append({'name':'alias-semicolon','directory':str(d),'main':str(d/'main.bend'),'files':['main.bend','dep.bend'],'expectedReads':['main.bend','dep.bend'],'referenceAccept':False})
(O/'raw-cases.json').write_text(json.dumps(raw,indent=2)+'\n')
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
inputs=[Path(__file__),R/'design/phase20/import-diagnostic-brace-boundary.md',O/'raw-cases.json',*[Path(c['directory'])/f for c in cases for f in c['files']]]
(O/'plan.json').write_text(json.dumps({'kind':'phase20-constructor-brace-boundaries','frozen':True,'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'rawCases':str(O/'raw-cases.json'),'cases':cases,'inputs':[identity(p)for p in inputs]},indent=2)+'\n');print(O)
