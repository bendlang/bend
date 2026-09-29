"""Retain failed checked attempt01; add the required local constructor annotation."""
from pathlib import Path
import difflib,hashlib,json,re,shutil
ROOT=Path(__file__).resolve().parents[4]
OLD=ROOT/'selfhost/build/phase18/instance-world-source-01'
OUT=ROOT/'selfhost/build/phase18/instance-world-source-02'
prior=json.loads((OLD/'manifest.json').read_text());BASE=Path(prior['parent'])
OUT.mkdir();project=OUT/'project';shutil.copytree(OLD/'project',project)
p=project/'src/check/kernel.bend';s=p.read_text();old='  +e = KEnv{world, dn(d), ref(dn(d)), 0, Nil{}, du(d), depth}'
assert s.count(old)==1;p.write_text(s.replace(old,old.replace('+e =','+e: KEnv =')))
def members(root):return {str(p.relative_to(root)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size,'mode':p.stat().st_mode&0o777} for p in sorted(root.rglob('*')) if p.is_file()}
after=members(project);changes=[n for n in prior['before'] if prior['before'][n]!=after[n]]
patch=''.join(''.join(difflib.unified_diff((BASE/n).read_text().splitlines(True),(project/n).read_text().splitlines(True),fromfile='a/'+n,tofile='b/'+n)) for n in changes)
(OUT/'source.patch').write_text(patch)
new=dict(prior['newSource']);new['bytes']+=6
manifest={**prior,'project':str(project),'after':after,'newSource':new,'delta':{k:new[k]-prior['oldSource'][k] for k in new},'correction':'Annotate local KEnv constructor binding; failed B1 attempt01 retained.','previousSource':str(OLD),'inputs':prior['inputs']+[{'file':str(Path(__file__)),'sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}]}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
config=json.loads((OLD/'workflow.json').read_text());config['project']=str(project);(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
print(json.dumps(manifest['delta']))
