"""Freeze original22 plus eight name neighbors and ten ordered loading controls."""
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';O=P/'import-diagnostic-type-controls-01';O.mkdir();(O/'fixtures').mkdir()
raw=json.loads((P/'import-diagnostic-type-census-01/cases.json').read_text())
h='type T is Data:\n'
raw.extend({'name':n,'source':s}for n,s in [
 ('qualified-constructor',h+'  C.D{}\n'),('trailing-dot',h+'  C.{}\n'),
 ('digit-after-dot',h+'  C.1{}\n'),('spaced-dot',h+'  C .D{}\n'),
 ('newline-before-brace',h+'  C\n  {}\n'),('duplicate-before-brace',h+'  C{}\n  C()\n'),
 ('declaration-prefix-names',h+'definitely{}\ntypedef{}\nlawful{}\n'),
 ('underscore-name',h+'_C{}\n')])
assert len(raw)==30
(O/'raw-cases.json').write_text(json.dumps(raw,indent=2)+'\n')
dep='def value() -> Type:\n  Type\n';lead='import ./dep.bend as D\n'
rows=[
 ('type-late-missing',{'main.bend':h+'  C{}\nimport ./absent.bend as E\n'},['main.bend'],False),
 ('prior-valid',{'main.bend':lead+h+'  C{}\nimport ./absent.bend as E\n','dep.bend':dep},['main.bend','dep.bend'],False),
 ('prior-invalid',{'main.bend':lead+h+'  C{}\nimport ./absent.bend as E\n','dep.bend':'def broken( !!!\n'},['main.bend','dep.bend'],False),
 ('unindented-dependency',{'main.bend':lead+'def main() -> Type:\n  Type\n','dep.bend':h+'C{}\n'},['main.bend','dep.bend'],True),
 ('alias-constructor',{'main.bend':lead+h+'  D.C{}\n','dep.bend':dep},['main.bend','dep.bend'],False),
 ('alias-before-brace',{'main.bend':lead+h+'  D.C()\n','dep.bend':dep},['main.bend','dep.bend'],False),
 ('duplicate-constructor',{'main.bend':h+'  C{}\n  C{}\n'},['main.bend'],False),
 ('duplicate-before-brace',{'main.bend':h+'  C{}\n  C()\n'},['main.bend'],False),
 ('qualified-constructor',{'main.bend':h+'  C.D{}\n'},['main.bend'],True),
 ('reserved-before-import',{'main.bend':h+'  return{}\nimport ./absent.bend as E\n'},['main.bend'],False)]
cases=[]
for name,files,reads,accept in rows:
 d=O/'fixtures'/name;d.mkdir()
 for f,s in files.items():(d/f).write_text(s)
 cases.append({'name':name,'directory':str(d),'main':str(d/'main.bend'),'files':list(files),'expectedReads':reads,'referenceAccept':accept})
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
inputs=[Path(__file__),R/'design/phase20/import-diagnostic-type-correction.md',P/'import-diagnostic-type-census-01/report.json',O/'raw-cases.json',*[Path(c['directory'])/f for c in cases for f in c['files']]]
(O/'plan.json').write_text(json.dumps({'kind':'phase20-constructor-checkpoint-controls','frozen':True,'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'rawCases':str(O/'raw-cases.json'),'cases':cases,'inputs':[identity(p)for p in inputs]},indent=2)+'\n');print(O)
