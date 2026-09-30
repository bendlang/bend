#!/usr/bin/env python3
"""Freeze actual checked-emission fixture variants without executing them."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[4]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
assert sys.argv[2:] in [[],['--attempt07']]
def ident(p):
 p=Path(p).resolve();return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
inputs={}
def retain(p):
 p=Path(p).resolve();row=ident(p);inputs[str(p)]=row;return row
source=ROOT/'selfhost/tools/performance/phase29/fixture-mandelbrot.bend'
points=ROOT/'selfhost/tools/performance/phase29/fixture-points.json'
variants=[
 ('phase29',ROOT/'selfhost/build/phase29/fixture-candidate-04/candidate.mjs', 'Phase29 installed baseline; primitive arithmetic and scalar Nat worker.'),
 ('owned_attempt01',ROOT/'selfhost/build/phase30/fixture-owned-01/candidate.mjs', 'Checked Phase30 attempt01: owned arguments, historical runtime.'),
 ('region_attempt05',ROOT/'selfhost/build/phase30/fixture-region-05/candidate.mjs', 'Checked attempt05: scalar regions and repaired exact-application scheduling.'),
 ('region_literal_attempt06',ROOT/'selfhost/build/phase30/fixture-region-06/candidate.mjs', 'Checked attempt06: attempt05 mechanisms plus literal shifts.'),
 ('typescript_pinned',ROOT/'selfhost/build/phase29/prototype-01/upstream.mjs', 'Pinned upstream TypeScript-generated library; same source.'),
]
if sys.argv[2:]:
 variants.insert(4,('region_literal_attempt07',ROOT/'selfhost/build/phase30/fixture-region-07/candidate.mjs',
  'Checked attempt07: attempt06 mechanisms with callable-kind preservation; matcher arrows and regular Nat callbacks retain their original kind.'))
report={'kind':'phase30-checked-fixture-prospective-comparison','complete':False,
 'scope':'One actual compiled Mandelbrot helper fixture, dynamic args [128,524800], expected 128. No program or compiler execution performed by this planner. Historical variants retain their runtime identities; region05 versus region06 isolates literal shifts on the same repaired runtime. Optional attempt07 separately preserves callable kinds.',
 'variants':{},'inputs':[]}
save(out/'plan.json',report)
retain(Path(__file__));retain(source);retain(points)
shutil.copyfile(Path(__file__),out/'consumed-plan.py');shutil.copyfile(source,out/'source.bend')
for label,module,scope in variants:
 receipt=module.with_suffix('.mjs.json');r=json.loads(receipt.read_text())
 assert r['complete'] and r['input']['sha256']==ident(source)['sha256']
 assert r['output']['sha256']==ident(module)['sha256']
 dst=out/(label+'.mjs');shutil.copyfile(module,dst)
 row={'label':label,'scope':scope,'module':ident(dst),'originalModule':retain(module),'emissionReceipt':retain(receipt),'dependencies':{}}
 shutil.copyfile(receipt,out/(label+'-emission.json'))
 if label!='typescript_pinned':
  assert r['observation']['checked'] and r['observation']['status']=='ok'
  for key in ['attempt','api','runtime','base','driver']:
   value=r[key];fresh=retain(value['file']);assert fresh['sha256']==value['sha256'];row['dependencies'][key]=fresh
  attempt=json.loads(Path(r['attempt']['file']).read_text());assert attempt['checked']
  row['artifactKind']=attempt.get('artifactKind')
  for key in ['checkedApi','bootstrapReport','derivationReport']:
   if key in attempt:
    value=attempt[key];fresh=retain(value['file']);assert fresh['sha256']==value['sha256'];row['dependencies'][key]=fresh
  validation=Path(r['attempt']['file']).parent/'validation-001/report.json'
  if validation.exists():row['dependencies']['scopedValidationReceipt']=retain(validation)
 else:
  upstream=ROOT/'selfhost/.bootstrap/upstream-phase23'
  commit=subprocess.check_output(['git','-C',str(upstream),'rev-parse','HEAD'],text=True).strip()
  assert commit=='018751270e800bc222a93dad7f257083ee53a5f7'
  row['upstreamCommit']=commit
  for name in ['bend.ts','comp.ts','base.bend']:
   row['dependencies'][name]=retain(upstream/'bend2'/name)
  row['dependencies']['historicalAcquisition']=retain(module.parent/'report.json')
 report['variants'][label]=row
for relative in [
 'selfhost/build/phase30/fixture-owned-01/emission-equivalence.json',
 'selfhost/build/phase30/fixture-owned-01/check/run.json',
 'selfhost/build/phase30/scalar-check-05/run.json',
 'selfhost/build/phase30/scalar-check-06/run.json',
 'selfhost/build/phase30/literal-shifts-check-06/run.json',
 'selfhost/build/phase30/literal-shifts-order-06/report.json',
]:
 p=ROOT/relative;assert p.is_file(),p;retain(p)
report['inputs']=list(inputs.values())
for row in report['inputs']:assert ident(row['file'])==row
report['complete']=True;save(out/'plan.json',report)
for protocol in ['screen','confirm']:
 save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(out/'plan.json'),*report['inputs']],
  'cases':[{'id':'checked-mandelbrot-helper','point':{'args':[128,524800],'expected':128},
    'modules':{label:row['module']['file'] for label,row in report['variants'].items()}}]})
print(json.dumps({'complete':True,'out':str(out),'variants':list(report['variants']),'inputs':len(report['inputs'])}))
