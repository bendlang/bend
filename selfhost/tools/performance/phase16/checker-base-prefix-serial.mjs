import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../../../..'),out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const helper=await import(pathToFileURL(path.join(root,'selfhost/build/phase16/checker-base-prefix-source-03/project/tools/development/workflow.mjs')));
const {identity,verifyIdentity,verifyAttempt,validatedCache}=helper;
const {supervise,requireExecution}=await import('../../development/process.mjs');
const attempt=path.join(root,'selfhost/build/phase16/checker-base-prefix-build-03'),m=await verifyAttempt(attempt);
const cache=validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
const matrix=JSON.parse(fs.readFileSync(path.join(root,'selfhost/build/phase16/stage-matrix-01/report.json'))),source=matrix.source.file;
verifyIdentity(matrix.source);
const countedApi=path.join(root,'selfhost/build/phase16/checker-base-prefix-proof-03/counted-api.mjs'),worker=path.join(import.meta.dirname,'checker-base-prefix-serial-worker.mjs'),host=path.join(m.snapshot.root,'tools/typed-driver.mjs');
const inputs=[import.meta.filename,worker,process.execPath,host,path.join(m.snapshot.root,'tools/compiler-abi.mjs'),path.join(m.snapshot.root,'tools/node-resource-args.mjs'),path.join(m.snapshot.root,'src/compiler.json'),m.api.file,countedApi,m.base.file,m.runtime.file,cache.file,source,path.join(root,'design/phase16/checker-base-prefix-serial.md'),path.join(root,'selfhost/build/phase16/checker-base-prefix-proof-03/report.json')].map(identity);
const report={kind:'phase16-serial-whole-compiler-base-prefix-law',complete:false,pass:false,installationEligible:false,inputs,rows:[],scope:'Separate full/split workers; complete canonical JSON book hash and next/error equality; instrumented operation counts only, no speed ratio.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(const mode of ['full','split']){
  inputs.forEach(verifyIdentity);const request={mode,inputs,originalApi:m.api.file,countedApi,base:m.base.file,runtime:m.runtime.file,upstream:m.config.upstream,cache:cache.file,host,source};
  const requestFile=path.join(out,mode+'.request.json'),result=path.join(out,mode+'.result.json');fs.writeFileSync(requestFile,JSON.stringify(request,null,2)+'\n');
  const execution=await supervise('taskset',['-c','1',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,requestFile,result],{env:process.env,directory:path.join(out,mode+'-process'),timeoutMs:180000,maxBytes:2**20});
  const row={mode,execution};report.rows.push(row);save();requireExecution(execution);row.result=JSON.parse(fs.readFileSync(result));assert(row.result.pass);save();
 }
 const [a,b]=report.rows.map(x=>x.result);assert.deepEqual(a.output,b.output);assert.equal(a.next,b.next);assert.equal(a.error,b.error);assert.deepEqual(a.outputCensus,b.outputCensus);
 report.output=a.output;report.next=a.next;report.removedFreshVisits=a.freshCounts.ffw_walk-b.freshCounts.ffw_walk;report.fullFreshVisits=a.freshCounts.ffw_walk;report.fractionRemoved=report.removedFreshVisits/report.fullFreshVisits;
 inputs.forEach(verifyIdentity);await verifyAttempt(attempt);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,output:report.output,next:report.next,removedFreshVisits:report.removedFreshVisits,fullFreshVisits:report.fullFreshVisits,fractionRemoved:report.fractionRemoved,error:report.error}));
