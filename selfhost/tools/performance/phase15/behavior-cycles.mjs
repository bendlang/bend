import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const root=path.resolve(import.meta.dirname,'../../../..'),project=path.join(root,'selfhost'),out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const baseline=path.join(project,'build/phase14/combined-01'),candidate=path.join(project,'build/phase15/behavior-build-01'),hostProject=path.join(project,'build/phase15/behavior-source-02/project'),selection=path.join(project,'build/phase15/behavior-cycles-01/selection.json');
const inputs=[import.meta.filename,selection,path.join(hostProject,'tools/typed-driver.mjs'),process.execPath].map(identity),report={kind:'phase15-three-way-cycle-boundaries',complete:false,inputs,runs:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const b=await verifyAttempt(baseline),c=await verifyAttempt(candidate);report.baseline=b.api;report.candidate=c.api;
 // Bind the sole host02 change against the actual checked host, before probes.
 const oldHost=fs.readFileSync(path.join(c.snapshot.root,'tools/typed-driver.mjs'),'utf8'),newHost=fs.readFileSync(path.join(hostProject,'tools/typed-driver.mjs'),'utf8');
 const old="if(fs.readFileSync(path.join(project,'src/load/imports.bend'),'utf8').includes('def f_import_missing('))",replacement="if(files.includes('src/load/imports.bend')&&fs.readFileSync(path.join(project,'src/load/imports.bend'),'utf8').includes('def f_import_missing('))";
 assert.equal(oldHost.split(old).length,2);assert.equal(newHost,oldHost.replace(old,replacement));
 const line=newHost.split('\n').find(x=>x.includes(replacement)),guard=new Function('files','fs','path','project','exports',line);
 const ex=[];guard([], {readFileSync(){throw Error('must not read absent module');}},path,'unused',ex);assert.deepEqual(ex,[]);
 guard(['src/load/imports.bend'],{readFileSync(){return '# old module';}},path,'unused',ex);assert.deepEqual(ex,[]);
 guard(['src/load/imports.bend'],{readFileSync(){return 'def f_import_missing('; }},path,'unused',ex);assert.deepEqual(ex,['f_import_missing']);report.exportGuardCases=3;
 for(const [label,m,adapter] of [['baseline',b,path.join(b.snapshot.root,'tools/conformance/adapters/typed.mjs')],['candidate-host02',c,path.join(hostProject,'tools/conformance/adapters/typed.mjs')]]){
  const config=path.join(out,label+'.json');fs.writeFileSync(config,JSON.stringify({upstream:m.config.upstream,selection,jobs:1,workerMode:'persistent',recycleAfter:64,rssLimitMb:4096,heapMb:4096,stackKb:4096,timeoutMs:30000,retain:'all',cpu:2,candidateAdapter:adapter},null,2)+'\n');
  const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS'||key==='NODE_PATH')delete env[key];Object.assign(env,{BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file,BEND_UPSTREAM:m.config.upstream});
  const e=await supervise('taskset',['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(project,'tools/conformance/target.mjs'),config,path.join(out,label)],{directory:path.join(out,label+'-execution'),env,timeoutMs:180000});report.runs.push({label,api:m.api,host:identity(path.resolve(path.dirname(adapter),'../../typed-driver.mjs')),execution:e});save();requireExecution(e,[0,1]);
  const paired=JSON.parse(fs.readFileSync(path.join(out,label,'paired.json')));assert.equal(paired.rows.length,10);assert.deepEqual(paired.missing,[]);assert.ok(!paired.error);assert.ok(paired.rows.every(x=>x.semanticAgreement));
  for(const side of ['reference','candidate']){const r=JSON.parse(fs.readFileSync(path.join(out,label,side+'.json')));assert.equal(r.results.length,10);assert.ok(r.finished&&!r.changedInputs.length);assert.ok(r.workers.every(w=>!w.errors.length&&!w.stats.timeouts&&!w.stats.failures));}
 }
 const before=JSON.parse(fs.readFileSync(path.join(out,'baseline/paired.json'))),after=JSON.parse(fs.readFileSync(path.join(out,'candidate-host02/paired.json')));assert.deepEqual(before.rows.map(x=>x.reference),after.rows.map(x=>x.reference));
 report.rows=after.rows.map((x,i)=>({id:x.id,lane:x.lane,reference:x.reference,baseline:before.rows[i].candidate,candidate:x.candidate,baselineExact:before.rows[i].exactAgreement,candidateExact:x.exactAgreement,changed:JSON.stringify(before.rows[i].candidate)!==JSON.stringify(x.candidate)}));
 report.changed=report.rows.filter(x=>x.changed).length;report.complete=true;report.pass=true;report.scope='Healthy three-way observations and matching status/phase metadata; cycle diagnostics and changed error ordering are separately retained for review. No claim of universal cycle precedence.';inputs.forEach(verifyIdentity);await verifyAttempt(baseline);await verifyAttempt(candidate);
}catch(error){report.error=error.stack;process.exitCode=1;}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,changed:report.changed,error:report.error}));
