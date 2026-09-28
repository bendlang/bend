// Concurrent diagnostic screen; the final controlled matrix belongs to root.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {verifyAttempt,identity,verifyIdentity,validatedCache} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [baselineArg,seedArg,delayedArg,outArg,orderArg='baseline,seed,delayed']=process.argv.slice(2);
const paths={baseline:path.resolve(baselineArg),seed:path.resolve(seedArg),delayed:path.resolve(delayedArg)},attempts={};
for(const [name,dir] of Object.entries(paths))attempts[name]=await verifyAttempt(dir);
assert.equal(attempts.baseline.api.sha256,'63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f');
const order=orderArg.split(',');assert.deepEqual([...order].sort(),['baseline','delayed','seed']);
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const worker=path.join(out,'worker.mjs'),originalWorker=path.resolve(import.meta.dirname,'../phase8/check-worker.mjs');
fs.copyFileSync(originalWorker,worker);
const source=JSON.parse(fs.readFileSync(attempts.baseline.bootstrapReport.file)).source;
const inputs=new Map(),add=file=>{const item=identity(file);inputs.set(item.file,item);return item;};
for(const file of [import.meta.filename,process.execPath,worker,originalWorker,source])add(file);
const variants={};
for(const [name,m] of Object.entries(attempts)){
 assert.equal(m.base.sha256,attempts.baseline.base.sha256);assert.equal(m.runtime.sha256,attempts.baseline.runtime.sha256);
 for(const file of ['typed-driver.mjs','compiler-abi.mjs','conformance/adapters/typed.mjs'])assert.equal(identity(path.join(m.snapshot.root,'tools',file)).sha256,identity(path.join(attempts.baseline.snapshot.root,'tools',file)).sha256);
 const cache=validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
 variants[name]={attempt:add(path.join(paths[name],'attempt.json')),api:m.api,cache,artifactKind:m.artifactKind};
 for(const i of [m.api,m.base,m.runtime,cache,m.bootstrapReport,...m.artifacts,...m.snapshot.sources.map(x=>x.frozen)])add(i.file);
}
for(const name of ['bend.ts','comp.ts','main.ts','base.bend'])add(path.join(attempts.baseline.config.upstream,'bend2',name));
const report={kind:'phase12-normalizer-full-source-diagnostic',complete:false,pass:false,order,cpu:'2',source:identity(source),variants,inputs:[...inputs.values()],rows:[],
 scope:'Same immutable Phase11 source and unchanged check-worker. One fresh process per variant; concurrent development on other CPUs. Directional screen, not a final controlled speed ratio. No emission.',
 timingBoundary:'Adapter request includes lazy API import. Process wall includes startup, hash verification, output capture. Existing separately verified Base caches; OS caches not flushed.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
const verify=()=>report.inputs.forEach(verifyIdentity);save();
try{
 for(const [index,name] of order.entries()){
  verify();const m=attempts[name],prefix=path.join(out,index+'-'+name),workdir=prefix+'-work';fs.mkdirSync(workdir);
  const request={variant:name,source,api:m.api.file,base:m.base.file,runtime:m.runtime.file,upstream:m.config.upstream,workdir,timeoutMs:180000,adapter:path.join(m.snapshot.root,'tools/conformance/adapters/typed.mjs'),inputs:report.inputs};
  const requestFile=prefix+'.request.json',resultFile=prefix+'.result.json';fs.writeFileSync(requestFile,JSON.stringify(request,null,2)+'\n',{flag:'wx'});
  const execution=await supervise('taskset',['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,requestFile,resultFile],{directory:prefix+'-process',env:process.env,timeoutMs:180000});
  const observation=fs.existsSync(resultFile)?JSON.parse(fs.readFileSync(resultFile)):null;
  report.rows.push({index,variant:name,execution,observation});save();requireExecution(execution);assert.equal(observation.pass,true);assert.equal(observation.affinity.split(':')[1].trim(),'2');verify();
  console.log(JSON.stringify({variant:name,pass:observation.pass,wallMs:execution.wallMs,requestMs:observation.requestMs,maxRssKiB:observation.maxRssKiB}));
 }
 const sets=report.rows.map(r=>[...r.observation.result.unsafeDefinitions].sort());
 report.unsafeDefinitionSetsAgree=sets.every(x=>JSON.stringify(x)===JSON.stringify(sets[0]));assert.ok(report.unsafeDefinitionSetsAgree);
 report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
save();
