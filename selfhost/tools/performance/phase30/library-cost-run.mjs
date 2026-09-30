// Exclusive serial CPU0 samples of normal checked-library compilation.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {supervise,requireExecution} from '../../development/process.mjs';
const [configFile,outArg]=process.argv.slice(2),config=JSON.parse(fs.readFileSync(configFile)),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
assert.equal(config.complete,true);assert.equal(config.cpu,'0');assert.equal(config.samples,3);assert.equal(config.timeoutMs,180000);
assert.deepEqual(identity(process.execPath),config.node);assert.deepEqual(config.order,['typescript','phase29','candidate']);
const inputs=[...config.inputs,identity(configFile),identity(import.meta.filename)];
const verify=()=>{for(const item of inputs)assert.deepEqual(identity(item.file),item,'Changed input '+item.file)};
const report={kind:'phase30-checked-library-compilation-cost',complete:false,pass:false,started:new Date().toISOString(),
 inputs,config:identity(configFile),scope:config.scope,rows:[],statistics:{},
 boundaries:{request:'TS book_nil/load/valid/js_lib or Bend default inspect library; normal Base pipeline included.',
  hostImport:'Explicit bend.ts/comp.ts or typed-driver import, outside request. Bend API lazy loading stays in request.',
  importAndRequest:'Sum of compiler host import and its normal checked-library request.',
  processWall:'Supervised child includes Node startup, preflight, request, persisted output and postflight.'}};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'),fs.constants.COPYFILE_EXCL);save();
const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];
const start=performance.now();
try{
 verify();
 for(const c of config.cases)for(let sample=0;sample<3;sample++){
  const order=config.order.slice(sample).concat(config.order.slice(0,sample));
  for(const name of order){
   verify();const v=config.variants[name],prefix=path.join(out,c.id+'-'+sample+'-'+name);
   const request={variant:name,typescript:v.typescript,source:c.source,expected:c.expected[name],attempt:v.attempt,api:v.api,
    cache:v.cache,verifier:v.verifier.file,driver:v.driver,upstream:v.upstream,inputs,output:prefix+'.mjs'};
   const req=prefix+'.request.json',result=prefix+'.result.json';fs.writeFileSync(req,JSON.stringify(request,null,2)+'\n',{flag:'wx'});
   const execution=await supervise('taskset',['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096',config.worker.file,req,result],{directory:prefix+'-process',env,timeoutMs:180000});
   const observation=fs.existsSync(result)?JSON.parse(fs.readFileSync(result)):null;
   const row={source:c.id,sample,variant:name,execution,observation};report.rows.push(row);save();requireExecution(execution);
   assert.equal(observation?.pass,true);assert.equal(observation.complete,true);
   assert.equal(observation.affinity.split(':')[1].trim(),'0');assert.equal(observation.output.sha256,c.expected[name].sha256);
   assert.deepEqual(identity(observation.output.file),Object.fromEntries(Object.entries(observation.output).filter(([k])=>k!=='bytes')));
   verify();save();console.log(JSON.stringify({source:c.id,sample,variant:name,requestMs:observation.requestMs,hostImportMs:observation.hostImportMs,importAndRequestMs:observation.importAndRequestMs,processMs:execution.wallMs}));
  }
 }
 const stats=values=>{const sorted=[...values].sort((a,b)=>a-b);return {median:sorted[1],min:sorted[0],max:sorted[2],samples:values}};
 for(const c of config.cases){
  report.statistics[c.id]={};for(const name of config.order){
   const rows=report.rows.filter(r=>r.source===c.id&&r.variant===name);assert.equal(rows.length,3);
   report.statistics[c.id][name]={requestMs:stats(rows.map(r=>r.observation.requestMs)),hostImportMs:stats(rows.map(r=>r.observation.hostImportMs)),
    importAndRequestMs:stats(rows.map(r=>r.observation.importAndRequestMs)),processWallMs:stats(rows.map(r=>r.execution.wallMs)),maxRssKiB:stats(rows.map(r=>r.observation.maxRssKiB))};
  }
 }
 verify();report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
report.finished=new Date().toISOString();report.wallMs=performance.now()-start;save();
