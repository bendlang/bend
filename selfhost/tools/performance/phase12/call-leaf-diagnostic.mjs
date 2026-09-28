// Bounded same-source diagnostic, not a controlled final performance claim.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyIdentity,verifyAttempt,validatedCache} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [ablationArg,leafArg,attemptArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);
fs.mkdirSync(out);
const am=JSON.parse(fs.readFileSync(path.join(ablationArg,'manifest.json'))),lm=JSON.parse(fs.readFileSync(path.join(leafArg,'manifest.json')));
const attempt=await verifyAttempt(path.resolve(attemptArg));
const source=JSON.parse(fs.readFileSync(attempt.bootstrapReport.file)).source;
const variants={A:am.variants.find(x=>x.name==='A'),leaf:lm.variants.find(x=>x.name==='leaf')};
const worker=path.join(out,'check-worker.mjs');fs.copyFileSync(new URL('../phase8/check-worker.mjs',import.meta.url),worker);
fs.copyFileSync(import.meta.filename,path.join(out,path.basename(import.meta.filename)));
const inputMap=new Map(),add=file=>{const item=identity(file);inputMap.set(item.file,item);return item};
for(const file of [import.meta.filename,worker,process.execPath,source,path.join(ablationArg,'manifest.json'),path.join(leafArg,'manifest.json'),path.join(attemptArg,'attempt.json'),attempt.checkedApi.file,attempt.bootstrapReport.file,attempt.runtime.file,attempt.base.file])add(file);
for(const v of Object.values(variants)){
 verifyIdentity(v.api);add(v.api.file);
 v.cache=validatedCache(path.join(path.dirname(v.api.file),'build/typed/cache'),v.api.file,attempt.base.file);add(v.cache.file);
 for(const name of ['typed-driver.mjs','compiler-abi.mjs','conformance/adapters/typed.mjs'])add(path.join(path.dirname(v.host),name));
}
for(const i of attempt.snapshot.sources)add(i.frozen.file);
const report={kind:'phase12-leaf-full-source-diagnostic',complete:false,pass:false,inputs:[...inputMap.values()],source:identity(source),variants,rows:[],plannedOrder:['A','leaf'],scope:'CPU3, Node24,4MiBstack4GiBheap, validated private Base caches, same frozen final source. Concurrent team jobs may exist; no final performance claim. If initial request ratio is within 10%, add leaf,A reverse order to decide whether complexity is earned.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(let index=0;index<report.plannedOrder.length;index++){
  report.inputs.forEach(verifyIdentity);const name=report.plannedOrder[index],v=variants[name],prefix=path.join(out,`${index}-${name}`),workdir=prefix+'-work';fs.mkdirSync(workdir);
  const request={variant:name,source,api:v.api.file,base:attempt.base.file,runtime:attempt.runtime.file,upstream:attempt.config.upstream,workdir,timeoutMs:180000,adapter:path.join(path.dirname(v.host),'conformance/adapters/typed.mjs'),inputs:report.inputs};
  const req=prefix+'.request.json',res=prefix+'.result.json';fs.writeFileSync(req,JSON.stringify(request,null,2)+'\n',{flag:'wx'});
  const execution=await supervise('taskset',['-c','3',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,req,res],{directory:prefix+'-process',env:process.env,timeoutMs:180000});
  const row={name,execution,observation:fs.existsSync(res)?JSON.parse(fs.readFileSync(res)):null};report.rows.push(row);save();requireExecution(execution);assert.equal(row.observation.pass,true);assert.equal(row.observation.inputsVerified,true);assert.equal(row.observation.affinity.split(':')[1].trim(),'3');report.inputs.forEach(verifyIdentity);
  console.log(JSON.stringify({name,requestMs:row.observation.requestMs,processMs:execution.wallMs,pass:true}));
  if(index===1){const ratio=report.rows[0].observation.requestMs/report.rows[1].observation.requestMs;report.initialRatio=ratio;if(ratio>=0.9&&ratio<=1.1)report.plannedOrder.push('leaf','A');save();}
 }
 const sets=report.rows.map(r=>[...r.observation.result.unsafeDefinitions].sort());assert.ok(sets.every(s=>JSON.stringify(s)===JSON.stringify(sets[0])));report.unsafeDefinitionSetsAgree=true;
 report.statistics=Object.fromEntries(Object.keys(variants).map(name=>{const rows=report.rows.filter(r=>r.name===name);return[name,{samples:rows.length,meanRequestMs:rows.reduce((s,r)=>s+r.observation.requestMs,0)/rows.length,meanProcessMs:rows.reduce((s,r)=>s+r.execution.wallMs,0)/rows.length}]}));
 report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
save();
