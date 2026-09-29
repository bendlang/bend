from pathlib import Path
import hashlib,json,shutil,difflib
root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
base=phase/'checker-trace-source-08/project';out=phase/'checker-trace-source-09'
out.mkdir();shutil.copytree(base,out/'project');p=out/'project/src/diagnostic/trace.bend';s=p.read_text()
old='site, kid(ct(r), 4), kc(KTerm, U32.is_eq(q, 2)'
new='site, kt("DTrail", "", 0, 0, Con{site, ks(kid(ct(r), 4))}), kc(KTerm, U32.is_eq(q, 2)'
assert s.count(old)==1;p.write_text(s.replace(old,new))
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
patch=out/'trace.patch';patch.write_text(''.join(difflib.unified_diff(s.splitlines(True),p.read_text().splitlines(True),fromfile='src/diagnostic/trace.bend',tofile='src/diagnostic/trace.bend')))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'before':ident(base/'src/diagnostic/trace.bend'),'after':ident(p),'patch':ident(patch),'tool':ident(Path(__file__)),'correction':'DDiagnostic uses its retained trail for location. The immediate kind-site override must lead that trail; keep the original trail as fallback for unlocated callers.'},indent=2)+'\n')
config=json.loads((phase/'checker-trace-source-08/workflow.json').read_text());config['project']=str(out/'project');(out/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
