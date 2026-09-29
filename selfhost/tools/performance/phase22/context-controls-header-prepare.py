#!/usr/bin/env python3
"""Select unchanged declaration cases and explicitly reuse their acquired baseline rows."""
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'selfhost/build/phase22/context-controls-header-inputs-01';base=R/'selfhost/build/phase22/context-controls-header-baseline-subset-01';out.mkdir();(base/'selected').mkdir(parents=True)
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
selection=R/'selfhost/build/phase16/wave9-source-01/selection.json';report=R/'selfhost/build/phase22/context-controls-integration198-01/report.json';paired=report.parent/'selected/paired.json';s=json.loads(selection.read_text());r=json.loads(report.read_text());p=json.loads(paired.read_text());assert r['complete'] and r['pass']
explicit={'p16-import/'+x for x in ['ordinary-fill','annotated-fill','alias-name','alias-type','alias-law']}
cases=[c for c in s['cases'] if c['id'] in explicit or c['id'].startswith('local-law/')];assert len(cases)==13 and sum(len(c['lanes']) for c in cases)==26
keys={(c['id'],lane) for c in cases for lane in c['lanes']};rows=[row for row in p['rows'] if (row['id'],row['lane']) in keys];assert len(rows)==26 and all(x['exactAgreement'] for x in rows)
inputs=[ident(__file__),ident(selection),ident(report),ident(paired),*[ident(c['file']) for c in cases]]
plan={'kind':'phase22-declaration-header26-frozen-subset','complete':True,'prospectiveBeforeCandidate':True,'observations':26,'sourceSelection':ident(selection),'baselineAcquisition':ident(report),'scope':'Five original import/law-fill/alias declaration cases and eight original local-law cases. Full case objects and complete paired rows reused unchanged; no new oracle, fixture or baseline execution.','inputs':inputs}
(out/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
(base/'selected/paired.json').write_text(json.dumps({'kind':'explicit-unchanged-baseline-row-subset','source':ident(paired),'rows':rows,'missing':[]},indent=2)+'\n')
(base/'report.json').write_text(json.dumps({'kind':'phase22-baseline-subset-not-new-acquisition','complete':True,'pass':True,'api':r['api'],'observations':26,'exact':26,'source':ident(report),'inputs':inputs},indent=2)+'\n')
print(json.dumps({'prepared':True,'observations':26,'plan':ident(out/'plan.json')}))
