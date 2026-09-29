// Run selected JS/native probes using an identity-verified frozen compiler.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../..'),build=fs.realpathSync(process.argv[2]),out=path.resolve(process.argv[3]),selection=fs.realpathSync(process.argv[4]);
const workflow=path.join(build,'snapshot/tools/development/workflow.mjs'),w=await import(pathToFileURL(workflow)),m=await w.verifyAttempt(build);
const {supervise,requireExecution}=await import(pathToFileURL(path.join(build,'snapshot/tools/development/process.mjs')));
const envFile=path.join(root,'build/phase16/wave6-backend-environment-01.json'),frozen=JSON.parse(fs.readFileSync(envFile));
for(const item of frozen.inputs)assert.equal(w.identity(item.file).sha256,item.sha256);
const env={...process.env};for(const k of Object.keys(env))if(k.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(k))delete env[k];
Object.assign(env,frozen.environment,{BEND_UPSTREAM:m.config.upstream,BEND_BASE:m.base.file,BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_TYPED_TRACE:''});
fs.mkdirSync(out,{recursive:false});fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const data=JSON.parse(fs.readFileSync(selection)),cases=(Array.isArray(data)?data:data.cases).map(c=>({...c,...c.file?{file:fs.realpathSync(path.resolve(path.dirname(selection),c.file))}:{}})),count=cases.reduce((n,c)=>n+c.lanes.length,0);
fs.writeFileSync(path.join(out,'selection.json'),JSON.stringify({cases},null,2)+'\n');
const target={upstream:m.config.upstream,selection:path.join(out,'selection.json'),cpu:3,jobs:1,workerMode:'isolated',rssLimitMb:4096,heapMb:4096,stackKb:4096,timeoutMs:30000,retain:'all',candidateAdapter:path.join(m.snapshot.root,'tools/conformance/adapters/typed.mjs')};
fs.writeFileSync(path.join(out,'target.json'),JSON.stringify(target,null,2)+'\n');
const inputs=[import.meta.filename,workflow,selection,envFile,path.join(build,'attempt.json')].map(w.identity);
const report={kind:'phase23-backend-paired',complete:false,pass:false,cpu:3,api:m.api,inputs,environment:frozen.environment};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const run=await supervise('taskset',['-c','3',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(m.snapshot.root,'tools/conformance/target.mjs'),path.join(out,'target.json'),path.join(out,'selected')],{directory:path.join(out,'command'),env,timeoutMs:1200000});report.execution=run;save();requireExecution(run,[0,1]);
 const paired=JSON.parse(fs.readFileSync(path.join(out,'selected/paired.json')));assert.equal(paired.rows.length,count);assert.equal(paired.missing.length,0);assert.ok(!paired.error);
 const sides=['reference','candidate'].map(n=>JSON.parse(fs.readFileSync(path.join(out,'selected',n+'.json'))));
 report.acquisitionComplete=sides.every(d=>d.finished&&d.results.length===count&&d.changedInputs?.length===0&&d.identity?.changedArtifacts?.length===0);
 report.rawComplete=paired.complete;report.rawSelectedComplete=paired.selectedComplete;report.rows=paired.rows;report.exact=paired.rows.filter(x=>x.exactAgreement).length;report.complete=report.acquisitionComplete;report.pass=paired.rows.every(x=>x.exactAgreement&&x.referenceVerdict==='pass'&&x.candidateVerdict==='pass');
 await w.verifyAttempt(build);inputs.forEach(w.verifyIdentity);
}catch(e){report.error=String(e.stack);process.exitCode=1}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,exact:report.exact,total:count,error:report.error}));
if(!report.pass)process.exitCode=1;
