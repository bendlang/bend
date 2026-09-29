#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'implementation/phase22/context-controls-integration198.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
directory=R/'selfhost/build/phase22/context-controls-integration198-01';file=directory/'report.json';r=json.loads(file.read_text());paired=directory/'selected/paired.json';p=json.loads(paired.read_text());assert r['complete'] and r['pass'];assert len(p['rows'])==198 and not p['missing'] and not p.get('error');assert all(x['exactAgreement'] for x in p['rows']);assert not r['comparison']['lostExact'] and not r['comparison']['gainedExact'] and not r['comparison']['newPrimitiveMismatch']
for item in [*r['inputs'],r['api'],r['attempt'],r['cache']]:assert ident(item['file'])['sha256']==item['sha256'],item['file']
report={'kind':'phase22-historical-integration198-closure','complete':True,'pass':True,'api':r['api'],'observations':198,'exact':198,'gains':0,'losses':0,'prior':'selfhost/build/phase19/instance-integration198-01','rawSelectedComplete':r['selected']['selectedComplete'],'rawReferenceStatuses':r['selected']['reference']['statuses'],'rawCandidateStatuses':r['selected']['candidate']['statuses'],'scope':'Actual genuine final source10 host rerun of unchanged frozen selection, paths, oracles and pin observations. Exact198 preserves prior198. Covers imports, aliases/lambdas, qualified patterns, local-law fills, module names, quiet TODO and program completion. No performance or promotion claim.','previousFinalReceipt':'context-controls-final.json remains immutable; this closes its explicitly pending integration198 task.','inputs':[ident(__file__),ident(file),ident(paired),ident(R/'implementation/phase22/context-controls-integration-plan.md'),ident(R/'selfhost/build/phase16/wave9-source-01/selection.json'),ident(R/'selfhost/build/phase19/instance-integration198-01/report.json'),ident(R/'implementation/phase22/context-controls-final.json')]}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text('''# Historical integration198 closure

All198 observations remain strict exact on the source10 host and checked API. The original Phase16 selection, fixture paths, oracles and pinned observations are unchanged; comparison with the Phase19 baseline has zero gains and zero losses. This covers imports, alias/lambda resolution, qualified patterns, local-law fills, module display, quiet TODO and program completion.

The original negative parse observed labels remain visible in the raw reports. This closes the pending integration task in the earlier immutable final-control receipt. The candidate remains uninstalled because its independent cost screen failed; no performance or promotion claim follows from this correctness result.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out)}))
