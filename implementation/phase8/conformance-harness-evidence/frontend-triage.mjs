#!/usr/bin/env node
// Reproduce semantic triage from complete raw vectors. Exact comparison remains
// a separate prerequisite; no diagnostic/path/exit fields are normalized here.
import fs from 'node:fs';
import crypto from 'node:crypto';
const [referenceFile,candidateFile,outputFile]=process.argv.slice(2);
if(!outputFile)throw Error('Usage: frontend-triage.mjs REFERENCE CANDIDATE OUTPUT');
const read=file=>({file,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex'),report:JSON.parse(fs.readFileSync(file,'utf8'))});
const reference=read(referenceFile),candidate=read(candidateFile);
for(const x of [reference,candidate]){
  const r=x.report;
  if(!r.finished||r.changedInputs.length||r.identity.changedArtifacts.length||r.identity.adapterChangedDuringRun)throw Error('Incomplete or changed report: '+x.file);
  if(r.results.length!==r.inventory.total*2)throw Error('Expected every parse/check observation: '+x.file);
  if(r.workers?.some(w=>w.errors?.length))throw Error('Worker errors: '+x.file);
}
const maps=[reference,candidate].map(x=>new Map(x.report.results.filter(r=>r.lane==='check').map(r=>[r.id,r])));
const fixtures=reference.report.inventory.tests;
if(maps.some(m=>m.size!==fixtures.length))throw Error('Missing or duplicate check observations');
const accepted=r=>r.result?.checked===true&&r.result.typeAccepted===true;
const refusal=r=>r.result?.status==='error'&&!accepted(r);
const trustRefusal=r=>accepted(r)&&r.result.status==='error'&&r.result.phase==='verdict'&&r.result.proofTrust==='failed';
const counts=xs=>xs.reduce((a,x)=>(a[x]=(a[x]??0)+1,a),{});
const pairs=fixtures.map(f=>{const a=maps[0].get(f.id),b=maps[1].get(f.id);if(!a||!b)throw Error('Missing fixture '+f.id);return {fixture:f,reference:a,candidate:b}});
const compact=p=>({id:p.fixture.id,status:p.candidate.status,phase:p.candidate.result?.phase,typeAccepted:p.candidate.result?.typeAccepted,proofTrust:p.candidate.result?.proofTrust,exitCode:p.candidate.result?.exitCode,diagnostic:p.candidate.result?.diagnostic});
const select=fn=>pairs.filter(p=>fn(p.fixture));
const positive=select(f=>!f.negative),validation=select(f=>f.failureKind==='validation'),deferred=select(f=>f.failureKind==='error'),trust=select(f=>f.failureKind==='proof-trust');
if(positive.length+validation.length+deferred.length+trust.length!==fixtures.length)throw Error('Unclassified fixtures');
const out={
  inputs:[reference,candidate].map(({file,sha256})=>({file,sha256})),fixtureCount:fixtures.length,
  positive:{total:positive.length,referenceAccepted:positive.filter(p=>accepted(p.reference)).length,candidateAccepted:positive.filter(p=>accepted(p.candidate)).length,
    notTypeAccepted:positive.filter(p=>!accepted(p.candidate)).map(compact),laterRefusals:positive.filter(p=>accepted(p.candidate)&&p.candidate.result.status!=='ok').map(compact)},
  validationNegative:{total:validation.length,referenceRefused:validation.filter(p=>refusal(p.reference)).length,candidateRefused:validation.filter(p=>refusal(p.candidate)).length,
    unexpectedTypeAcceptance:validation.filter(p=>accepted(p.candidate)&&!accepted(p.reference)).map(compact),unresolved:validation.filter(p=>!accepted(p.candidate)&&!refusal(p.candidate)).map(compact),
    refusalPhases:counts(validation.filter(p=>refusal(p.candidate)).map(p=>p.candidate.result.phase))},
  deferredErrors:{total:deferred.length,referenceTypeAccepted:deferred.filter(p=>accepted(p.reference)).map(p=>p.fixture.id),candidateTypeAccepted:deferred.filter(p=>accepted(p.candidate)).map(p=>p.fixture.id),
    unexpected:deferred.filter(p=>accepted(p.candidate)!==accepted(p.reference)).map(compact),note:'Frontend type acceptance alone does not demonstrate the expected later compile refusal; execution controls remain separate evidence.'},
  proofTrust:{total:trust.length,referenceRefusals:trust.filter(p=>trustRefusal(p.reference)).length,candidateTypeAccepted:trust.filter(p=>accepted(p.candidate)).length,
    candidateRefusals:trust.filter(p=>trustRefusal(p.candidate)).length,exactPasses:trust.filter(p=>p.candidate.status==='pass').length,unmatched:trust.filter(p=>p.candidate.status!=='pass').map(compact),kernelChecked:false},
  exactCheckStatuses:counts(pairs.map(p=>p.candidate.status)),
  note:'Semantic acceptance/refusal counts are distinct from exact fixture passes. Timeouts establish neither acceptance nor rejection. No proof kernel has been run.'
};
fs.writeFileSync(outputFile,JSON.stringify(out,null,2)+'\n');
console.log(JSON.stringify(out,null,2));
