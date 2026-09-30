#!/usr/bin/env python3
"""Freeze an unexecuted NEW811 JS plan; never relabel it historical renewal."""
from pathlib import Path
import hashlib,json,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
priorfile,out=(Path(x).resolve() for x in sys.argv[1:]);prior=json.loads(priorfile.read_text());assert prior['campaign']=='broad-js' and prior['expectedRows']==811
out.mkdir(exist_ok=False)
def identity(file):
 file=Path(file).resolve();raw=file.read_bytes();return {'file':str(file),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
inputs={x['file']:x for x in prior['inputs']}
def retain(file,sha=None):
 item=identity(file)
 if sha is not None:assert item['sha256']==sha,item['file']
 inputs[item['file']]=item;return item
m=json.loads(Path(prior['attempt']['file']).read_text());upstream=Path(m['config']['upstream']);host=Path(m['snapshot']['root'])
historical=ROOT/'selfhost/build/phase24/backend-plan-01/plan.json';hp=json.loads(historical.read_text());inventoryfile=Path(hp['inventory']['file']);inventory=json.loads(inventoryfile.read_text());retain(inventoryfile,hp['inventory']['sha256'])
fixtures={x['id']:x for x in inventory['tests']}
selected=[]
for b in prior['batches']:
 assert b['name'].startswith('js-') and b['retain']=='failed' and len(b['cases'])<=64
 for c in b['cases']:
  assert c['lanes']==['js'];f=fixtures[c['id']];assert f['main'] and not f['negative'] and f['hasExpectation'] and 'js' in f['backends'];selected.append(f)
assert len(selected)==len({x['id'] for x in selected})==811
# Bind all inventoried source/effect/support identities as well as selected oracles.
def inventory_inputs(value):
 if isinstance(value,dict):
  if 'file' in value and 'sha256' in value:
   f=Path(value['file']);retain(f if f.is_absolute() else upstream/f,value['sha256'])
  for x in value.values():inventory_inputs(x)
 elif isinstance(value,list):
  for x in value:inventory_inputs(x)
inventory_inputs(inventory)
for f in [Path(__file__),HERE/'review-additional-js-run.py',HERE/'review-additional-js-policy.py',priorfile,ROOT/'design/phase30/additional-js-backend-coverage.md',ROOT/'implementation/phase24/backend-census.md']:retain(f)
judge=retain(host/'tools/conformance/judge.mjs');driver=retain(host/'tools/typed-driver.mjs');adapter=retain(host/'tools/conformance/adapters/typed.mjs')
assert "Upstream gate exempts unprintable main types from compiled execution." in Path(judge['file']).read_text()
batches=[]
for b in prior['batches']:
 c=list(b['command']);assert c[-2]==b['output'];dest=str(out/'execution'/b['name']);c[-2]=dest
 batches.append({**b,'command':c,'output':dest})
p={'kind':'phase30-additional-js-coverage-plan','complete':True,'executed':False,'attempt':prior['attempt'],'inputs':list(inputs.values()),'batches':batches,'fixtures':selected,'judge':judge,'policy':identity(HERE/'review-additional-js-policy.py'),'hostProvenance':{'driverSha256':driver['sha256'],'adapterSha256':adapter['sha256']},'runtimeNodeArgs':['--stack-size=4096','--max-old-space-size=4096'],'expectedRows':811,'cpu':'3-6','jobs':4,'outerTimeoutSeconds':1800,'terminationGraceSeconds':3,'retainedBytesStop':200*1024**2,'minimumFreeBytes':150*1024**2,'scope':'New paired JS coverage, never historical811 renewal. Unchanged oracles and narrow unprintable-main NA; raw verdicts/complete observables retained.'}
for item in inputs.values():assert identity(item['file'])==item
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes());print(json.dumps({'complete':True,'executed':False,'rows':811,'out':str(out)}))
