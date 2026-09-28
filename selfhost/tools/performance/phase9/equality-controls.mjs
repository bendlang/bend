// Paired actual checker/code-output controls; timings are descriptive, not a benchmark.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
import {verifyEqualityDerivation} from '../../development/equality.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [attemptArg,derivationArg,outArg,cpu='2']=process.argv.slice(2);
assert.match(cpu,/^\d+$/);
const attempt=fs.realpathSync(attemptArg),m=await verifyAttempt(attempt),derived=verifyEqualityDerivation(derivationArg),out=path.resolve(outArg);
assert.equal(m.checkedApi.sha256,derived.metadata.original.api.sha256);fs.mkdirSync(out);
const selected=JSON.parse(fs.readFileSync(path.join(attempt,'validation-001/selection.json'))).cases;
const cases=selected.map(x=>({...x,lane:'check'}));
for(const [name,accept]of [['alpha_equivalence',true],['beta_ann_body',false],['binder_name_capture',false]])cases.push({id:'check/'+name,file:path.join(m.config.upstream,'tests/check',name+'.bend'),lane:'check',accept,...accept?{}:{rejectPhase:'check'}});
for(const name of ['closures_hof','beta_nested_redex','string_algorithms']){
 const file=path.join(m.config.upstream,'tests/run',name+'.bend'),expected=fs.readFileSync(file,'utf8').split('\n').filter(x=>x.startsWith('#|')).map(x=>x.slice(2)).join('\n')+'\n';
 cases.push({id:'run/'+name,file,lane:'js',expected});
}
fs.copyFileSync(import.meta.filename,path.join(out,'equality-controls.mjs.source'));
const worker=path.join(out,'worker.mjs');fs.copyFileSync(new URL('./equality-worker.mjs',import.meta.url),worker);
const paths=[worker,import.meta.filename,process.execPath,m.api.file,derived.api,derived.report,derived.metadata.toolSnapshot.file,m.base.file,m.runtime.file,...m.snapshot.sources.map(x=>x.frozen.file),...cases.map(x=>x.file)];
const inputs=[...new Set(paths)].map(identity),report={kind:'phase9-equality-compiler-controls',complete:false,pass:false,scope:'Selected actual checking, exact observations, byte-identical JS and actual JS execution. Timings overlap other authorized work and are not a controlled speed claim.',inputs,cases,variants:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(const [variant,api]of [['original',m.api.file],['derived',derived.api]]){
  const workdir=path.join(out,variant);fs.mkdirSync(workdir);
  const request={variant,api,base:m.base.file,runtime:m.runtime.file,driver:path.join(m.snapshot.root,'tools/typed-driver.mjs'),workdir,cases,inputs};
  const requestFile=path.join(out,variant+'.request.json'),resultFile=path.join(out,variant+'.result.json');fs.writeFileSync(requestFile,JSON.stringify(request,null,2)+'\n');
  const execution=await supervise('taskset',['-c',cpu,process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,requestFile,resultFile],{directory:path.join(out,variant+'-process'),env:process.env,timeoutMs:180000});
  report.variants.push({variant,execution,result:fs.existsSync(resultFile)?JSON.parse(fs.readFileSync(resultFile)):null});save();requireExecution(execution);
 }
 const observation=row=>Object.fromEntries(['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','diagnostic','stdout','stderr','emittedSha256'].map(k=>[k,row.result[k]??null]));
 const [a,b]=report.variants.map(x=>x.result.rows);assert.equal(a.length,b.length);
 report.comparisons=a.map((row,i)=>({id:row.id,lane:row.lane,exact:JSON.stringify(observation(row))===JSON.stringify(observation(b[i]))}));
 assert.ok(report.comparisons.every(x=>x.exact),'Compiler observations or emitted bytes changed');
 inputs.forEach(verifyIdentity);verifyEqualityDerivation(derivationArg);await verifyAttempt(attempt);
 report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
save();console.log(JSON.stringify({pass:report.pass,rows:report.comparisons?.length,error:report.error}));
