import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {makeFixtures} from './checker-fixtures.mjs';
const [planFile,role,workload,outFile]=process.argv.slice(2),plan=JSON.parse(fs.readFileSync(planFile));
const hash=p=>createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const started=performance.now(),report={kind:'phase32-checker-helper-timing',complete:false,pass:false,role,workload,observations:[],warm:[],calibration:[]};
try{
 for(const i of plan.inputs)assert.equal(hash(i.file),i.sha256);
 const artifact=plan.variants[role];assert.equal(hash(artifact.file),artifact.sha256);
 const m=await import(pathToFileURL(artifact.file)),fixture=makeFixtures(m,128);
 let outputs,run,expected;
 if(workload==='cached'||workload==='uncached'){
  const book=workload==='cached'?fixture.cached:fixture.book;
  outputs=Array(fixture.queries.length);expected=fixture.expected;
  run=()=>{let sum=0;for(let i=0;i<fixture.queries.length;i++){const value=m.checkerProbe.lookup(book,fixture.queries[i]);outputs[i]=value;sum=(sum+value.a[0].length+value.a[2])>>>0}return sum};
 }else{
  assert.equal(workload,'infer_ref');outputs=Array(fixture.infer.length);expected=fixture.infer.map(x=>x.expected);
  run=()=>{let sum=0;for(let i=0;i<fixture.infer.length;i++){const value=m.checkerProbe.infer_ref(...fixture.infer[i].args);outputs[i]=value;sum=(sum+value.a[3].length+value.a[5])>>>0}return sum};
 }
 const batch=count=>{let sink=0;const t=performance.now();for(let i=0;i<count;i++)sink=(sink+run())>>>0;return {count,ms:performance.now()-t,sink}};
 run();assert.deepEqual(outputs,expected);
 const expectedHash=createHash('sha256').update(JSON.stringify(expected)).digest('hex');
 let warmMs=0;while(warmMs<plan.warmMs){const r=batch(1);warmMs+=r.ms;report.warm.push(r);assert.ok(report.warm.length<100000,'warm-call ceiling')}
 let count=1;for(let i=0;i<12;i++){const r=batch(count);report.calibration.push(r);if(r.ms>=plan.targetMs/2)break;count=Math.min(100000,Math.max(count+1,Math.ceil(count*plan.targetMs/Math.max(r.ms,0.01))))}
 for(let sample=0;sample<plan.samples;sample++){
  const first=batch(Math.max(1,Math.floor(count/2))),second=batch(Math.max(1,Math.ceil(count/2)));
  assert.deepEqual(outputs,expected);
  report.observations.push({sample,first,second,count:first.count+second.count,ms:first.ms+second.ms,msPerBatch:(first.ms+second.ms)/(first.count+second.count),halfDriftPercent:100*((second.ms/second.count)/(first.ms/first.count)-1)});
 }
 for(const i of plan.inputs)assert.equal(hash(i.file),i.sha256);
 report.complete=true;report.pass=true;report.expectedHash=expectedHash;report.points=outputs.length;report.count=count;
 report.node=process.version;report.execArgv=process.execArgv;report.artifact=artifact;report.fixtureSize=128;
 report.memory=process.memoryUsage();report.resourceUsage=process.resourceUsage();report.status=fs.readFileSync('/proc/self/status','utf8').split('\n').filter(x=>/^(Cpus_allowed_list|VmHWM|VmRSS):/.test(x));
}catch(e){report.error=e.stack;process.exitCode=1}
report.wallMs=performance.now()-started;fs.writeFileSync(outFile,JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({role,workload,pass:report.pass,error:report.error}));
