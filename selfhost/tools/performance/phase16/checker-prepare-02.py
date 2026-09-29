from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/checker-source-01';out=base/'build/phase16/checker-source-02';out.mkdir();shutil.copytree(old/'project',out/'project');project=out/'project'
p=project/'src/diagnostic/trace.bend';s=p.read_text();s=s.replace('u => nm(t) ++ " is a datatype:', 'u => "Note: " ++ nm(t) ++ " is a datatype:');s=s.replace('dg_text("+" ++ name ++ " can be used many times','dg_text("Note: +" ++ name ++ " can be used many times');p.write_text(s)
p=project/'src/check/kernel.bend';s=p.read_text();old='check(e, outer, cy(r), 0, typ(kindq(e, qt(h))))';assert s.count(old)==1;s=s.replace(old,'dg_kind_check(e, outer, cy(r), qt(h), nm(h))');p.write_text(s)
changes=[]
for name in ['src/check/kernel.bend','src/diagnostic/trace.bend']:
 before=(base/name).read_bytes();after=(project/name).read_bytes();changes.append({'file':name,'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)});(out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=name,tofile=name)))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-checker-diagnostic-candidate','changes':changes,'correction':'Preserve required Note: prefix; apply same existing-kind check wrapper to let binder as pinned term_check_kind does. Source01/build01/focused01 remain unchanged.','toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n');print(out)
