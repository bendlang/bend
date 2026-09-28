#!/usr/bin/env node
// Exact compatibility and semantic triage are separate: a generic rejection
// does not match the fixture diagnostic, and an Error expectation can be runtime.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
export function semanticSummary(rows,fixtures=[]) {
  const byId=new Map(fixtures.map(t=>[t.id,t]));
  const failureKind=r=>r.failureKind??byId.get(r.id)?.failureKind??null;
  const checked=rows.filter(r=>r.lane==='check'),positive=checked.filter(r=>!r.negative),negative=checked.filter(r=>r.negative&&failureKind(r)!=='proof-trust');
  // Explicit type acceptance survives a later proof-trust/compile/runtime
  // refusal. Legacy reports without this field retain their former inference.
  const accepted=r=>r.result?.checked===true&&(r.result.typeAccepted===true||(r.result.typeAccepted===undefined&&r.result.status==='ok'));
  const trust=checked.filter(r=>failureKind(r)==='proof-trust');
  const rejected=r=>r.result?.status==='error';
  const acceptedErrors=negative.filter(accepted).map(r=>{
    const later=rows.filter(other=>other.id===r.id&&other.status==='pass'&&['compile-rejection','runtime-rejection'].includes(other.evidence));
    return {id:r.id,lanes:[...new Set(later.map(other=>other.lane))],phases:[...new Set(later.map(other=>other.result.phase))]};
  });
  const failureGroups={};
  for(const r of positive.filter(r=>!accepted(r))) {
    const result=r.result||{},key=(result.phase||r.status||'unknown')+': '+(result.diagnostic||result.reason||r.reason||'unknown');
    (failureGroups[key]??=[]).push(r.id);
  }
  const executionGroups={};
  for(const r of rows.filter(r=>!r.negative&&!['parse','check'].includes(r.lane)&&['fail','timeout','crash','unsupported'].includes(r.status))) {
    const reason=r.result?.diagnostic||r.result?.reason||r.reason||'unknown';
    const key=r.lane+': '+reason;
    (executionGroups[key]??={lane:r.lane,reason,ids:[]}).ids.push(r.id);
  }
  return {
    completedRows:rows.length,
    typeAcceptance:{total:checked.length,accepted:checked.filter(accepted).length,
      checkerRejected:checked.filter(r=>r.result?.status==='error'&&r.result.phase==='check'&&r.result.checked===true&&!accepted(r)).length,
      notEstablished:checked.filter(r=>!accepted(r)&&!(r.result?.status==='error'&&r.result.phase==='check'&&r.result.checked===true)).map(r=>r.id)},
    proofTrustExpectations:{total:trust.length,typeAccepted:trust.filter(accepted).length,
      exactPasses:trust.filter(r=>r.status==='pass'&&r.evidence==='proof-trust-rejection').length,
      refusals:trust.filter(r=>accepted(r)&&r.result.status==='error'&&r.result.phase==='verdict'&&r.result.proofTrust==='failed').map(r=>r.id),
      other:trust.filter(r=>r.status!=='pass'||r.evidence!=='proof-trust-rejection').map(r=>({id:r.id,result:r.result,status:r.status}))},
    positiveChecks:{total:positive.length,accepted:positive.filter(accepted).length,other:positive.filter(r=>!accepted(r)).map(r=>({id:r.id,result:r.result,status:r.status}))},
    errorExpectations:{total:negative.length,acceptedForPhaseTriage:negative.filter(accepted).map(r=>r.id),
      acceptedWithExpectedLaterRejection:acceptedErrors.filter(r=>r.lanes.length),
      acceptedWithoutExpectedLaterRejection:acceptedErrors.filter(r=>!r.lanes.length).map(r=>r.id),
      rejectedByPhase:negative.filter(rejected).reduce((out,r)=>(out[r.result.phase]=(out[r.result.phase]||0)+1,out),{}),
      timeoutsOrCrashes:negative.filter(r=>!accepted(r)&&!rejected(r)).map(r=>r.id)},
    positiveCheckingFailureGroups:Object.entries(failureGroups).map(([reason,ids])=>({reason,count:ids.length,ids})).sort((a,b)=>b.count-a.count),
    positiveExecutionFailureGroups:Object.values(executionGroups).map(g=>({...g,count:g.ids.length})).sort((a,b)=>b.count-a.count),
    exactLanes:Object.fromEntries([...new Set(rows.map(r=>r.lane))].map(lane=>[lane,rows.filter(r=>r.lane===lane).reduce((out,r)=>(out[r.status||r.result?.status||'unknown']=(out[r.status||r.result?.status||'unknown']||0)+1,out),{})])),
    note:'Proof-trust refusals are separate from type rejection and do not claim Lean kernel validation. Accepted Error expectations require phase-specific triage. Rejections with different diagnostics are not exact conformance passes.'
  };
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  const file=process.argv[2];
  if(!file)throw Error('Usage: semantic-summary.mjs REPORT.json|PROGRESS.jsonl');
  const text=fs.readFileSync(file,'utf8'),report=file.endsWith('.jsonl')?null:JSON.parse(text),rows=report?report.results:text.trim().split('\n').filter(Boolean).map(line=>JSON.parse(line));
  console.log(JSON.stringify(semanticSummary(rows,report?.inventory?.tests),null,2));
}
