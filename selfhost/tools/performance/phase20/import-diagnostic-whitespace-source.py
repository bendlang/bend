"""Fresh source04: preserve datatype semicolons with the existing whitespace worker."""
from pathlib import Path
import json,hashlib,shutil,difflib,re
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';BASE=P/'import-diagnostic-source-03/project';O=P/'import-diagnostic-source-04'
parent=P/'import-diagnostic-brace-parent-02/report.json';regression=P/'import-diagnostic-brace-regression-02/report.json';b=json.loads(parent.read_text());r=json.loads(regression.read_text());assert b['complete']and b['pass']and r['complete']and r['pass']and b['count']==r['count']==44
new_bad=[]
for x,y in zip(b['rows'],r['rows']):
 assert(x['name'],x['route'])==(y['name'],y['route'])and x['expected']==y['expected']
 if not x['candidateAccept']and y['candidateAccept']and not y['referenceAccept']:new_bad.append({'name':y['name'],'route':y['route']})
assert any(x['name']=='semicolon'for x in new_bad)and any(x['name']=='between-unindented'for x in new_bad)
O.mkdir();C=O/'project';shutil.copytree(BASE,C);p=C/'src/front/declarations.bend';old=p.read_text();new=old;changes=[]
for name,nextname,needle,replacement,count in [
 ('f_type_kind','f_type_ctors','f_skip(ts)','f_space(ts)',1),
 ('f_type_ctors','f_type_ctor_header','f_tops(ts,','f_top(ts,',1),
 ('f_type_ctor_header','f_type_ctor','f_skip(f_tl(ts))','f_space(f_tl(ts))',3),
 ('f_type_ctor','f_param_refs','f_skip(ts)','f_space(ts)',1),
]:
 a=new.index('@unsafe\ndef '+name+'(');z=new.index('@unsafe\ndef '+nextname+'(',a+1);part=new[a:z];assert part.count(needle)==count,(name,part.count(needle));new=new[:a]+part.replace(needle,replacement)+new[z:];changes.append({'function':name,'before':needle,'after':replacement,'occurrences':count})
p.write_text(new);prior=(R/'selfhost/build/phase19/instance-source-04/project/src/front/declarations.bend').read_text()
for name,left in [('declarations-parent03.patch',old),('declarations-phase19.patch',prior)]:
 (O/name).write_text(''.join(difflib.unified_diff(left.splitlines(True),new.splitlines(True),fromfile='parent/src/front/declarations.bend',tofile='source04/src/front/declarations.bend')))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(C);(O/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
delta=lambda before,after:{'physicalLines':len(after.splitlines())-len(before.splitlines()),'bytes':len(after.encode())-len(before.encode()),**{k:len(re.findall(r'^'+word+' ',after,re.M))-len(re.findall(r'^'+word+' ',before,re.M))for k,word in [('definitions','def'),('laws','law'),('types','type')]}}
inputs=[Path(__file__),R/'design/phase20/import-diagnostic-brace-boundary.md',R/'design/phase20/import-diagnostic-type-whitespace.md',P/'import-diagnostic-brace-controls-02/plan.json',parent,regression,BASE.parent/'manifest.json']
(O/'manifest.json').write_text(json.dumps({'kind':'phase20-datatype-whitespace-correction','complete':True,'frozen':True,'parent':str(BASE),'project':str(C),'changedFiles':['src/front/declarations.bend'],'corrections':changes,'newSource02FalseAcceptances':new_bad,'deltaParent03':delta(old,new),'deltaPhase19':delta(prior,new),'hostChanges':False,'inputs':[identity(p)for p in inputs],'members':{str(f.relative_to(C)):{'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size,'mode':f.stat().st_mode&0o777}for f in sorted(C.rglob('*'))if f.is_file()},'installed':False},indent=2)+'\n');print(O)
