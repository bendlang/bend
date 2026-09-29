import pathlib,json,hashlib
root=pathlib.Path.cwd();out=root/'selfhost/build/phase15/behavior-cycles-01';out.mkdir();fixtures=out/'fixtures';fixtures.mkdir()
files={}
for name,parent,child in [('cycle-valid',False,False),('cycle-parent-error',True,False),('cycle-child-error',False,True),('cycle-both-errors',True,True)]:
 files[name+'/a.bend']='import Base\nimport ./b.bend as B\n'+('parent_bad_token\n' if parent else 'def main() -> Nat:\n  0n\n')
 files[name+'/b.bend']='import ./a.bend as A\n'+('child_bad_token\n' if child else 'def value() -> Nat:\n  1n\n')
files['alias-same-physical/main.bend']='import Base\nimport ./leaf.bend as L\nimport ./sub/link.bend as R\ndef main() -> Nat:\n  Nat.add(L.value(), R.value())\n'
files['alias-same-physical/leaf.bend']='def value() -> Nat:\n  1n\n'
for name,text in files.items():p=fixtures/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)
link=fixtures/'alias-same-physical/sub/link.bend';link.parent.mkdir();link.symlink_to('../leaf.bend')
# The symlink is relative to sub, so its target is the sibling module.
selection=[{'id':'p15-cycle/'+name,'file':str(fixtures/(name+'/a.bend')),'lanes':['parse','check'],'accept':False,'rejectPhase':'parse'} for name in ['cycle-valid','cycle-parent-error','cycle-child-error','cycle-both-errors']]
selection.append({'id':'p15-cycle/alias-same-physical','file':str(fixtures/'alias-same-physical/main.bend'),'lanes':['parse','check'],'accept':True})
(out/'selection.json').write_text(json.dumps(selection,indent=2)+'\n');(out/'plan.json').write_text(json.dumps({'kind':'phase15-cycle-order-boundary-plan','frozenBeforeRuns':True,'purpose':'Compare retained Phase14, isolated Phase15 plus export guard, and pinned TS before changing cycle semantics. Cycle diagnostics may retain inherited differences; no new semantics accepted from exit code alone.','files':[{'file':str(fixtures/name),'sha256':hashlib.sha256(text.encode()).hexdigest()} for name,text in files.items()],'symlink':{'file':str(link),'target':'../leaf.bend'},'cases':selection},indent=2)+'\n');print(out)
