from pathlib import Path
import difflib,hashlib,json,shutil
root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
base=phase/'unbound-marker-source-01/project';out=phase/'unbound-marker-source-02';out.mkdir();shutil.copytree(base,out/'project')
p=out/'project/src/diagnostic/trace.bend';s=p.read_text()
old='dg_text(nm(t) ++ "^-1")'
new='dg_text(nm(t) ++ kc(String, kp_bound(dg_scope(ctx, Nil{}), nm(t)), u => "^-1", u => ""))'
assert s.count(old)==1;p.write_text(s.replace(old,new))
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'context-display.patch';patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile='src/diagnostic/trace.bend',tofile='src/diagnostic/trace.bend')))
selection=json.loads((phase/'unbound-marker-source-01/selection.json').read_text());fixture=out/'marked-datatype.bend';shutil.copy2(phase/'bare-family-fixtures-01/quantity-marked.bend',fixture)
for c in selection['cases']:
 if c['id']=='unbound-marker/marked-datatype':c['file']=str(fixture)
(out/'selection.json').write_text(json.dumps(selection,indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':ident(base/'src/diagnostic/trace.bend'),'after':ident(p),'patch':ident(patch),'fixture':ident(fixture),'tool':ident(Path(__file__)),'scope':'Reuse existing displayed-context membership for the invalid-variable suffix; corrected valid quantified-datatype boundary. Original candidate and malformed positive retained.'},indent=2)+'\n')
config=json.loads((phase/'unbound-marker-source-01/workflow.json').read_text());config['project']=str(out/'project');(out/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
