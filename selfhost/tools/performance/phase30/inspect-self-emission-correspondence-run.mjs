// One bounded actual emission; byte equality decides reuse of a prior functional gate.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
import {supervise,requireExecution} from '../../development/process.mjs';
const [planFile]=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile)),out=path.join(path.dirname(path.resolve(planFile)),'execution');
assert.equal(p.kind,'phase30-actual-self-emission-correspondence-plan');assert.equal(p.complete,true);assert.equal(p.executed,false);assert.equal(p.timeoutMs,1200000);
fs.mkdirSync(out,{recursive:false});const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const verify=()=>{for(const x of p.inputs)assert.equal(ident(x.file).sha256,x.sha256)};
const report={kind:'phase30-actual-self-emission-correspondence',complete:false,pass:false,plan:ident(planFile),producer:ident(import.meta.filename),scope:p.scope};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));
const env={...process.env};for(const k of Object.keys(env))if(k.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(k))delete env[k];env.BEND_TYPED_TRACE='1';
try{
 verify();assert.equal(ident(process.execPath).sha256,p.node.sha256);assert.equal(fs.existsSync(p.output),false);assert.equal(fs.existsSync(p.output+'.json'),false);
 report.execution=await supervise('taskset',['-c',p.cpu,process.execPath,...p.nodeArgs,p.emitter.file,p.attemptDirectory,p.source.file,p.output],{directory:path.join(out,'emission'),env,timeoutMs:p.timeoutMs});save();requireExecution(report.execution);
 const r=JSON.parse(fs.readFileSync(p.output+'.json'));report.output=ident(p.output);report.emissionReceipt=ident(p.output+'.json');report.observation=r.observation;save();
 assert.equal(r.complete,true);assert.equal(r.observation.checked,true);assert.equal(r.observation.status,'ok');
 for(const [key,expected]of Object.entries({attempt:p.attempt,api:p.api,input:p.source,runtime:p.runtime,base:p.base,output:report.output}))assert.equal(r[key].sha256,expected.sha256);
 assert.equal(report.output.sha256,p.expected.sha256);assert.equal(report.output.bytes,p.expected.bytes);verify();
 report.byteIdenticalToManualFlag=true;report.reusedFunctionalGate=p.functionalGate;report.complete=report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,output:report.output,error:report.error}));
