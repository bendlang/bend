"""Freeze decorator checkpoint and ordered IO controls before running or editing a compiler."""
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'selfhost/build/phase20/import-diagnostic-controls-01';OUT.mkdir();(OUT/'fixtures').mkdir()
rows=[
('unsafe-import',{'main.bend':'@unsafe\nimport ./dep.bend as D\n','dep.bend':''},['main.bend']),
('unsafe-missing-import',{'main.bend':'@unsafe\nimport ./absent.bend as D\n'},['main.bend']),
('unsafe-bad-dependency',{'main.bend':'@unsafe\nimport ./dep.bend as D\n','dep.bend':'def bad( !!!\n'},['main.bend']),
('unsafe-law',{'main.bend':'@unsafe\nlaw value:\n  Type\n'},['main.bend']),
('unsafe-type',{'main.bend':'@unsafe\ntype T is Data:\n  Unit{}\n'},['main.bend']),
('unsafe-eof',{'main.bend':'@unsafe'},['main.bend']),
('unsafe-eof-newline',{'main.bend':'@unsafe\n'},['main.bend']),
('unsafe-repeated',{'main.bend':'@unsafe\n@unsafe\ndef f() -> Type:\n  Type\n'},['main.bend']),
('unsafe-comments',{'main.bend':'@unsafe # 😀\n# comment\n\nimport ./dep.bend as D\n','dep.bend':''},['main.bend']),
('unsafe-valid-def',{'main.bend':'@unsafe\ndef f() -> Type:\n  Type\n'},['main.bend']),
('prior-valid-import',{'main.bend':'import ./dep.bend as D\n@unsafe\nimport ./later.bend as E\n','dep.bend':'def value() -> Type:\n  Type\n','later.bend':'def bad( !!!\n'},['main.bend','dep.bend']),
('prior-invalid-dependency',{'main.bend':'import ./dep.bend as D\n@unsafe\nimport ./later.bend as E\n','dep.bend':'def bad( !!!\n','later.bend':''},['main.bend','dep.bend'])]
cases=[]
for name,files,reads in rows:
 d=OUT/'fixtures'/name;d.mkdir()
 for f,text in files.items():(d/f).write_text(text)
 cases.append({'name':name,'directory':str(d),'files':list(files),'main':str(d/'main.bend'),'expectedReads':reads,'accept':name=='unsafe-valid-def','expectedDiagnosticChange':name not in ['unsafe-valid-def','prior-invalid-dependency']})
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
plan={'kind':'phase20-decorator-checkpoint-controls','frozen':True,'cases':cases,'baselineAttempt':str(ROOT/'selfhost/build/phase19/instance-build-03'),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'inputs':[identity(Path(__file__)),identity(ROOT/'design/phase20/import-diagnostic-checkpoint.md'),*[identity(Path(c['directory'])/f)for c in cases for f in c['files']]]}
(OUT/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');print(OUT)
