// Cross-revision bundle checking: each variant retains its own Base and host.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {supervise,requireExecution} from '../../development/process.mjs';
const [configFile,outArg]=process.argv.slice(2),config=JSON.parse(fs.readFileSync(configFile));
const out=path.resolve(outArg);fs.mkdirSync(out);
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs=new Map(),add=file=>{const item=identity(file);inputs.set(item.file,item);return item;};
const manifests={},variants={};
for(const [name,v]of Object.entries(config.variants)){
  const attempt=JSON.parse(fs.readFileSync(path.join(v.attempt,'attempt.json')));
  const helper=await import(pathToFileURL(path.join(attempt.snapshot.root,'tools/development/workflow.mjs')));
  const m=await helper.verifyAttempt(v.attempt);manifests[name]=m;
  const upstream=v.upstream??m.config.upstream;
  const adapter=path.join(m.snapshot.root,'tools/conformance/adapters',v.typescript?'upstream.mjs':'typed.mjs');
  const cache=v.typescript?null:helper.validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
  variants[name]={typescript:!!v.typescript,attempt:add(path.join(v.attempt,'attempt.json')),api:m.api,
    upstream,base:add(path.join(upstream,'bend2/base.bend')),adapter:add(adapter),runtime:m.runtime,cache};
  for(const item of [m.api,m.runtime,m.base,m.bootstrapReport,...m.artifacts,...m.snapshot.sources.map(x=>x.frozen),...(cache?[cache]:[])])add(item.file);
  for(const file of ['bend.ts','comp.ts','main.ts','safe.ts','base.bend'])add(path.join(upstream,'bend2',file));
}
const worker=path.join(out,'worker.mjs');fs.copyFileSync(new URL('../phase8/check-worker.mjs',import.meta.url),worker);
for(const file of [configFile,import.meta.filename,worker,process.execPath,config.source])add(file);
const report={kind:'phase23-cross-revision-check-matrix',complete:false,started:new Date().toISOString(),
  source:identity(config.source),variants,inputs:[...inputs.values()],order:config.order,cpu:String(config.cpu??0),rows:[],
  scope:'Same frozen compiler source, each usable bundle with its own pinned Base and runtime. No emission. Fresh processes, validated Bend Base cache; TypeScript checks its Base. OS caches are not flushed.',
  timingBoundary:'Request wraps adapter.probe including lazy API loading. Process includes startup, identity hashing and output capture.',
  attribution:'Cross-revision workflow comparison, not isolated algorithm or Bend-source attribution. Host provenance must match actual driver/adapter; no other result fields excluded.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
const verify=()=>{for(const item of report.inputs)assert.deepEqual(identity(item.file),item);};
save();
try{
  for(const [i,name]of config.order.entries()){
    verify();const v=variants[name],m=manifests[name];assert.ok(v);
    const prefix=path.join(out,`${i}-${name}`),workdir=prefix+'-work';fs.mkdirSync(workdir);
    const request={variant:name,source:config.source,api:m.api.file,base:v.base.file,runtime:m.runtime.file,
      upstream:v.upstream,workdir,timeoutMs:180000,adapter:v.adapter.file,inputs:report.inputs};
    const req=prefix+'.request.json',result=prefix+'.result.json';fs.writeFileSync(req,JSON.stringify(request,null,2)+'\n',{flag:'wx'});
    const execution=await supervise('taskset',['-c',report.cpu,process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,req,result],{directory:prefix+'-process',env:process.env,timeoutMs:180000});
    const row={variant:name,execution,observation:fs.existsSync(result)?JSON.parse(fs.readFileSync(result)):null};report.rows.push(row);save();requireExecution(execution);
    assert.equal(row.observation.pass,true);assert.equal(row.observation.affinity.split(':')[1].trim(),report.cpu);
    const {hostProvenance,...observation}=row.observation.result;
    if(v.typescript)assert.equal(hostProvenance,undefined);
    else assert.deepEqual(hostProvenance,{driverSha256:identity(path.join(m.snapshot.root,'tools/typed-driver.mjs')).sha256,adapterSha256:v.adapter.sha256});
    if(i===0)report.programObservation=observation;
    else assert.deepEqual(observation,report.programObservation,'Entire program observation must agree');
    verify();save();console.log(name,execution.wallMs.toFixed(1)+'ms');
  }
  const mean=xs=>xs.reduce((a,b)=>a+b,0)/xs.length;
  report.statistics=Object.fromEntries(Object.keys(variants).map(name=>{const rows=report.rows.filter(r=>r.variant===name);return [name,{samples:rows.length,meanProcessWallMs:mean(rows.map(r=>r.execution.wallMs)),meanRequestMs:mean(rows.map(r=>r.observation.requestMs)),maxRssKiB:Math.max(...rows.map(r=>r.observation.maxRssKiB))}];}));
  report.complete=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
report.finished=new Date().toISOString();save();
