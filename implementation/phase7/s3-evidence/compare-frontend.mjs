// Compare the full behavioral observations; audit differing host identities separately.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {observationHealth} from '../../../selfhost/tools/development/workflow.mjs';
const [beforeFile,afterFile,out]=process.argv.slice(2);
const hash=data=>createHash('sha256').update(data).digest('hex');
const read=file=>JSON.parse(fs.readFileSync(file));
const old=read(beforeFile),current=read(afterFile);
const key=row=>row.id+'::'+row.lane;
const report={kind:'S3-full-frontend-preservation',complete:false,pass:false,
  scope:'All result fields except separately verified hostProvenance; exact status/reason/evidence and fixture identities. No diagnostic normalization.',
  inputs:[beforeFile,afterFile,import.meta.filename].map(file=>({file:path.resolve(file),sha256:hash(fs.readFileSync(file))})),differences:[]};
const save=()=>fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');save();
try{
  for(const raw of [old,current]){
    assert.ok(observationHealth(raw),'Incomplete infrastructure observations');
    assert.equal(raw.inventory.total,1378);assert.equal(raw.results.length,2756);
    assert.equal(new Set(raw.results.map(key)).size,2756);
    assert.equal(raw.workers.length,2);
    assert.ok(raw.workers.every(w=>w.stats.failures===0&&w.stats.timeouts===0));
    for(const row of raw.results){
      const provenance=row.result.hostProvenance;
      assert.equal(provenance.driverSha256,raw.identity.artifacts.driver.sha256);
      assert.equal(provenance.adapterSha256,raw.identity.adapterSha256);
    }
  }
  assert.deepEqual(current.inventory.tests.map(t=>[t.id,t.sha256]),old.inventory.tests.map(t=>[t.id,t.sha256]));
  assert.deepEqual(current.inputHashes,old.inputHashes);assert.deepEqual(current.inputPaths,old.inputPaths);
  assert.equal(current.identity.artifacts.base.sha256,old.identity.artifacts.base.sha256);
  assert.equal(current.identity.artifacts.runtime.sha256,old.identity.artifacts.runtime.sha256);
  assert.equal(current.identity.adapterSha256,old.identity.adapterSha256);
  const before=new Map(old.results.map(row=>[key(row),row]));
  for(const row of current.results){
    const prior=before.get(key(row));assert.ok(prior);
    const {hostProvenance:oldIdentity,...a}=prior.result;
    const {hostProvenance:newIdentity,...b}=row.result;
    try{assert.deepEqual(b,a);for(const field of ['status','reason','evidence'])assert.deepEqual(row[field],prior[field]);}
    catch(error){report.differences.push({key:key(row),before:prior,after:row,error:error.message});}
  }
  report.counts={observations:current.results.length,positiveCheck:current.results.filter(r=>r.lane==='check'&&!r.negative).length,
    negativeCheck:current.results.filter(r=>r.lane==='check'&&r.negative).length,
    strictCheckFailures:current.results.filter(r=>r.lane==='check'&&r.status==='fail').length};
  report.summaries={before:old.summary,after:current.summary};
  report.artifacts={before:old.identity.artifacts,after:current.identity.artifacts};
  report.workerStats={before:old.workers,after:current.workers};
  report.complete=true;report.pass=report.differences.length===0;
}catch(error){report.error=error.stack;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,counts:report.counts,differences:report.differences.length,error:report.error}));
if(!report.pass)process.exitCode=1;
