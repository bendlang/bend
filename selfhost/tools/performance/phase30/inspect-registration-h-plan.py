#!/usr/bin/env python3
"""Freeze a manual H runtime diagnostic's real-hash Base and small oracle gates."""
from pathlib import Path
import hashlib,json,sys
here=Path(__file__).resolve().parent;root=here.parents[3]
self_file,derive_file,out=(Path(x).resolve() for x in sys.argv[1:]);s=json.loads(self_file.read_text());d=json.loads(derive_file.read_text())
assert s['kind']=='phase30-bounded-self-emission-plan' and d['complete'] and d['audit']['registrationFree']
def ident(file):
 file=Path(file).resolve();raw=file.read_bytes();return {'file':str(file),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
assert ident(s['output'])==d['baseline'] or ident(s['output'])['sha256']==d['baseline']['sha256']
assert ident(d['variants']['flag']['output']['file'])==d['variants']['flag']['output']
reference=self_file.parent/'execution/h-oracle/report.json';r=json.loads(reference.read_text());assert r['complete'] and r['pass'] and r['smallOutputBytesEqual']
original=here/'inspect-self-emission-oracle.mjs';text=original.read_text()
start=text.index(' if(apiFile!==fs.realpathSync(plan.api.file)){');end=text.index(" for(const key of Object.keys(process.env))",start)
old=text[start:end]
new=''' assert.equal(plan.kind,'phase30-manual-h-runtime-functional-plan');
 assert.equal(apiFile,fs.realpathSync(plan.diagnostic.file));
 assert.deepEqual(apiIdentity,plan.diagnostic);
 const derivation=JSON.parse(fs.readFileSync(plan.derivation.file));
 assert.equal(derivation.complete,true);assert.equal(derivation.audit.registrationFree,true);
 assert.deepEqual(derivation.variants.flag.output,apiIdentity);
 assert.equal(derivation.baseline.sha256,plan.originalH.sha256);
 report.manuallyDerivedRuntimeDiagnostic=true;
'''
changed=text[:start]+new+text[end:]
edits=[(old,new),('phase30-self-emission-small-oracle','phase30-manual-h-runtime-small-oracle'),('sameB1Observations','sameOriginalHObservations')]
for before,after in edits[1:]:assert changed.count(before)==1;changed=changed.replace(before,after)
restored=changed
for before,after in reversed(edits):assert restored.count(after)==1;restored=restored.replace(after,before)
assert restored==text
out.mkdir(exist_ok=False);worker=out/'oracle.mjs';worker.write_text(changed)
(out/'original-oracle.mjs').write_text(text);(out/'consumed-plan.py').write_bytes(Path(__file__).read_bytes())
inputs={x['file']:x for x in s['inputs']}
for x in d['inputs']:inputs[x['file']]=x
for f in [self_file,derive_file,reference,original,worker,Path(__file__),here/'inspect-registration-h-run.mjs',s['output'],str(s['output'])+'.json',d['variants']['flag']['output']['file'],root/'design/phase30/registration-free-exact-dispatch.md']:
 x=ident(f);inputs[x['file']]=x
for x in inputs.values():assert ident(x['file'])['sha256']==x['sha256']
p={k:s[k] for k in ['node','api','source','attempt','runtime','base','driver','fixtures','resources','oracle']}
p['resources']={**p['resources'],'cpu':'7','oracleTimeoutSeconds':90}
p.update(kind='phase30-manual-h-runtime-functional-plan',complete=True,executed=False,inputs=list(inputs.values()),
 diagnostic=d['variants']['flag']['output'],originalH=ident(s['output']),derivation=ident(derive_file),reference=ident(reference),worker=ident(worker),
 sourcePlan=ident(self_file),oracleDerivation={'original':ident(original),'edits':[{'before':a,'after':b} for a,b in edits],'inverseExact':True},
 scope='Manually derived H runtime flag only; actual-hash Base check and same small oracle. Not a checked attempt, self-emission, timing or fixed-point claim.')
(out/'plan.json').write_text(json.dumps(p,indent=2)+'\n');print(json.dumps({'complete':True,'executed':False,'out':str(out),'diagnostic':p['diagnostic']['sha256']}))
