// Preparation and exclusive warmed-once measurement are separate root grants.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {supervise,requireExecution} from '../../development/process.mjs';
const [planFile,mode,outArg,preparedFile]=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile)),out=path.resolve(outArg);
assert.ok(['prepare','measure'].includes(mode));assert.equal(p.kind,'phase30-warmed-generated-compiler-cost-plan');assert.equal(p.complete,true);
assert.equal(p.warmRequests,1);assert.equal(p.timedRequests,2);assert.equal(p.timeoutMs,90000);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const inputs=[...p.inputs,identity(planFile),identity(import.meta.filename)];
const verify=()=>{for(const item of inputs)assert.deepEqual(identity(item.file),{file:fs.realpathSync(item.file),sha256:item.sha256,bytes:item.bytes})};
let prepared;
if(mode==='measure'){prepared=JSON.parse(fs.readFileSync(preparedFile));assert.equal(prepared.complete,true);assert.equal(prepared.pass,true);assert.equal(prepared.mode,'prepare');assert.equal(prepared.plan.sha256,identity(planFile).sha256);inputs.push(identity(preparedFile));for(const row of prepared.rows)inputs.push(row.resultIdentity,row.observation.cache.after)}
const report={kind:'phase30-warmed-generated-compiler-cost',complete:false,pass:false,mode,plan:identity(planFile),inputs,rows:[],scope:p.scope,
 boundaries:{request:'D.inspect library with one already loaded API; normal source/check/emission/cache processing and real ABI conversion included.',excluded:'Imports, API/ABI validation, Base preparation, output verification/persistence; warm request separately reported.',sampling:'Three alternating fresh-process trials per side, one warm and two timed requests. No steady-state claim.'}};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));
const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(key))delete env[key];
try{
 verify();assert.equal(identity(process.execPath).sha256,p.node.sha256);
 const rounds=mode==='prepare'?[['checked_parent','generated_h']]:p.order;
 for(let trial=0;trial<rounds.length;trial++)for(const variant of rounds[trial]){
  verify();const directory=path.join(out,trial+'-'+variant);fs.mkdirSync(directory);
  const req=path.join(directory,'request.json'),result=path.join(directory,'result.json');
  const request={plan:p,variant,mode:mode==='prepare'?'prepare':'trial',prepared:mode==='measure'?prepared.rows.find(x=>x.variant===variant).observation:null};
  fs.writeFileSync(req,JSON.stringify(request,null,2)+'\n',{flag:'wx'});
  const cpu=mode==='prepare'?p.prepareCpu:p.cpu;
  const execution=await supervise('taskset',['-c',cpu,process.execPath,...p.nodeArgs,p.worker.file,req,result],{directory:path.join(directory,'process'),env,timeoutMs:p.timeoutMs});
  const observation=fs.existsSync(result)?JSON.parse(fs.readFileSync(result)):null;
  const row={trial,variant,execution,observation,resultIdentity:fs.existsSync(result)?identity(result):null};report.rows.push(row);save();requireExecution(execution);
  assert.equal(observation?.complete,true);assert.equal(observation.pass,true);assert.equal(observation.affinity.split(':')[1].trim(),cpu);verify();
 }
 if(mode==='measure'){
  report.statistics={};for(const variant of ['checked_parent','generated_h']){
   const rows=report.rows.filter(x=>x.variant===variant);assert.equal(rows.length,3);
   const values=rows.map(x=>x.observation.meanRequestMs),sorted=[...values].sort((a,b)=>a-b);
   report.statistics[variant]={medianMs:sorted[1],minMs:sorted[0],maxMs:sorted[2],trialMeanMs:values,withinTrialPercent:rows.map(x=>x.observation.secondVsFirstPercent)};
  }
  report.hOverParent=report.statistics.generated_h.medianMs/report.statistics.checked_parent.medianMs;
 }else assert.deepEqual(report.rows[0].observation.observation,report.rows[1].observation.observation);
 verify();report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,mode,hOverParent:report.hOverParent,error:report.error}));
