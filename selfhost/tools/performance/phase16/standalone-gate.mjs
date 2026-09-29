// Compile the maintained standalone loader from the exact final frozen source.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{pathToFileURL}from'node:url';import{supervise,requireExecution}from'../../development/process.mjs';
const[aa,oo]=process.argv.slice(2),attempt=fs.realpathSync(aa),out=path.resolve(oo),project=path.resolve(import.meta.dirname,'../../..');fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-launcher.mjs'));
const workflow=path.join(attempt,'snapshot/tools/development/workflow.mjs'),W=await import(pathToFileURL(workflow)),test=path.join(project,'tests/frontend/trace-component.mjs'),inputs=[import.meta.filename,workflow,test,process.execPath,path.join(attempt,'attempt.json')].map(W.identity),report={kind:'phase16-final-standalone-loader',complete:false,pass:false,cpu:2,inputs,scope:'Unchanged maintained25-module standalone loader and raw/traced/seeded controls, rebuilt from final attempt snapshot. No checker/diagnostic tracing/production dependency; shared model/render remain explicit.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const m=await W.verifyAttempt(attempt);report.finalApi=m.api;report.checkedApi=m.checkedApi;
 // The maintained test imports assemble from the live repo; prove byte identity
 // with the exact source snapshot before allowing that import to build anything.
 for(const name of['assemble.mjs','stage0-library.mjs']){const live=path.join(project,'tools',name),frozen=path.join(m.snapshot.root,'tools',name);inputs.push(W.identity(live),W.identity(frozen));assert.equal(W.identity(live).sha256,W.identity(frozen).sha256);}
 const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(key))delete env[key];Object.assign(env,{BEND_COMPONENT_PROJECT:m.snapshot.root,BEND_UPSTREAM:m.config.upstream});
 report.execution=await supervise('taskset',['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',test,path.join(out,'component')],{directory:path.join(out,'execution'),env,timeoutMs:90000});save();requireExecution(report.execution);
 const resultFile=path.join(out,'component/report.json'),r=JSON.parse(fs.readFileSync(resultFile));assert(r.complete);assert.equal(r.status,0);assert.equal(r.signal,null);assert.equal(r.modules.length,25);assert(r.modules.every(x=>!x.startsWith('src/check/')&&(!x.startsWith('src/diagnostic/')||['src/diagnostic/model.bend','src/diagnostic/render.bend'].includes(x))));report.component=W.identity(resultFile);report.moduleCount=r.modules.length;
 await W.verifyAttempt(attempt);inputs.forEach(W.verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,modules:report.moduleCount,error:report.error}));
