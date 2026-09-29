from pathlib import Path
import difflib, hashlib, json, shutil
root=Path(__file__).resolve().parents[4]
base=root/'selfhost/build/phase16/canonical-source-02/project'
out=root/'selfhost/build/phase16/bare-family-source-01'
out.mkdir();shutil.copytree(base,out/'project')
relative='src/front/families.bend';p=out/'project'/relative
old='f_eq(dk(f_find(nm(t), book)), "ADT"), u => f_adt(t, Nil{}, f_find(nm(t), book))'
new='f_eq(dk(f_find(nm(t), book)), "ADT") && U32.is_eq(da(f_find(nm(t), book)), 0), u => f_adt(t, Nil{}, f_find(nm(t), book))'
s=p.read_text();assert s.count(old)==1;p.write_text(s.replace(old,new))
def identity(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'src_front_families.bend.patch';patch.write_text(''.join(difflib.unified_diff((base/relative).read_text().splitlines(True),p.read_text().splitlines(True),fromfile=relative,tofile=relative)))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':identity(base/relative),'after':identity(p),'patch':identity(patch),'tool':identity(Path(__file__)),'plan':identity(root/'design/phase16/bare-family.md')},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'0','jobs':1},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py');print(out)
