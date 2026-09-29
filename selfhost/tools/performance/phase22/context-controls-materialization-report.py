#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
R=Path.cwd();out=R/'implementation/phase22/context-controls-materialization-02.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
inputs=[ident(__file__)];parts={};records={}
for name,n in [('materialization',16),('do-header',4),('header-demand',2)]:
 base=R/f'selfhost/build/phase22/context-controls-{name}-baseline-01';now=R/f'selfhost/build/phase22/context-controls-production-{name}-02';b=json.loads((base/'selected/paired.json').read_text());r=json.loads((now/'report.json').read_text());p=json.loads((now/'selected/paired.json').read_text());assert len(p['rows'])==n and not p['missing'] and not p.get('error');assert not any(x['referenceVerdict']=='fail' for x in b['rows']);parts[name]={'observations':n,'baselineExact':sum(x['exactAgreement'] for x in b['rows']),'candidateExact':sum(x['exactAgreement'] for x in p['rows']),'originalReportComplete':r['complete'],'originalReportPass':r['pass'],'gainedExact':r['comparison']['gainedExact'],'lostExact':r['comparison']['lostExact'],'newPrimitiveMismatch':r['comparison']['newPrimitiveMismatch']};inputs += [ident(base/'report.json'),ident(base/'selected/paired.json'),ident(now/'report.json'),ident(now/'selected/paired.json')]
 for q in [*r['inputs'],r['api'],r['attempt'],r['cache']]:
  prior=records.setdefault(q['file'],q);assert prior['sha256']==q['sha256']
for q in records.values():assert ident(q['file'])['sha256']==q['sha256'],q['file']
report={'kind':'phase22-materialization-public-controls-closure','complete':True,'pass':False,'acquisitionComplete':True,'attempt':'selfhost/build/phase22/context-build-05','api':r['api'],'baselineExact':sum(x['baselineExact'] for x in parts.values()),'candidateExact':sum(x['candidateExact'] for x in parts.values()),'observations':22,'parts':parts,'findings':['Eager arguments and eager constructor siblings now precede deferred lambda-body errors, exactly matching pin.','Both discarded-lambda positives remain accepted; returned lambda materialization rejects the unresolved operator; applied header lambda forces its body.','Do alias resolution precedes malformed header arguments and preserves compact<> cursor; all4 exact.','Zero-parameter header immediate error and parameterized-codomain deferred error both exact.','Two lost exacts remain in raw-computed-pattern observed text: candidate correctly rejects raw App with original span but prints unreduced application; pin observed term beta-reduces to0. Primitive outcomes agree.'],'postAcquisitionIdentityAudit':{'pass':True,'uniqueInputs':len(records)},'directBetaOriginOwnership':'Our context-controls-beta-origin.mjs was prepared but never run. Root reassigned actual direct helper controls to speed; his reports are separate, avoiding duplicate probes.','inputs':inputs}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text('''# Phase22 materialization feedback

Checked build05 matches 20 of 22 new public observations, compared with 13 on the installed parent. It fixes eager-versus-deferred error order, do-header alias-before-argument order, compact `<>` cursor, and immediate versus lazy header demand. All positive discarded-lambda programs retain acceptance.

Two diagnostics regress: raw `(k => k)(0) = 1` remains correctly rejected before completion, with the correct original span, but its observed term prints the unreduced application rather than the pin's `0`. Eligibility must still use the raw App; only its rejection display needs the pinned materialization behavior. The original failed materialization report is preserved. This feedback does not select the candidate.

All 22 rows were acquired and a closing audit verifies the exact consumed identities. Root delegated the private beta-origin probes to speed; this owner's prepared direct helper remains unconsumed. Source07's larger public rerun is separate.
''');print(json.dumps({'complete':True,'pass':False,'exact':report['candidateExact'],'report':ident(out)}))
