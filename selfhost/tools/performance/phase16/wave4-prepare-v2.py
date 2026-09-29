"""Restore the independently validated family guard lost in an owner overlay."""
from pathlib import Path
import difflib,hashlib,json,shutil
root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
base=phase/'wave4-source-01/project';out=phase/'wave4-source-02';out.mkdir();shutil.copytree(base,out/'project')
p=out/'project/src/front/families.bend';s=p.read_text()
old='f_eq(dk(f_find(nm(t), book)), "ADT"), u => f_adt(t, Nil{}, f_find(nm(t), book))'
new='f_eq(dk(f_find(nm(t), book)), "ADT") && U32.is_eq(da(f_find(nm(t), book)), 0), u => f_adt(t, Nil{}, f_find(nm(t), book))'
assert s.count(old)==1;p.write_text(s.replace(old,new))
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'family-guard.patch';patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile='src/front/families.bend',tofile='src/front/families.bend')))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':ident(base/'src/front/families.bend'),'after':ident(p),'patch':ident(patch),'tool':ident(Path(__file__)),'failure':'The semantic05 owner patch was formed against integration04 but also removed its independent arity-zero guard. Baseline-only full gate missed the loss of a new Phase16 exact match. Restore the existing one-predicate semantic correction; strengthen the integration gate separately.'},indent=2)+'\n')
config=json.loads((phase/'wave4-source-01/workflow.json').read_text());config['project']=str(out/'project');(out/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
