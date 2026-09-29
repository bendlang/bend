import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [baselineArg,candidateArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const attempts={baseline:fs.realpathSync(baselineArg),candidate:fs.realpathSync(candidateArg)},m={};
for(const [name,dir]of Object.entries(attempts))m[name]=await verifyAttempt(dir);
assert.equal(m.baseline.base.sha256,m.candidate.base.sha256);assert.equal(m.baseline.runtime.sha256,m.candidate.runtime.sha256);
assert.equal(m.baseline.config.upstream,m.candidate.config.upstream);
const source=JSON.parse(fs.readFileSync(m.candidate.bootstrapReport.file)).source;
const worker=path.join(out,'worker.mjs');fs.copyFileSync(new URL('./stage-worker.mjs',import.meta.url),worker);
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const inputs=new Map(),add=file=>{const i=identity(file);inputs.set(i.file,i);return i;};
for(const file of [import.meta.filename,worker,process.execPath,source])add(file);
const variants={};
for(const [name,manifest]of Object.entries(m)){
 const W=await import(pathToFileURL(path.join(manifest.snapshot.root,'tools/development/workflow.mjs')));
 const cache=W.validatedCache(path.join(manifest.snapshot.root,'build/typed/cache'),manifest.api.file,manifest.base.file);
 variants[name]={attempt:add(path.join(attempts[name],'attempt.json')),api:manifest.api,cache};
 for(const i of [manifest.api,manifest.base,manifest.runtime,manifest.bootstrapReport,cache,...manifest.snapshot.sources.map(x=>x.frozen)])add(i.file);
}
const report={complete:false,pass:false,kind:'phase16-diagnostic-stage-attribution',variants,source:identity(source),inputs:[...inputs.values()],order:['baseline','candidate','candidate','baseline'],rows:[],scope:'Instrumented ordinary host inspect, API loading and public compiler calls; API internals unchanged. Exclusive CPU0 with validated caches. Uninstrumented matrices remain the speed authority.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(const [index,variant]of report.order.entries()){
  report.inputs.forEach(verifyIdentity);const a=m[variant],prefix=path.join(out,`${index}-${variant}`);
  const request={variant,source,api:a.api.file,base:a.base.file,runtime:a.runtime.file,upstream:a.config.upstream,host:path.join(a.snapshot.root,'tools/typed-driver.mjs'),inputs:report.inputs};
  const requestFile=prefix+'.request.json',resultFile=prefix+'.result.json';fs.writeFileSync(requestFile,JSON.stringify(request,null,2)+'\n');
  const execution=await supervise('taskset',['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,requestFile,resultFile],{directory:prefix+'-process',env:process.env,timeoutMs:600000});
  const observation=fs.existsSync(resultFile)?JSON.parse(fs.readFileSync(resultFile)):null;report.rows.push({index,variant,execution,observation});save();requireExecution(execution);assert.equal(observation.pass,true);assert.equal(observation.affinity.split(':')[1].trim(),'0');
 }
 const sets=report.rows.map(r=>r.observation.result.unsafeDefinitions.slice().sort());assert(sets.every(x=>JSON.stringify(x)===JSON.stringify(sets[0])));
 const sum=rs=>rs.reduce((a,b)=>a+b,0),mean=rs=>sum(rs)/rs.length;
 report.means={};for(const variant of ['baseline','candidate']){
  const rows=report.rows.filter(r=>r.variant===variant).map(r=>r.observation),names=[...new Set(rows.flatMap(r=>Object.keys(r.calls)))];
  report.means[variant]={requestMs:mean(rows.map(r=>r.requestMs)),apiLoadMs:mean(rows.map(r=>r.apiLoadMs)),compilerApiMs:mean(rows.map(r=>r.compilerApiMs)),hostAndInstrumentationMs:mean(rows.map(r=>r.hostAndInstrumentationMs)),calls:Object.fromEntries(names.map(n=>[n,{count:mean(rows.map(r=>r.calls[n]?.count??0)),ms:mean(rows.map(r=>r.calls[n]?.ms??0))}]))};
 }
 report.inputs.forEach(verifyIdentity);for(const dir of Object.values(attempts))await verifyAttempt(dir);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));
