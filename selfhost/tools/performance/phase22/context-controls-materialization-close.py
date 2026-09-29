#!/usr/bin/env python3
"""Close the unchanged supplemental22 on a fresh candidate identity."""
from pathlib import Path
import hashlib,json,sys
R=Path.cwd();serial=sys.argv[1];out=R/f'implementation/phase22/context-controls-materialization-{serial}.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
launcher=R/f'selfhost/build/phase22/context-controls-materialization-sweep-{serial}/report.json';launch=json.loads(launcher.read_text());assert launch['complete'] and launch['pass']
inputs=[ident(__file__),ident(launcher)];parts={};records={};api=None
for name,n in [('materialization',16),('do-header',4),('header-demand',2)]:
 base=R/f'selfhost/build/phase22/context-controls-{name}-baseline-01';now=R/f'selfhost/build/phase22/context-controls-production-{name}-{serial}';b=json.loads((base/'selected/paired.json').read_text());r=json.loads((now/'report.json').read_text());p=json.loads((now/'selected/paired.json').read_text())
 assert r['complete'] and r['pass'];assert len(p['rows'])==n and not p['missing'] and not p.get('error');assert all(x['exactAgreement'] for x in p['rows']);assert not r['comparison']['lostExact'] and not r['comparison']['newPrimitiveMismatch']
 if api is None:api=r['api']
 assert r['api']==api
 parts[name]={'observations':n,'baselineExact':sum(x['exactAgreement'] for x in b['rows']),'candidateExact':n,'gainedExact':r['comparison']['gainedExact'],'lostExact':r['comparison']['lostExact']}
 inputs += [ident(base/'report.json'),ident(base/'selected/paired.json'),ident(now/'report.json'),ident(now/'selected/paired.json')]
 for q in [*r['inputs'],r['api'],r['attempt'],r['cache']]:
  prior=records.setdefault(q['file'],q);assert prior['sha256']==q['sha256']
for q in records.values():assert ident(q['file'])['sha256']==q['sha256'],q['file']
report={'kind':'phase22-supplemental-materialization-closure','complete':True,'pass':True,'api':api,'observations':22,'candidateExact':22,'baselineExact':sum(x['baselineExact'] for x in parts.values()),'parts':parts,'scope':'Unchanged materialization16/do-header4/header-demand2. Parameterized header-demand parse repeats one finalization26 observation; counts describe acquired observations, not distinct fixtures. No private beta-worker claim.','findings':['Raw computed App pattern eligibility remains a refusal; its observed term now beta-reduces exactly like the pin.','Discarded lambdas remain unforced; eager arguments/siblings and returned lambda materialization retain exact error order.','Do alias ambiguity precedes malformed arguments with exact cursor; immediate and lazy header demand match.'],'postAcquisitionIdentityAudit':{'pass':True,'uniqueInputs':len(records)},'inputs':inputs}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text(f'''# Phase22 supplemental materialization closure {serial}

All 22 frozen observations match the pin, compared with {report['baselineExact']} on the installed parent. Raw computed applications remain ineligible patterns, while their rejection display now follows pinned beta reduction. Eager/deferred error order, discarded lambdas, do-header alias-before-argument order and immediate/lazy header demand all remain exact.

The header-demand cohort repeats one finalization26 parse observation; counts describe acquired observations rather than distinct fixtures. Private worker controls are owned separately. The JSON binds the exact API, original reports/baselines and all {len(records)} consumed identities; no fixtures, expected outcomes or old reports changed.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out)}))
