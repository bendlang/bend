from pathlib import Path
import json,hashlib
root=Path.cwd();out=root/'selfhost/build/phase16/checker-base-prefix-controls-01';out.mkdir();f=out/'fixtures';f.mkdir()
texts={
'normal.bend':'import Base\ndef value() -> Nat:\n  0n\n',
'dep.bend':'import Base\ndef value() -> Nat:\n  0n\n',
'alias.bend':'import ./dep.bend as D\ndef value() -> Nat:\n  D.value()\n',
'repeated-alias.bend':'import ./dep.bend as D\nimport ./dep.bend as E\ndef value() -> Nat:\n  Nat.add(D.value(), E.value())\n',
'bare.bend':'def item() -> Type:\n  Type\n',
'base-first.bend':'import Base\nimport ./bare.bend as B\ndef value() -> Nat:\n  0n\n',
'base-later.bend':'import ./bare.bend as B\nimport Base\ndef value() -> Nat:\n  0n\n',
'duplicate.bend':'import Base\ndef value() -> Nat:\n  0n\ndef value() -> Nat:\n  1n\n',
'laws.bend':'import Base\nlaw value:\n  Nat\n',
'fill.bend':'import ./laws.bend as L\ndef L.value():\n  0n\n',
'bad-fill.bend':'import ./laws.bend as L\ndef L.missing():\n  0n\n',
'malformed.bend':'import Base\ndef missing(\n',
}
for n,t in texts.items():(f/n).write_text(t)
rows=[{'name':n[:-5],'file':str(f/n),'expected':'error' if n in ['duplicate.bend','bad-fill.bend','malformed.bend'] else 'ok','eligible':n not in ['base-later.bend','bare.bend','malformed.bend']} for n in ['normal.bend','alias.bend','repeated-alias.bend','base-first.bend','base-later.bend','bare.bend','duplicate.bend','fill.bend','bad-fill.bend','malformed.bend']]
(out/'controls.json').write_text(json.dumps(rows,indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'kind':'exact-base-prefix-finite-graphs','plan':str(root/'design/phase16/checker-base-prefix-proof.md'),'files':[{'file':str(f/n),'sha256':hashlib.sha256((f/n).read_bytes()).hexdigest()} for n in texts]},indent=2)+'\n');print(out)
