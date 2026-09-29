"""Freeze identical-host, identical-workload matrix inputs after cheap gates."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[4]
out=root/'selfhost/build/phase22/index-remove-matrix-inputs-01'
parent=root/'selfhost/build/phase21/group-range-build-02'
candidate=root/'selfhost/build/phase22/index-remove-build-01'
a=json.loads((parent/'attempt.json').read_text());b=json.loads((candidate/'attempt.json').read_text())
assert a['api']['sha256']=='44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0'
assert b['api']['sha256']=='c6d94a6795e98695e9e45893c34332181ff50039cbb09121fbf789ca515a2f12'
def identity(p):
 p=p.resolve();return {'file':str(p),'canonicalPath':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def hosts(m):return {str(Path(x['frozen']['file']).relative_to(m['snapshot']['root'])):x['frozen'] for x in m['snapshot']['sources'] if str(Path(x['frozen']['file']).relative_to(m['snapshot']['root'])).startswith('tools/')}
ah,bh=hosts(a),hosts(b);assert set(ah)==set(bh);assert len(ah)==35
rows=[]
for name in sorted(ah):
 x,y=ah[name],bh[name];assert x['sha256']==y['sha256'];assert identity(Path(x['file']))['sha256']==x['sha256'];assert identity(Path(y['file']))['sha256']==y['sha256'];rows.append({'relative':name,'before':x,'after':y})
controls=root/'selfhost/build/phase22/index-remove-controls-01/report.json'
full=root/'selfhost/build/phase22/index-remove-fullcheck-01/report.json'
assert json.loads(controls.read_text())['pass'];assert json.loads(full.read_text())['exactObservation']
out.mkdir()
review=out/'host-review.json';review.write_text(json.dumps({'kind':'phase22-complete-host-membership-review','pass':True,'members':35,'changes':[],'rows':rows},indent=2)+'\n')
source=Path(json.loads((root/'selfhost/build/phase22/installed-profile-01/request.json').read_text())['source'])
(out/'matrix.json').write_text(json.dumps({'baseline':str(parent),'candidate':str(candidate),'source':str(source),'cpu':'0','mode':'measure','hostReview':str(review)},indent=2)+'\n')
inputs=[Path(__file__),controls,full,parent/'attempt.json',candidate/'attempt.json',source,review,out/'matrix.json',root/'design/phase22/index-remove-worker.md',root/'selfhost/tools/performance/phase16/check-matrix-v2.mjs',root/'selfhost/tools/performance/phase8/check-worker.mjs']
(out/'freeze.json').write_text(json.dumps({'complete':True,'inputs':[identity(p) for p in inputs],'resources':{'cpu':'0','stackKiB':4096,'heapMiB':4096},'order':['typescript','baseline','candidate','candidate','baseline','typescript'],'scope':'Exclusive cost screen only after root and both other agents acknowledge idle; fresh process each row, validated per-image cache, same parent compiler source, no emission. Two samples per image, no broad throughput claim.'},indent=2)+'\n')
print(out)
