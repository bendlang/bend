#!/usr/bin/env python3
import pathlib,shutil,json,hashlib,difflib
r=pathlib.Path(__file__).resolve().parents[4];base=r/'selfhost/build/phase16/spans-lambda-source-03';parent=base/'project';out=r/'selfhost/build/phase16/spans-lambda-source-04';assert not out.exists();p=out/'project';shutil.copytree(parent,p)
changes=[]
for rel,count in [('src/check/kernel.bend',2),('src/check/annotate.bend',1)]:
 f=p/rel;s=f.read_text();old='U32.is_eq(qt(t), 2) && U32.is_eq(qt(ty), 1)';assert s.count(old)==count;s=s.replace(old,'k_quantity_present(t) && '+old);f.write_text(s);before=parent/rel;patch=out/(rel.replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(before.read_text().splitlines(True),s.splitlines(True),fromfile='a/'+rel,tofile='b/'+rel)));changes.append({'path':rel,'parentSha256':hashlib.sha256(before.read_bytes()).hexdigest(),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'patch':str(patch),'lineDelta':0})
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(p),'changes':changes,'netLines':0,'reason':'Root-reviewed pinned optional-Many predicate; witness spans-lambda-demand-01'},indent=2)+'\n');c=json.loads((base/'workflow.json').read_text());c['project']=str(p);(out/'workflow.json').write_text(json.dumps(c,indent=2)+'\n');print(out)
