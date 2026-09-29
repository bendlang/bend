"""Seal the first shared prototype before genuine checking; no production promotion."""
from pathlib import Path
import hashlib,json,difflib,re
ROOT=Path(__file__).resolve().parents[4];OUT=ROOT/'selfhost/build/phase19/instance-source-01';P=OUT/'project';OLD=ROOT/'selfhost/build/phase18/instance-world-source-06/project'
def members(root):return {str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mode':p.stat().st_mode&0o777}for p in sorted(root.rglob('*'))if p.is_file()}
def count(root):
 names=json.loads((root/'src/compiler.json').read_text())['modules'];ss=[(root/n).read_text()for n in names];s=''.join(ss)
 return {'modules':len(names),'physicalLines':sum(len(t.splitlines())for t in ss),'nonblankLines':sum(bool(l.strip())for t in ss for l in t.splitlines()),'bytes':sum((root/n).stat().st_size for n in names),'definitions':len(re.findall(r'^def ',s,re.M)),'laws':len(re.findall(r'^law ',s,re.M)),'types':len(re.findall(r'^type ',s,re.M))}
a,b=members(OLD),members(P);assert a.keys()==b.keys();changed=[n for n in a if a[n]!=b[n]]
patch=''.join(''.join(difflib.unified_diff((OLD/n).read_text().splitlines(True),(P/n).read_text().splitlines(True),fromfile='parent/'+n,tofile='candidate/'+n))for n in changed)
(OUT/'source.patch').write_text(patch);ca,cb=count(OLD),count(P)
inputs=[Path(__file__),ROOT/'design/phase19/live-instance-checking.md',ROOT/'design/phase19/instance-interfaces.md',ROOT/'design/phase19/instance-output-order.md',OUT/'parent-manifest.json']
r={'kind':'phase19-shared-live-instance-source','complete':True,'frozen':True,'parent':str(OLD),'project':str(P),'parentMembers':a,'candidateMembers':b,'changedFiles':changed,'before':ca,'after':cb,'delta':{k:cb[k]-ca[k]for k in ca},'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}for p in inputs],'installed':False,'semanticInstantiation':True,'status':'First coherent prototype. No checking, correctness, performance or simplification conclusion yet.'}
(OUT/'manifest.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps({'complete':True,'changed':changed,'delta':r['delta']}))
