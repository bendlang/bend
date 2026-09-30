#!/usr/bin/env python3
"""Freeze same-source scalar scaling modules/points; execute no compiler/program."""
from pathlib import Path
import hashlib, json, sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
attempt,module,out=(Path(x).resolve() for x in sys.argv[1:])
def identity(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
inputs={}
def retain(p,expected=None):
 row=identity(p)
 if expected:assert row['sha256']==expected['sha256'],row['file']
 inputs[row['file']]=row;return row
source=HERE.parent/'phase29/fixture-mandelbrot.bend'
history=ROOT/'selfhost/build/phase30/fixture-lexical-confirm-08/report.json'
observed=json.loads(history.read_text());assert observed['complete'] and observed['allCasesMeasured']
configuration=Path(observed['inputs'][0]['file']);retain(configuration,observed['inputs'][0])
config=json.loads(configuration.read_text());assert config['protocol']=='confirm'
prior_file=configuration.parent/'plan.json';prior=json.loads(prior_file.read_text());assert prior['complete']
assert retain(source)==prior['source']
assert prior['source']['sha256']=='5c1b7031be03394ea7bfc64358b6db167711765e187e32d06f65a9f06bba3c7d'
for p in [Path(__file__),history,prior_file,ROOT/'design/phase30/scalar-region-cost-scaling.md',
          HERE/'inspect-scalar-scaling-check.py',HERE.parent/'phase29/compare.py',HERE.parent/'phase29/execute.mjs']:
 retain(p)
variants={}
for side in ['phase29','typescript']:
 row=prior['variants'][side]
 assert config['cases'][0]['modules'][side]==row['module']['file']
 for key in ['module','originalModule','emissionReceipt']:retain(row[key]['file'],row[key])
 for dep in row['dependencies'].values():retain(dep['file'],dep)
 receipt=json.loads(Path(row['emissionReceipt']['file']).read_text())
 assert receipt['complete'] and (receipt.get('checked') or receipt.get('observation',{}).get('checked'))
 assert receipt['input']['sha256']==identity(source)['sha256']
 assert receipt['output']['sha256']==row['module']['sha256']==row['originalModule']['sha256']
 variants[side]=row
m=json.loads((attempt/'attempt.json').read_text());assert m['checked']
receipt_file=Path(str(module)+'.json');r=json.loads(receipt_file.read_text())
assert r['complete'] and r['observation']['checked'] and r['observation']['status']=='ok'
assert Path(r['attempt']['file']).resolve()==attempt/'attempt.json'
retain(attempt/'attempt.json',r['attempt']);retain(module,r['output']);retain(receipt_file)
assert r['input']['sha256']==identity(source)['sha256']
deps={}
for key in ['api','runtime','base','driver']:
 deps[key]=retain(r[key]['file'],r[key])
 if key in m:assert deps[key]['sha256']==m[key]['sha256']
assert variants['typescript']['upstreamCommit']=='018751270e800bc222a93dad7f257083ee53a5f7'
assert deps['base']['sha256']==variants['phase29']['dependencies']['base']['sha256']==variants['typescript']['dependencies']['base.bend']['sha256']
variants['candidate']={'label':attempt.name,'module':identity(module),
 'emissionReceipt':identity(receipt_file),'dependencies':deps,'attempt':identity(attempt/'attempt.json')}
out.mkdir(parents=True,exist_ok=False)
points=[{'exportName':'bench','args':[n,524800],'expected':n}for n in [0,128,1024,8192]]
for i,p in enumerate(points):save(out/('point-'+str(i)+'.json'),p)
for side,row in variants.items():
 target=out/(side+'.mjs');target.write_bytes(Path(row['module']['file']).read_bytes())
 assert identity(target)['sha256']==row['module']['sha256']
 variants[side]={**row,'originalModule':row['module'],'module':identity(target)}
plan={'kind':'phase30-scalar-region-cost-scaling-plan','complete':True,'executed':False,
 'inputs':list(inputs.values()),'source':identity(source),'variants':variants,'points':points,
 'oracle':'Seed524800 decodes to cr=ci=0. Starting zr=zi=esc=it=0, every step keeps zr=zi=esc=0 and increments it, so expected=n for these bounded counts.',
 'protocol':'Unchanged confirm:5samples,3s warmup and100-call floor,300ms target. Zero is a different real branch, not an affine-intercept promise.',
 'checkCommand':[sys.executable,str(HERE/'inspect-scalar-scaling-check.py'),str(out)],
 'timingPolicy':'confirm.json is created only by the exact public precheck gate; no timing authorized by plan generation.'}
save(out/'plan.json',plan)
save(out/'confirm-unvalidated.json',{'protocol':'confirm','inputs':[identity(out/'plan.json'),*plan['inputs']],
 'cases':[{'id':'scalar-region-'+str(p['args'][0]),'point':p,'modules':{k:v['module']['file']for k,v in variants.items()}}for p in points]})
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'complete':True,'executed':False,'out':str(out),'points':len(points)}))
