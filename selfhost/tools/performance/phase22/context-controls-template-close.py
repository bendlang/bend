#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'implementation/phase22/context-controls-template-screen-01.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
inputs=[ident(__file__)];parts=[]
for name in ['parent','candidate']:
 p=R/f'selfhost/build/phase22/context-controls-template-{name}-01/report.json';r=json.loads(p.read_text());assert r['complete'] and r['pass'] and r['selected']['exactDifferences']==0;assert r['selected']['candidate']['probes']==24
 for item in [*r['inputs'],r['api'],r['attempt'],r['cache']]:assert ident(item['file'])['sha256']==item['sha256'],item['file']
 rows=json.loads((p.parent/'selected/paired.json').read_text())['rows'];assert len(rows)==24 and all(x['exactAgreement'] for x in rows)
 parts.append({'name':name,'api':r['api'],'observations':24,'exact':24,'report':ident(p),'rawReferenceSummary':r['selected']['reference'],'rawCandidateSummary':r['selected']['candidate'],'prospectiveOracleFailures':r['selected']['referenceOracleFailures']})
 inputs.extend([ident(p),ident(p.parent/'selected/paired.json'),*r['inputs']])
 if name=='candidate':
  assert all(not r['comparison'][key] for key in ['lostExact','gainedExact','changedCandidatePrimitive','newPrimitiveMismatch'])
for p in ['selfhost/build/phase22/context-controls-template-inputs-01/plan.json','selfhost/build/phase22/context-controls-template-inputs-01/selection.json']:inputs.append(ident(R/p))
report={'kind':'phase22-dx-index-public-screen','complete':True,'pass':True,'observationsPerImage':24,'pairedAcquisitions':48,'parts':parts,'scope':'Frozen existing fixture24 public parse/check observations for dx-only contextual call lookup. Exact pinned reference and complete parent outcomes retained. No fixture or oracle changes. Internal duplicate-index invariant is proved separately by the implementation owner; this screen does not authorize index substitution for family/marked/name consumers. No speed/promotion claim.','inputs':inputs}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text('''# Template lookup public screen

All24 frozen public observations match pinned TypeScript exactly on both the checked parent and the dx-only index candidate. Complete reference objects remain equal; no result, primitive outcome or exact match changed. All raw expectations and verdicts are retained.

The12 unchanged fixtures cover imported fills, template aliases and lexical shadowing, local laws, ordinary template calls, recursive law/template self-calls, a missing call target, a wrong-type template argument and insufficient fill binders. This complements the owner's compiled index-invariant proof; it does not authorize a broader family or name lookup replacement and makes no timing claim.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out)}))
