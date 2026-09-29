import pathlib,json,hashlib
root=pathlib.Path.cwd();out=root/'selfhost/build/phase15/behavior-controls-02';out.mkdir();fixtures=out/'fixtures';fixtures.mkdir()
files={
 'plain.bend':'def value() -> Nat:\n  3n\n',
 'has-hyphen/lib.bend':'def value() -> Nat:\n  4n\n',
 'bad-body.bend':'def broken() -> Nat:\n  -5\n',
 'missing-first.bend':'import Base\nimport ./absent.bend as A\nimport ./bad-body.bend as B\ndef main() -> Nat:\n  -5\n',
 'bad-body-first.bend':'import Base\nimport ./bad-body.bend as B\nimport ./absent.bend as A\ndef main() -> Nat:\n  -6\n',
 'missing-before-alias.bend':'import Base\nimport ./absent.bend as A\nimport ./plain.bend as A\ndef main() -> Nat:\n  0n\n',
 'duplicate-before-missing.bend':'import Base\nimport ./plain.bend as A\nimport ./absent.bend as A\ndef main() -> Nat:\n  0n\n',
 'missing-parent-body.bend':'import Base\nimport ./absent.bend as A\ndef main() -> Nat:\n  -5\n',
 'invalid-before-missing.bend':'import Base\nimport ./bad.name.bend as A\nimport ./absent.bend as B\ndef main() -> Nat:\n  0n\n',
 'missing-before-invalid.bend':'import Base\nimport ./absent.bend as A\nimport ./bad.name.bend as B\ndef main() -> Nat:\n  0n\n',
 'hyphen.bend':'import Base\nimport ./has-hyphen/lib.bend as L\ndef main() -> Nat:\n  L.value()\n',
 'sub/parent.bend':'import Base\nimport ../plain.bend as L\ndef main() -> Nat:\n  L.value()\n',
 'double-slash.bend':'import Base\nimport .//plain.bend as L\ndef main() -> Nat:\n  L.value()\n',
 'parent-double-slash.bend':'import Base\nimport ..//plain.bend as L\ndef main() -> Nat:\n  L.value()\n',
 'dotted-parent.bend':'import Base\nimport ./x/../plain.bend as L\ndef main() -> Nat:\n  L.value()\n',
 'local-package.bend':'import Base\nimport ./thing@1.0.0.0/file.bend as L\ndef main() -> Nat:\n  0n\n',
 'digit.bend':'import Base\ndef main() -> Nat:\n  -5 = 3n\n  0n\n',
 'keyword.bend':'import Base\ndef main() -> Nat:\n  -return = 3n\n  0n\n',
 'valid-binder.bend':'import Base\ndef main() -> Nat:\n  -x: Nat = 3n\n  0n\n',
 'valid-underscore.bend':'import Base\ndef main() -> Nat:\n  -_: Nat = 3n\n  0n\n',
 'unicode-prefix-missing.bend':'# 🙂\nimport Base\n\timport ./absent.bend as A\ndef main() -> Nat:\n  0n\n',
 'nested-missing.bend':'import Base\nimport ./nested/dependency.bend as A\ndef main() -> Nat:\n  0n\n',
 'nested/dependency.bend':'# nested 🙂\nimport ../absent.bend as A\ndef value() -> Nat:\n  0n\n',
}
for name,txt in files.items():p=fixtures/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(txt)
ids=['import/cross_file_io.bend','import/cross_file_proof.bend','import/cycle_terminates.bend','import/diamond_dedup.bend','import/dotted_path.bend','import/hub_head_local.bend','import/hub_head_path.bend','import/path_canonical.bend','import/tilde_path.bend','parse/prefix_operator_dead.bend']
selection=[{'id':id,'lanes':['parse','check'],'accept':False,'rejectPhase':'parse'} for id in ids]
skip={'plain.bend','has-hyphen/lib.bend','bad-body.bend','nested/dependency.bend'};positive={'double-slash.bend','hyphen.bend','sub/parent.bend','valid-binder.bend','valid-underscore.bend'}
for name in files:
 if name not in skip:selection.append({'id':'p15-behavior/'+name,'file':str(fixtures/name),'lanes':['parse','check'],'accept':name in positive,**({} if name in positive else {'rejectPhase':'parse'})})
(out/'selection.json').write_text(json.dumps(selection,indent=2)+'\n')
(out/'plan.json').write_text(json.dumps({'kind':'phase15-behavior-control-plan','frozenBeforeCandidate':True,'cases':selection,'notes':['Scope compares exact full result separately from declared rejection-phase/acceptance oracle.','Non-ENOENT IO and missing entry controls use host-only fake API checks and remain load failures.','Illegal local path diagnostics may retain first-character versus whole-path observed mismatch.','Remote hub/package resolution remains unsupported and is not exercised over a network.'],'inputs':[{'file':str(fixtures/name),'sha256':hashlib.sha256(txt.encode()).hexdigest()} for name,txt in files.items()]},indent=2)+'\n')
print(out)
