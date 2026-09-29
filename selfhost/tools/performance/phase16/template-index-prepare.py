from pathlib import Path
import difflib,hashlib,json,shutil
root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
control=phase/'template-index-baseline-02/report.json';data=json.loads(control.read_text());assert data['complete'] and data['pass']
base=phase/'wave4-source-02/project';out=phase/'template-index-source-01';out.mkdir();shutil.copytree(base,out/'project')
p=out/'project/src/check/specialize.bend';s=p.read_text();old='bad(""), sp_template_book(book)}';new='bad(""), book_cached(sp_template_book(book), bound)}';assert s.count(old)==1;p.write_text(s.replace(old,new))
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'template-index.patch';patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile='src/check/specialize.bend',tofile='src/check/specialize.bend')))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':ident(base/'src/check/specialize.bend'),'after':ident(p),'patch':ident(patch),'tool':ident(Path(__file__)),'baseline':ident(control),'plan':ident(root/'design/phase16/template-membership-index.md')},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'3','jobs':1},indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
