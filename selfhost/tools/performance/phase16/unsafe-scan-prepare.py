from pathlib import Path
import difflib,hashlib,json,shutil
root=Path(__file__).resolve().parents[4];base=root/'selfhost/build/phase16/spans-integration-source-04/project';out=root/'selfhost/build/phase16/unsafe-scan-source-01';out.mkdir();shutil.copytree(base,out/'project')
relative='src/check/kernel.bend';p=out/'project'/relative;s=p.read_text()
old='kc(U32, Bool.not(du(d)) && contains_self(Con{body, Nil{}}, dn(d)), u => U32.sub(da(d), dx(d)), u => 0)'
new='kc(U32, du(d), u => 0, u => kc(U32, contains_self(Con{body, Nil{}}, dn(d)), u => U32.sub(da(d), dx(d)), u => 0))'
assert s.count(old)==1;p.write_text(s.replace(old,new))
def identity(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'src_check_kernel.bend.patch';patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile=relative,tofile=relative)))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':identity(base/relative),'after':identity(p),'patch':identity(patch),'tool':identity(Path(__file__)),'plan':identity(root/'design/phase16/unsafe-recursion-scan.md'),'baselineControls':identity(root/'selfhost/build/phase16/unsafe-scan-baseline-02/report.json')},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'0','jobs':1},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py');print(out)
