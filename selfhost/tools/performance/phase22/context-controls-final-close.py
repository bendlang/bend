#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'implementation/phase22/context-controls-final.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
inputs=[ident(__file__)]
def read(p):
 p=R/p;inputs.append(ident(p));return json.loads(p.read_text())
public=read('implementation/phase22/context-controls-production-05.json');extra=read('implementation/phase22/context-controls-materialization-05.json');history=read('selfhost/build/phase22/context-controls-history-02/report.json');binding=read('selfhost/build/phase22/context-controls-history-inputs-02/plan.json');policy=read('selfhost/build/phase22/context-controls-history-inputs-03/plan.json');subset=read('implementation/phase22/context-controls-marked-subset.json');failure=read('selfhost/build/phase22/context-controls-history-01/report.json')
for x in [public,extra,history,binding,subset]:assert x['complete'] and x['pass']
assert not failure['pass'];assert public['api']['sha256']==extra['api']['sha256']==history['candidate']['sha256']==binding['api']['sha256']==subset['api']['sha256']=='eac3b89d561287b9a51b411ab6353ea275e90c571de7d7c8e733c99eb0755a94'
assert binding['apiIdenticalToSource09'];assert len(history['fresh'])==2
assert len(history['histories'])==2;assert [len(v['requests']) for h in history['histories'] for v in h['rows']]==[53,53,60,60]
assert all(v['complete'] and not v['runner']['errors'] for h in history['histories'] for v in h['rows'])
assert len(history['intentionalTransitions'])==policy['expectedTransitions']==1
transition=history['intentionalTransitions'][0];assert (transition['history'],transition['index'],transition['id'],transition['lane'])==('history-60',40,'check/monad_do_destructure.bend','parse');assert transition['after']==policy['candidateDiagnostic']
records={}
for report in [public,extra,history,binding,policy,subset]:
 for item in report['inputs']:
  old=records.setdefault(item['file'],item);assert old['sha256']==item['sha256'],item['file']
for item in records.values():assert ident(item['file'])['sha256']==item['sha256'],item['file']
report={'kind':'phase22-independent-public-and-history-closure','complete':True,'pass':True,'api':history['candidate'],'source10Host':history['variants']['candidate']['hostProvenance'],'publicObservations':176,'publicExact':176,'executionObservations':36,'executionExact':36,'historyRequests':226,'freshChecks':2,'historyPolicy':'Every complete result field exact except actual verified driver SHA and the one prospectively frozen history60/index40/parse monad diagnostic transition to the independently frozen pin.','intentionalTransitions':history['intentionalTransitions'],'historicalMarkedSubset':{'observations':114,'exact':114,'formerDifferencesClosed':43,'newStandaloneRun':False},'overlaps':'Header-demand repeats one finalization26 parse observation; nine program check observations overlap public controls; marked114 is within the independently owned196 vector. Counts must not be added as distinct cases.','hostDeltaReview':binding['hostReview'],'source09to10':binding['source09to10'],'rawFailuresPreserved':'Prospective main/feature fixture-assumption statuses, source05 regressions, source06 computed-pattern regressions and history01 strict parent comparison failure remain unchanged. Original source09 history binding was never consumed.','identityAudit':{'pass':True,'uniqueConsumedInputs':len(records)},'scope':'Independent public/parser/checker behavior, ordinary check/interpreter/JS/native programs, and exact request-history state controls. No promotion, performance, hardware/GPU, or retired raw parser API compatibility claim. Integration198 final-host rerun is a separately pending task.','inputs':inputs}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text('''# Independent Phase22 final controls

The final compiler image matches all176 frozen public observations and36 ordinary program observations across check, interpreter, JavaScript and native execution. The source10 host uses the identical source09 compiler image; its sole later host change reproduces the pinned per-import checkup file-open/catch order.

Both complete53/60-request histories and two fresh long-string checks pass. Each compiler uses its own exact snapshot host and validated cache. Complete payloads remain equal except their verified driver identity and precisely one intentional diagnostic correction: history60/index40/parse for monad_do_destructure now reports the independently frozen pin's pattern error. The first strict-parent failure and original tools/bindings are preserved; the narrow policy was frozen before the complete rerun.

The historical marked114 is an exact subset of the final196 vector, closing its43 old differences without a redundant standalone acquisition. The JSON records overlaps; these counts are not distinct-case totals. Integration198 is separately pending. No performance or promotion conclusion follows from this report.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out),'verifiedInputs':len(records)}))
