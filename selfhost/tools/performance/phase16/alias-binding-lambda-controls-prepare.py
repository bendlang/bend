#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'selfhost/build/phase16/alias-binding-lambda-controls-01';OUT.mkdir();F=OUT/'fixtures';F.mkdir();shutil.copy2(ROOT/'selfhost/build/phase16/alias-binding-controls-01/fixtures/mod.bend',F/'mod.bend');rows=json.loads((ROOT/'selfhost/build/phase16/alias-binding-controls-01/selection.json').read_text())['cases'];head='import Base\nimport ./mod.bend as M\n';cases=[
('fresh-spaces',head+'def bad() -> Nat -> Nat:\n  M.double   =>   M.double\n',False),
('fresh-comment',head+'def bad() -> Nat -> Nat:\n  M.double => # body comment\n    M.double\n',False),
('fresh-newline',head+'def bad() -> Nat -> Nat:\n  M.double =>\n    M.double\n',False),
('fresh-eof',head+'def bad() -> Nat -> Nat:\n  M.double =>',False),
('fresh-body-error',head+'def bad() -> Nat -> Nat:\n  M.double => )\n',False),
('canonical-unbound','import Base\ndef bad() -> Nat -> Nat:\n  Foo.bar => Foo.bar\n',False),
('canonical-bound','import Base\ndef keep(Foo.bar:Nat) -> Nat -> Nat:\n  Foo.bar => Foo.bar\n',True),
('bound-comment',head+'def keep(M.double:Nat) -> Nat -> Nat:\n  M.double => # body comment\n    M.double\n',True),
('ordinary-body-error','import Base\ndef bad() -> Nat -> Nat:\n  x => )\n',False),
('reserved-body-error','import Base\ndef bad() -> Type -> Type:\n  Type => )\n',False),
('reserved-eof','import Base\ndef bad() -> Type -> Type:\n  Type =>',False),
]
for name,source,accept in cases:
 p=F/(name+'.bend');p.write_text(source);rows.append({'id':'alias-lambda/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept,**({}if accept else{'rejectPhase':'parse'})})
rows.append({'id':'parse/reserved_lambda_binder.bend','lanes':['parse','check']});(OUT/'selection.json').write_text(json.dumps({'cases':rows},indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'plan':'experiments/phase16/P16-alias-lambda-cursor.md','inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in sorted(F.iterdir())]},indent=2)+'\n');print(OUT)
