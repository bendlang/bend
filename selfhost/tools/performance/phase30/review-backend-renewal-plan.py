#!/usr/bin/env python3
"""Freeze existing pilot and JS-only broad selections; execute no fixtures."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];SH=ROOT/'selfhost'
attempt,out=(Path(x).resolve() for x in sys.argv[1:]);out.mkdir(exist_ok=False)
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
m=json.loads((attempt/'attempt.json').read_text());assert m['checked']
bootstrap=json.loads(Path(m['bootstrapReport']['file']).read_text());assert bootstrap['revision']=='018751270e800bc222a93dad7f257083ee53a5f7'
assert Path(m['config']['upstream']).resolve()==(SH/'.bootstrap/upstream-phase23').resolve()
historical=SH/'build/phase24/backend-plan-01/plan.json';p=json.loads(historical.read_text());assert p['pin']==bootstrap['revision']
priorReport=SH/'build/phase24/backend-candidate-pilot-07/report.json';prior=json.loads(priorReport.read_text())
assert any(Path(x['file']).resolve()==historical and x['sha256']==ident(historical)['sha256'] for x in prior['inputs'])
assert ident(p['inventory']['file'])['sha256']==p['inventory']['sha256']
helper=HERE.parent/'phase24/backend-census.py';priorHelper=SH/'build/phase24/backend-candidate-pilot-07/consumed-tool.py'
assert ident(helper)['sha256']==ident(priorHelper)['sha256']
envfile=SH/'build/phase16/wave6-backend-environment-01.json';environment=json.loads(envfile.read_text());env=environment['environment']
assert any(Path(x['file']).resolve()==Path(env['CC']).resolve() and x['sha256']==ident(env['CC'])['sha256'] for x in environment['inputs'])
inputs=[ident(x) for x in [Path(__file__),HERE/'review-backend-renewal-run.py',attempt/'attempt.json',historical,helper,priorHelper,priorReport,envfile,p['inventory']['file'],ROOT/'design/phase30/backend-pilot-renewal.md']]
for key in ['api','runtime','base','node','bootstrapReport']:
 actual=ident(m[key]['file']);assert actual['sha256']==m[key]['sha256'];inputs.append(actual)
inputs.append(ident(env['CC']))
for entry in m['snapshot']['sources']:
 actual=ident(entry['frozen']['file']);assert actual['sha256']==entry['frozen']['sha256'];inputs.append(actual)
pilot=[(i,b) for i,b in enumerate(p['pilot'])];broad=[(i,b) for i,b in enumerate(p['broad']) if b['name'].startswith('js-')]
assert len(pilot)==7 and sum(len(b['cases']) for i,b in pilot)==81
assert len(broad)==13 and sum(len(b['cases']) for i,b in broad)==811
assert all(b['retain']=='failed' and len(b['cases'])<=64 and all(c['lanes']==['js'] for c in b['cases']) for i,b in broad)
shared=['io/cid_unknown.bend','io/effect_ctr_name.bend','io/main_foreign.bend','reg/array_open_element.bend']
assert [c['id'] for c in pilot[0][1]['cases']]==shared
pilots={(c['id'],c['lanes'][0]) for i,b in pilot for c in b['cases']}
broads=[(c['id'],c['lanes'][0]) for i,b in broad for c in b['cases']]
assert len(set(broads))==len(broads) and not pilots.intersection(broads)
for label,selected,budget in [('pilot',pilot,900),('broad-js',broad,1800)]:
 kind='pilot' if label=='pilot' else 'broad'
 batches=[{'index':i,'name':b['name'],'cases':b['cases'],'retain':b['retain'],'output':str(out/label/b['name']),
  'command':[sys.executable,str(helper),'candidate',str(historical),kind,str(i),str(out/label/b['name']),str(attempt)]} for i,b in selected]
 save(out/(label+'.json'),{'kind':'phase30-retained-backend-renewal-plan','complete':True,'executed':False,'campaign':label,'attempt':ident(attempt/'attempt.json'),
  'inputs':inputs,'environment':env,'cpu':'3-6','jobs':4,'outerTimeoutSeconds':budget,'terminationGraceSeconds':3,'batchTimeoutSeconds':420,
  'expectedRows':sum(len(b['cases']) for b in batches),'expectedSharedCheckFailures':shared if label=='pilot' else [],'batches':batches,
  'policy':'Root grant required. Serial batches, process-group deadline, stop on first new incomplete/nonexact row; retain all later rows unexecuted. No clean timing overlap.'})
for row in inputs:assert ident(row['file'])==row
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'complete':True,'executed':False,'out':str(out),'pilotRows':81,'broadJsRows':811}))
