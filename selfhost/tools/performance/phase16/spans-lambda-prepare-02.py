#!/usr/bin/env python3
import pathlib,shutil,json,hashlib,difflib
r=pathlib.Path(__file__).resolve().parents[4];base=r/'selfhost/build/phase16/spans-lambda-source-01';parent=r/'selfhost/build/phase16/literal-context-source-04/project';out=r/'selfhost/build/phase16/spans-lambda-source-02';assert not out.exists();p=out/'project';shutil.copytree(base/'project',p)
f=p/'src/front/sugar.bend';s=f.read_text();a=s.index('def f_rewrite_motive(');b=s.index('def f_rewrite_body(',a);part=s[a:b];assert part.count('True{}')==2;s=s[:a]+part.replace('True{}','False{}')+s[b:];f.write_text(s)
m=json.loads((base/'manifest.json').read_text());m['project']=str(p);m['corrects']={'source':str(base),'issue':'Read-only inspection found both rewrite motive lambdas must omit q, matching pinned parse_rewrite; no source01 compiler build was run.'}
for row in m['producers']:
 if row['function']=='f_rewrite_motive':row['presence']='False{}'
for row in m['changes']:
 f=p/row['path'];old=parent/row['path'];patch=out/(row['path'].replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(old.read_text().splitlines(True),f.read_text().splitlines(True),fromfile='a/'+row['path'],tofile='b/'+row['path'])));row['sha256']=hashlib.sha256(f.read_bytes()).hexdigest();row['patch']=str(patch)
(out/'manifest.json').write_text(json.dumps(m,indent=2)+'\n');c=json.loads((base/'workflow.json').read_text());c['project']=str(p);(out/'workflow.json').write_text(json.dumps(c,indent=2)+'\n');print(out)
