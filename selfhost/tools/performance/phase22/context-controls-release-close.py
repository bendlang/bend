#!/usr/bin/env python3
"""Close final candidate controls without changing any acquired report or oracle."""
from pathlib import Path
import json,hashlib,os
R=Path.cwd();out=R/'implementation/phase22/context-controls-release.json';assert not out.exists();records={}
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
def add(item):
 if isinstance(item,(str,Path)):item=ident(item)
 assert Path(item['file']).is_absolute();old=records.setdefault(item['file'],item);assert old['sha256']==item['sha256'],item['file'];return item
def read(p):
 p=R/p if not Path(p).is_absolute() else Path(p);add(p);return json.loads(p.read_text())
add(__file__);launch=read('selfhost/build/phase22/context-controls-release-01/report.json');assert launch['complete'] and launch['pass'] and len(launch['jobs'])==6
attemptFile=R/'selfhost/build/phase22/context-build-16/attempt.json';a=read(attemptFile);api=a['api'];assert api['sha256']=='ade8ef020e439b81ecb53057b33a473c34a3cbd993b98a044121ecc3c2b8c9c3';assert a['artifactKind']=='derived-b1';assert launch['api']==api
for x in [*launch['inputs'],a['api'],a['checkedApi'],a['bootstrapReport'],a['derivationReport'],*a['artifacts']]:add(x)
for row in a['snapshot']['sources']:add(row['frozen'])
public=[];execution=[]
for family,expected,target in [('production',154,public),('materialization',22,public),('execution',36,execution)]:
 path=f'selfhost/build/phase22/context-controls-{family}-sweep-06/report.json';s=read(path);assert s['complete'] and s['pass'];subtotal=0
 for item in s['inputs']:add(item)
 for job in s['jobs']:
  add(job['report']);q=read(job['report']['file']);assert q['complete'] and q['pass'] and q['api']==api;assert q['selected']['exactDifferences']==0 and not q['selected']['primitiveDifferences'];assert not q['comparison']['lostExact'] and not q['comparison']['newPrimitiveMismatch']
  pairfile=Path(job['report']['file']).parent/'selected/paired.json';p=read(pairfile);assert len(p['rows'])==q['selected']['candidate']['probes'] and all(x['exactAgreement'] for x in p['rows']);subtotal+=len(p['rows'])
  for item in [*q['inputs'],q['attempt'],q['cache']]:add(item)
  target.append({'name':job['name'],'observations':len(p['rows']),'exact':len(p['rows']),'report':job['report'],'rawSelectedComplete':p['selectedComplete'],'rawReferenceSummary':q['selected']['reference'],'rawCandidateSummary':q['selected']['candidate'],'rawReferenceOracleFailures':len(q['selected']['referenceOracleFailures'])})
 assert subtotal==expected
integrationFile=R/'selfhost/build/phase22/context-controls-integration198-02/report.json';integration=read(integrationFile);assert integration['complete'] and integration['pass'] and integration['api']==api;assert integration['selected']['candidate']['probes']==198 and integration['selected']['exactDifferences']==0
assert all(not integration['comparison'][k] for k in ['lostExact','gainedExact','changedCandidatePrimitive','newPrimitiveMismatch']);read(integrationFile.parent/'selected/paired.json')
for item in [*integration['inputs'],integration['attempt'],integration['cache']]:add(item)
historyFile=R/'selfhost/build/phase22/context-controls-history-03/report.json';h=read(historyFile);assert h['complete'] and h['pass'] and h['candidate']==api;assert len(h['fresh'])==2;assert [len(v['requests']) for group in h['histories'] for v in group['rows']]==[53,53,60,60];assert all(v['complete'] and not v['runner']['errors'] for group in h['histories'] for v in group['rows'])
policy=read('selfhost/build/phase22/context-controls-history-inputs-04/plan.json');assert len(h['intentionalTransitions'])==policy['expectedTransitions']==1;t=h['intentionalTransitions'][0];assert (t['history'],t['index'],t['id'],t['lane'])==('history-60',40,'check/monad_do_destructure.bend','parse');assert t['after']==policy['candidateDiagnostic'];assert h['exactPairedPayloadExceptBoundDriverIdentityAndOnePinnedDiagnostic'] is True
for item in [*h['inputs'],*policy['inputs']]:add(item)
componentFile=R/'selfhost/build/phase22/context-controls-standalone-01/report.json';c=read(componentFile);assert c['complete'] and c['status']==0 and c['signal'] is None and not c.get('error');assert 'src/front/contextual.bend' in c['modules'];assert not any(n.startswith('src/check/') or n in ['src/diagnostic/trace.bend','src/diagnostic/produce.bend','src/diagnostic/frontend.bend'] for n in c['modules'])
for path,row in c['identity'].items():add({'file':path,**row})
for field,digest in [('source','sourceSha256'),('api','apiSha256')]:add({'file':c[field],'sha256':c[digest]})
add(R/'implementation/phase22/context-controls-release-plan.md');add(R/'selfhost/build/phase22/context-source-17/manifest.json');add(R/'selfhost/build/phase22/context-source-17/parent.json')
for item in records.values():
 actual=ident(item['file']);assert actual['sha256']==item['sha256'],item['file']
 if 'bytes' in item:assert actual['bytes']==item['bytes'],item['file']
 if 'canonicalPath' in item:assert os.path.realpath(item['file'])==item['canonicalPath'],item['file']
report={'kind':'phase22-final-independent-release-controls','complete':True,'pass':True,'api':api,'artifactKind':'derived-b1','checkedApi':a['checkedApi'],'candidateRole':{'source':'selfhost/build/phase22/context-source-17/project','attempt':ident(attemptFile),'snapshotRoot':a['snapshot']['root'],'actualHostProvenance':h['variants']['candidate']['hostProvenance'],'apiIsTheSelectedDerivative':True,'standaloneApiIsSeparateCheckedComponent':True},'publicObservations':176,'publicExact':176,'totals':{'parseCheck':{'candidateExact':154,'observations':154},'execution':{'candidateExact':36,'observations':36},'supplemental':{'candidateExact':22,'observations':22}},'publicParts':public,'executionObservations':36,'executionExact':36,'executionParts':execution,'integration198':{'observations':198,'exact':198,'report':ident(integrationFile),'allPriorExactResultsRetained':True},'histories':{'requests':226,'freshChecks':2,'report':ident(historyFile),'intentionalTransitions':h['intentionalTransitions'],'policy':'Every complete result field exact except independently verified driver SHA and precisely one prospectively frozen monad parse diagnostic transition to pinned TypeScript.'},'standaloneFrontend':{'report':ident(componentFile),'modules':len(c['modules']),'apiSha256':c['apiSha256'],'sourceSha256':c['sourceSha256'],'complete':True,'pass':True,'checkerIndependent':True,'ordinaryTracedSeededResultsEqual':True},'rawStatusesPreserved':True,'overlaps':'Nine execution check observations overlap public controls; header-demand repeats a finalization parse observation. Historical marked114 is covered separately within the implementation-owner196 vector, not reacquired here. These counts are not distinct-program totals.','identityAudit':{'complete':True,'pass':True,'uniqueInputs':len(records)},'scope':'Fresh final source17/host acquisitions only; prior success/failure artifacts untouched. Exact paired behavior is separate from original raw expectation statuses. No speed, promotion, GPU or universal conformance claim.','inputs':list(records.values())}
out.write_text(json.dumps(report,indent=2)+'\n')
supp=R/'implementation/phase22/context-controls-release-supplemental.json';assert not supp.exists()
supp.write_text(json.dumps({'kind':'phase22-final-release-supplemental-controls','complete':True,'pass':True,'api':api,'candidateExact':22,'observations':22,'parts':public[-3:],'scope':'Final source17 supplemental materialization16,do-header4,header-demand2, all exact. Companion to the complete final release receipt.','inputs':[ident(out)]},indent=2)+'\n')
out.with_suffix('.md').write_text('''# Final contextual frontend: independent release controls

Source17/context-build-16 passes all176 frozen public observations,36 check/interpreter/JavaScript/native observations and the unchanged integration198 selection exactly. These are fresh acquisitions on the final selected API and its actual frozen host; earlier source09/source10 reports remain unchanged. Raw fixture expectations and runner statuses are retained separately from exact comparison.

Both complete53/60-request histories pass for each compiler, plus two fresh long-string checks. Each image uses its own verified host and Base cache. The original prospective policy permits only verified driver identity and exactly one pinned diagnostic correction at history60/index40/parse for monad_do_destructure; every other result field remains exact. The original failed history and all policies are preserved.

The unchanged standalone frontend component test passes on the final source snapshot. It includes the contextual module, excludes checker and diagnostic trace/producer modules, genuinely checks its separate compiled component and confirms equal ordinary, traced and seeded graph loading. Its API is distinct from the release API; the receipt keeps the selected derived release image and original checked B1 identities separate.

The counts overlap as recorded in JSON. The historical marked114 subset is covered by the implementation owner's196 gate, not a duplicate acquisition here. These controls do not make a performance, promotion, GPU or universal conformance claim.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out),'api':api['sha256'],'verifiedInputs':len(records)}))
