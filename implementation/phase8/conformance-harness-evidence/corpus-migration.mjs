#!/usr/bin/env node
// Phase8 U2: direct gate paths, exact source hashes, then current-target results.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {semanticSummary} from '../../../selfhost/tools/conformance/semantic-summary.mjs';
const [oldRoot,newRoot,outputFile,candidateFile]=process.argv.slice(2);
if(!outputFile)throw Error('Usage: corpus-migration.mjs OLD_CHECKOUT NEW_CHECKOUT OUTPUT [CANDIDATE_REPORT]');
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
function discover(root){
  const tests=path.resolve(root,'tests'),files=[];
  for(const ns of fs.readdirSync(tests,{withFileTypes:true}).filter(d=>d.isDirectory())){
    for(const file of fs.readdirSync(path.join(tests,ns.name),{withFileTypes:true}).filter(f=>f.isFile()&&f.name.endsWith('.bend'))){
      const id=ns.name+'/'+file.name,bytes=fs.readFileSync(path.join(tests,id));
      files.push({id,sha256:sha(bytes),bytes:bytes.length});
    }
  }
  return new Map(files.sort((a,b)=>a.id.localeCompare(b.id)).map(f=>[f.id,f]));
}
const old=discover(oldRoot),current=discover(newRoot),added=[],removed=[],common=[];
for(const [id,file] of current){const prior=old.get(id);if(!prior)added.push(file);else common.push({id,oldSha256:prior.sha256,newSha256:file.sha256,changed:prior.sha256!==file.sha256});}
for(const [id,file] of old)if(!current.has(id))removed.push(file);
const byNamespace=files=>files.reduce((a,f)=>(a[f.id.split('/')[0]]=(a[f.id.split('/')[0]]??0)+1,a),{});
const out={
  method:'The gate discovers tests/<namespace>/*.bend only. Nested .bend support modules are not fixtures. Identity is the exact relative fixture path; source changes are separately hashed.',
  checkouts:{old:path.resolve(oldRoot),current:path.resolve(newRoot)},
  counts:{old:old.size,current:current.size,added:added.length,removed:removed.length,common:common.length,commonChanged:common.filter(f=>f.changed).length,commonUnchanged:common.filter(f=>!f.changed).length},
  addedByNamespace:byNamespace(added),removedByNamespace:byNamespace(removed),added,removed,common,
  limitation:'Results below, when present, use the new target only. Common paths, including byte-identical fixture sources, do not establish old-target compatibility because libraries/compiler semantics can differ.'
};
if(candidateFile){
  const bytes=fs.readFileSync(candidateFile),report=JSON.parse(bytes);
  if(!report.finished||report.changedInputs.length||report.identity.changedArtifacts.length||report.identity.adapterChangedDuringRun||report.results.length!==current.size*2)throw Error('Candidate frontend must be complete and unchanged');
  if(report.inventory.tests.length!==current.size||report.inventory.tests.some(f=>current.get(f.id)?.sha256!==f.sha256))throw Error('Candidate fixture hashes differ from the new inventory');
  const buckets={added:new Set(added.map(f=>f.id)),common:new Set(common.map(f=>f.id)),commonChanged:new Set(common.filter(f=>f.changed).map(f=>f.id)),commonUnchanged:new Set(common.filter(f=>!f.changed).map(f=>f.id))};
  out.candidate={file:path.resolve(candidateFile),sha256:sha(bytes),revision:report.inventory.revision};
  out.currentTargetOutcomes=Object.fromEntries(Object.entries(buckets).map(([name,ids])=>{
    const fixtures=report.inventory.tests.filter(f=>ids.has(f.id)),rows=report.results.filter(r=>ids.has(r.id));
    return [name,{fixtures:fixtures.length,...semanticSummary(rows,fixtures)}];
  }));
}
fs.writeFileSync(outputFile,JSON.stringify(out,null,2)+'\n');
console.log(JSON.stringify(out.counts,null,2));
