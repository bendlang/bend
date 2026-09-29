#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'implementation/phase22/context-controls-ctor-demand.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
file=R/'selfhost/build/phase22/context-controls-ctor-demand-01/report.json';r=json.loads(file.read_text());assert r['complete'] and r['pass'] and r['rawExactPass'];assert len(r['comparisons'])==34 and all(x['pass'] for x in r['comparisons'])
extra=sum(len(o['additionalPreviouslyDemandedTagReads']) for x in r['semanticComparisons'] if x['scoped'] for o in x['observations']);assert extra==0
inputs=[ident(__file__),ident(file)]
for item in r['inputs']:
 for record in item.values():assert ident(record['file'])['sha256']==record['sha256'];inputs.append(ident(record['file']))
for lane in r['lanes']:
 assert lane['unchangedPrefix'] and lane['report']['pass'] and len(lane['report']['rows'])==34
 for key in ['attempt','api','probe','result','verifier']:
  record=lane[key];assert ident(record['file'])['sha256']==record['sha256'];inputs.append(ident(record['file']))
for p in ['implementation/phase22/context-controls-ctor-plan.md','implementation/phase22/context-controls-ctor-policy-addendum.md','design/phase22/constructor-immutable-demand.md']:inputs.append(ident(R/p))
report={'kind':'phase22-actual-constructor-lookup-closure','complete':True,'pass':True,'baselineApi':r['lanes'][0]['api'],'candidateApi':r['lanes'][1]['api'],'rawExactPass':True,'pairedCases':34,'independentExpectedOutcomes':68,'scopedImmutableCases':33,'prospectiveEffectfulWitnesses':1,'effectfulWitnessActualOutcome':'Also passes exact raw comparison; no exclusion or duplicate-read allowance needed to obtain the actual result.','allowedAdditionalTagReadsUsed':0,'scope':'Actual internal f_ctor_lookup via append-only derived probe; genuine API prefix unchanged and distinct probe hashes retained. Not a public run_lib ABI or performance claim.','coverage':['Preorder constructor-only selection and duplicate reference identity','Child-before-sibling traversal and eager kind/name demand','Exact raw return descriptors and original thrown objects','Unused field/subtree avoidance and first-error order','Repeated lookup history,100000-wide miss,512-deep hit/miss under4MiB stack/4GiB heap'],'inputs':inputs}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text('''# Constructor lookup direct controls

All34 paired cases and68 independent expected outcomes pass on the actual parent and candidate helpers. Full raw outcomes, returned reference identity, getter access order and read counts agree exactly. The generated nonempty branch reconstructs a list cell after reading the original tag/head/tail once, so even the second-read-poison witness passes. The prospective immutable-data policy used zero extra-tag allowances; its separate raw verdict is also true.

Coverage includes preorder/duplicate selection, child-before-sibling error order, unused payload avoidance, repeated calls, a100000-definition miss and512-deep hit/miss under the original4MiB stack/4GiB heap. Every probe preserves its complete genuine API prefix and has a separate hash. These are internal helper controls, not public ABI conformance or a speed measurement.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out)}))
