#!/usr/bin/env python3
"""Freeze one actual checked compiler emission against the proved manual H flag."""
from pathlib import Path
import hashlib,json,sys
here=Path(__file__).resolve().parent;root=here.parents[3]
attempt,out=(Path(x).resolve() for x in sys.argv[1:]);m=json.loads((attempt/'attempt.json').read_text())
assert m['checked'] and m['config']['strictExact']
def ident(file):
 file=Path(file).resolve();raw=file.read_bytes();return {'file':str(file),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
original=root/'selfhost/build/phase30/self-emission-plan-16/plan.json';s=json.loads(original.read_text())
manual=root/'selfhost/build/phase30/registration-dispatch16-h/derive.json';d=json.loads(manual.read_text())
gate=root/'selfhost/build/phase30/registration-h-functional16/execution/report.json';g=json.loads(gate.read_text())
assert d['complete'] and d['audit']['registrationFree'] and g['complete'] and g['pass']
expected=d['variants']['flag']['output'];assert ident(expected['file'])==expected
assert any(x['mode']=='oracle' and x['observation']['smallOutputBytesEqual'] and x['observation']['sameOriginalHObservations'] and x['observation']['cache']['compilerSha256']==expected['sha256'] for x in g['steps'])
bootstrap=json.loads(Path(m['bootstrapReport']['file']).read_text());source=ident(bootstrap['source'])
assert source['sha256']==bootstrap['sourceSha256']==s['source']['sha256']
assert any(x['sha256']==source['sha256'] and Path(x['file']).resolve()==Path(source['file']) for x in m['artifacts'])
assert m['runtime']['sha256']==d['variants']['flag']['runtime']['sha256']
assert m['base']['sha256']==s['base']['sha256'] and m['node']['sha256']==s['node']['sha256']
inputs={}
def retain(file,sha=None):
 x=ident(file)
 if sha is not None:assert x['sha256']==sha
 inputs[x['file']]=x;return x
for x in [original,manual,gate,expected['file'],Path(__file__),here/'inspect-self-emission-correspondence-run.mjs',here.parent/'phase26/emit.mjs',root/'design/phase30/registration-flag-integration.md',attempt/'attempt.json',source['file']]:retain(x)
for k in ['node','api','checkedApi','bootstrapReport','runtime','base']:retain(m[k]['file'],m[k]['sha256'])
for x in m['artifacts']:retain(x['file'],x['sha256'])
for x in m['snapshot']['sources']:retain(x['frozen']['file'],x['frozen']['sha256'])
for file in (root/'selfhost/tools/development').glob('*.mjs'):retain(file)
out.mkdir(exist_ok=False)
p={'kind':'phase30-actual-self-emission-correspondence-plan','complete':True,'executed':False,'inputs':list(inputs.values()),'attempt':ident(attempt/'attempt.json'),'attemptDirectory':str(attempt),'source':source,'api':m['api'],'runtime':m['runtime'],'base':m['base'],'node':m['node'],'expected':expected,'functionalGate':ident(gate),'cpu':'2','timeoutMs':1200000,'nodeArgs':['--stack-size=4096','--max-old-space-size=8192'],'emitter':ident(here.parent/'phase26/emit.mjs'),'output':str(out/'compiler.mjs'),'scope':'One actual checked B1->H emission for exact correspondence to the validated manual flag. Byte equality transfers only the retained manual-H functional gate with its frozen16 driver and runtime input, not a fresh H17/new-runtime pipeline. No H->H, fixed point, inherited speed ratio or new H-conformance claim.'}
for x in inputs.values():assert ident(x['file'])==x
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes());print(json.dumps({'complete':True,'executed':False,'out':str(out),'expected':expected['sha256']}))
