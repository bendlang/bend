import pathlib,json,hashlib,shutil
root=pathlib.Path.cwd();old=root/'selfhost/build/phase15/behavior-cycles-01';out=root/'selfhost/build/phase15/behavior-cycles-02';out.mkdir();fixtures=out/'fixtures';shutil.copytree(old/'fixtures',fixtures,symlinks=True)
files={
 'cycle-canonical/a.bend':'import Base\nimport ./sub/link.bend as L\ndef main() -> Nat:\n  0n\n',
 'diamond/main.bend':'import Base\nimport ./left.bend as L\nimport ./right.bend as R\ndef main() -> Nat:\n  Nat.add(L.value(), R.value())\n',
 'diamond/left.bend':'import ./leaf.bend as F\ndef value() -> Nat:\n  F.value()\n',
 'diamond/right.bend':'import ./sub/link.bend as F\ndef value() -> Nat:\n  F.value()\n',
 'diamond/leaf.bend':'def value() -> Nat:\n  1n\n',
 'cycle-before-missing/a.bend':'import Base\nimport ./b.bend as B\nimport ./absent.bend as X\ndef main() -> Nat:\n  0n\n',
 'cycle-before-missing/b.bend':'import ./a.bend as A\nimport ./other-absent.bend as X\ndef value() -> Nat:\n  0n\n',
}
for name,text in files.items():p=fixtures/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
for name,target in [('cycle-canonical/sub/link.bend','../a.bend'),('diamond/sub/link.bend','../leaf.bend')]:p=fixtures/name;p.parent.mkdir(parents=True);p.symlink_to(target)
selection=json.loads((old/'selection.json').read_text())
for x in selection:x['file']=x['file'].replace(str(old),str(out))
for name,file,accept in [('cycle-canonical','a.bend',False),('diamond','main.bend',True),('cycle-before-missing','a.bend',False)]:selection.append({'id':'p15-cycle/'+name,'file':str(fixtures/name/file),'lanes':['parse','check'],'accept':accept,**({} if accept else {'rejectPhase':'parse'})})
(out/'selection.json').write_text(json.dumps(selection,indent=2)+'\n');(out/'plan.json').write_text(json.dumps({'kind':'phase15-cycle-order-expanded-boundaries','frozenBeforeRuns':True,'sourcePlan':str(root/'experiments/phase15/P15-005-import-cycle-order.md'),'scope':'All8 fixtures16observations must exactly match pinned TS, including canonical reentry and the first cycle before later missing files.','files':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'symlink':str(p.readlink()) if p.is_symlink() else None} for p in fixtures.rglob('*.bend')],'cases':selection},indent=2)+'\n');print(out)
