#!/usr/bin/env python3
"""Narrow current-image binding of the unchanged warmed compiler protocol."""
from pathlib import Path
import hashlib,json,sys
here=Path(__file__).resolve().parent;root=here.parents[3]
correspondence,positive,out=(Path(x).resolve() for x in sys.argv[1:])
old_file=root/'selfhost/build/phase30/generated-compiler-cost-plan16b/plan.json'
old=json.loads(old_file.read_text());c=json.loads(correspondence.read_text())
assert c['complete'] and c['pass'] and c['byteIdenticalToManualFlag']
cp=json.loads(Path(c['plan']['file']).read_text())
m=json.loads(Path(cp['attempt']['file']).read_text())
assert m['checked'] and m['config']['strictExact']
assert Path(cp['attemptDirectory']).name=='attempt-17'
def identity(file):
 file=Path(file).resolve();raw=file.read_bytes();return {'file':str(file),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
inputs={}
def retain(file,expected=None):
 x=identity(file)
 if expected is not None:assert x['sha256']==expected['sha256'],str(file)
 inputs[x['file']]=x;return x
for x in old['inputs']+cp['inputs']:retain(x['file'],x)
for file in [old_file,correspondence,cp['attempt']['file'],Path(__file__),root/'design/phase30/warmed-generated-compiler17.md']:
 retain(file)
retain(c['plan']['file'],c['plan']);retain(c['emissionReceipt']['file'],c['emissionReceipt'])
h=retain(c['output']['file'],c['output']);assert h['sha256']==cp['expected']['sha256']
receipt_file=Path(str(positive)+'.json');receipt=json.loads(receipt_file.read_text())
assert receipt['complete'] and receipt['observation']['checked'] and receipt['observation']['status']=='ok'
retain(receipt_file)
for key in ['attempt','input','api','runtime','base','driver','output']:
 retain(receipt[key]['file'],receipt[key])
assert receipt['attempt']['sha256']==cp['attempt']['sha256']
assert receipt['input']['sha256']==old['source']['sha256']
for key in ['api','runtime','base']:assert receipt[key]['sha256']==m[key]['sha256']
assert receipt['output']['sha256']==identity(positive)['sha256']
assert m['api']['sha256']==old['selectedB1']['sha256']
assert m['checkedApi']['sha256']==old['variants']['checked_parent']['sha256']
assert cp['source']['sha256']==old['compilerSource']['sha256']
assert m['base']['sha256']==old['base']['sha256'] and m['node']['sha256']==old['node']['sha256']
assert receipt['driver']['sha256']==old['driver']['sha256']
before=Path(old['expected']['file']).read_bytes();runtime16=Path(old['runtime']['file']).read_bytes()
runtime17=Path(m['runtime']['file']).read_bytes()
assert before.startswith(runtime16)
assert positive.read_bytes()==runtime17+before[len(runtime16):]
plan=dict(old)
plan.update(inputs=[],node=m['node'],compilerSource=cp['source'],driver=receipt['driver'],
 base=m['base'],runtime=m['runtime'],variants={'checked_parent':retain(m['checkedApi']['file'],m['checkedApi']),'generated_h':h},
 selectedB1=m['api'],expected=identity(positive),
 scope='Actual H17 versus the genuine TS-produced parent of the same Bend compiler; unchanged warmed-once small request protocol,17 runtime input and fresh exact positive-byte oracle. Not upstream TypeScript compiler speed, steady state, fixed point or full compiler cost.',
 correspondence=identity(correspondence),positiveCheckedEmission=identity(receipt_file),
 originalProtocol=identity(old_file),bindingAmendment=identity(root/'design/phase30/warmed-generated-compiler17.md'))
for key in ['node','api','checkedApi','base','runtime']:retain(m[key]['file'],m[key])
for key in ['worker']:
 retain(old[key]['file'],old[key])
retain(here/'inspect-generated-compiler-cost-run.mjs')
plan['inputs']=list(inputs.values())
for x in plan['inputs']:assert identity(x['file'])==x
out.mkdir(parents=True,exist_ok=False)
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
print(json.dumps({'complete':True,'executed':False,'out':str(out),'h':h,'expected':plan['expected']}))
