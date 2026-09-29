"""Extend immutable brace witnesses with the two datatype-loop cursor boundaries."""
from pathlib import Path
import json,hashlib,shutil
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';OLD=P/'import-diagnostic-brace-controls-01';O=P/'import-diagnostic-brace-controls-02';O.mkdir();shutil.copytree(OLD/'fixtures',O/'fixtures')
old=json.loads((OLD/'plan.json').read_text());raw=json.loads((OLD/'raw-cases.json').read_text());cases=[]
for c in old['cases']:
 d=O/'fixtures'/c['name'];cases.append({**c,'directory':str(d),'main':str(d/'main.bend')})
h='type T is Data:\n'
for name,source,accept in [
 ('before-first-unindented',h+';\nC{}\n',False),
 ('between-unindented',h+'  C{};\nD{}\n',False),
 ('before-first-indented',h+';\n  C{}\n',False),
 ('between-indented',h+'  C{};\n  D{}\n',False),
 ('before-next-def',h+'  C{};\ndef main() -> Type: Type\n',False),
 ('comment-between',h+'  C{} # comment\n\n  D{}\n',True),
]:
 d=O/'fixtures'/name;d.mkdir();(d/'main.bend').write_text(source)
 raw.append({'name':name,'source':source,'expectedReferenceAccept':accept});cases.append({'name':name,'directory':str(d),'main':str(d/'main.bend'),'files':['main.bend'],'expectedReads':['main.bend'],'referenceAccept':accept})
assert len(raw)==14 and len(cases)==15
(O/'raw-cases.json').write_text(json.dumps(raw,indent=2)+'\n')
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
files=[Path(__file__),R/'design/phase20/import-diagnostic-type-whitespace.md',OLD/'plan.json',O/'raw-cases.json',*[Path(c['directory'])/f for c in cases for f in c['files']]]
(O/'plan.json').write_text(json.dumps({'kind':'phase20-constructor-whitespace-boundaries','frozen':True,'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'rawCases':str(O/'raw-cases.json'),'cases':cases,'inputs':[identity(p)for p in files]},indent=2)+'\n');print(O)
