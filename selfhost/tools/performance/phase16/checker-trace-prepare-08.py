from pathlib import Path
import hashlib,json,shutil,difflib
root=Path(__file__).resolve().parents[4]
phase=root/'selfhost/build/phase16';base=phase/'checker-trace-source-07/project';out=phase/'checker-trace-source-08'
out.mkdir();shutil.copytree(base,out/'project')
p=out/'project/src/check/kernel.bend';s=p.read_text()
old='law check_let_done:\n  for +r: KChecked'
new='law check_let_done:\n  for +e: KEnv\n  for +ctx: List<&2,KTerm>\n  for +r: KChecked'
assert s.count(old)==1;p.write_text(s.replace(old,new))
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'law.patch';patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile='src/check/kernel.bend',tofile='src/check/kernel.bend')))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':ident(base/'src/check/kernel.bend'),'after':ident(p),'patch':ident(patch),'tool':ident(Path(__file__)),'correction':'Source07 updated the definition but omitted its existing forward law; checked compilation correctly refused it. Update that law only.'},indent=2)+'\n')
config=json.loads((phase/'checker-trace-source-07/workflow.json').read_text());config['project']=str(out/'project');(out/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
