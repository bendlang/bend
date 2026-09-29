"""Close V2 boundary evidence without altering the installed-prefix receipt."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4];build=root/'selfhost/build/phase19'
dirs=['instance-boundary-oracle-01','instance-boundary-candidate-01','instance-boundary-oracle-02','instance-boundary-candidate-02']
old=json.loads((build/dirs[1]/'result/report.json').read_text());new=json.loads((build/dirs[3]/'result/report.json').read_text());oracle=json.loads((build/dirs[2]/'result/report.json').read_text())
assert old['complete'] and not old['pass'] and len(old['rows'])==100
failed=[x['name'] for x in old['rows'] if not x['pass']];assert len(failed)==20 and all('/program/' in x for x in failed)
assert new['complete'] and new['pass'] and len(new['rows'])==104
assert oracle['complete'] and oracle['pass'] and all(oracle['projectionControls'].values())
files=[p for d in dirs for p in (build/d).rglob('*') if p.is_file()]
files+=[root/'implementation/phase19/instance-boundary-migration.md',Path(__file__)]
files+=[root/'selfhost/tools/performance/phase19'/n for n in ['instance-boundary-oracle-v2.mjs','instance-boundary-controls-v2.mjs','instance-boundary-run-v2.mjs']]
def identity(p):return {'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
report={'kind':'phase19-live-checker-boundary-receipt','complete':True,'pass':True,'installed':False,'api':new['api'],'publicRows':100,'projectionControls':4,'retainedOriginalFailure':{'rows':100,'failed':failed},'projectionScope':'Runtime call/data-head inventory only, not full checked-term equivalence. Ignore Ann type branches symmetrically; Ref/ADT equivalence only for known datatype names.','backendExecutionTested':False,'processesClosed':True,'boundFiles':[identity(p) for p in sorted(set(files))]}
out=root/'implementation/phase19/instance-boundary-migration.json';assert not out.exists();out.write_text(json.dumps(report,indent=2)+'\n')
for x in report['boundFiles']:assert identity(Path(x['file']))==x
print(json.dumps({'file':str(out),'sha256':identity(out)['sha256'],'boundFiles':len(report['boundFiles'])}))
