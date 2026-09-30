#!/usr/bin/env python3
"""Freeze Phase29 / checked07 / checked08 / pinned-TS helper comparisons."""
from pathlib import Path
import argparse, hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[4]
def ident(p):
 p=Path(p).resolve();raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('out',type=Path);ap.add_argument('--control',type=Path,action='append',required=True)
args=ap.parse_args();out=args.out.resolve();out.mkdir(parents=True,exist_ok=False)
parent=ROOT/'selfhost/build/phase30/fixture-checked-plan-02/plan.json'
prior=json.loads(parent.read_text());assert prior['complete']
inputs={}
def retain(p):
 row=ident(p);inputs[row['file']]=row;return row
retain(Path(__file__));retain(parent)
shutil.copyfile(Path(__file__),out/'consumed-plan.py')
source=ROOT/'selfhost/tools/performance/phase29/fixture-mandelbrot.bend';retain(source)
variants={}
for label,key in [('phase29','phase29'),('actual07','region_literal_attempt07'),('typescript','typescript_pinned')]:
 row=prior['variants'][key]
 for k in ['module','originalModule','emissionReceipt']:
  assert retain(row[k]['file'])==row[k]
 for dependency in row['dependencies'].values():assert retain(dependency['file'])==dependency
 target=out/(label+'.mjs');shutil.copyfile(row['module']['file'],target)
 variants[label]={**row,'label':label,'module':ident(target)}
module=ROOT/'selfhost/build/phase30/fixture-region-08/candidate.mjs';receipt=Path(str(module)+'.json');r=json.loads(receipt.read_text())
assert r['complete'] and r['observation']['checked'] and r['input']['sha256']==ident(source)['sha256'] and r['output']['sha256']==ident(module)['sha256']
target=out/'actual08.mjs';shutil.copyfile(module,target)
row={'label':'actual08','scope':'Actual checked lexical-only attempt08; same runtime/region/literal behavior as actual07.',
 'module':ident(target),'originalModule':retain(module),'emissionReceipt':retain(receipt),'dependencies':{}}
for key in ['attempt','api','runtime','base','driver']:
 fresh=retain(r[key]['file']);assert fresh['sha256']==r[key]['sha256'];row['dependencies'][key]=fresh
attempt=json.loads(Path(r['attempt']['file']).read_text());assert attempt['checked']
for key in ['checkedApi','bootstrapReport','derivationReport']:
 if key in attempt:
  fresh=retain(attempt[key]['file']);assert fresh['sha256']==attempt[key]['sha256'];row['dependencies'][key]=fresh
row['dependencies']['scopedValidation']=retain(Path(r['attempt']['file']).parent/'validation-001/report.json')
assert row['dependencies']['runtime']['sha256']==variants['actual07']['dependencies']['runtime']['sha256']
variants={'phase29':variants['phase29'],'actual07':variants['actual07'],'actual08':row,'typescript':variants['typescript']}
controls=[]
for p in args.control:
 c=json.loads(p.read_text());assert c.get('pass') and c.get('complete');controls.append(retain(p))
plan={'kind':'phase30-actual-lexical-fixture-prospective-comparison','complete':True,
 'scope':'Actual checked compiler emissions, not disposable output rewriting. Dynamic helper [128,524800] returns128. Actual07/08 share runtime and source; attempt08 changes lexical private helper spelling.',
 'source':ident(source),'variants':variants,'controls':controls,'inputs':list(inputs.values())}
save(out/'plan.json',plan)
for protocol in ['screen','confirm']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*plan['inputs']],
  'cases':[{'id':'actual-lexical-mandelbrot-helper','point':{'args':[128,524800],'expected':128},'modules':{k:r['module']['file']for k,r in variants.items()}}]})
print(json.dumps({'complete':True,'out':str(out),'variants':list(variants)}))
