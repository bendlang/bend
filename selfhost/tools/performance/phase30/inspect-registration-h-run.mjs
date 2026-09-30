// Root-granted correctness only: no H self-emission or speed measurement.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
import {supervise,requireExecution} from '../../development/process.mjs';
const [planFile]=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile)),out=path.join(path.dirname(path.resolve(planFile)),'execution');
assert.equal(p.kind,'phase30-manual-h-runtime-functional-plan');assert.equal(p.complete,true);assert.equal(p.executed,false);assert.equal(p.resources.oracleTimeoutSeconds,90);
fs.mkdirSync(out,{recursive:false});const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const verify=()=>{for(const x of p.inputs)assert.equal(ident(x.file).sha256,x.sha256)};
const report={kind:'phase30-manual-h-runtime-functional-gate',complete:false,pass:false,inputs:[ident(planFile),ident(import.meta.filename)],scope:p.scope,steps:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));
const env={...process.env};for(const k of Object.keys(env))if(k.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(k))delete env[k];
try{
 verify();assert.equal(ident(process.execPath).sha256,p.node.sha256);for(const mode of ['base','oracle']){
  const directory=path.join(out,mode),command=['-c',p.resources.cpu,process.execPath,...p.resources.nodeArgs,p.worker.file,path.resolve(planFile),p.diagnostic.file,directory,mode,...(mode==='oracle'?[p.reference.file]:[])];
  const execution=await supervise('taskset',command,{directory:path.join(out,mode+'-process'),env,timeoutMs:90000});
  const file=path.join(directory,'report.json'),observation=fs.existsSync(file)?JSON.parse(fs.readFileSync(file)):null;
  report.steps.push({mode,execution,observation,receipt:fs.existsSync(file)?ident(file):null});save();requireExecution(execution);
  assert.equal(observation?.complete,true);assert.equal(observation.pass,true);assert.equal(observation.manuallyDerivedRuntimeDiagnostic,true);
  assert.equal(observation.affinity.split(':')[1].trim(),p.resources.cpu);assert.equal(observation.cache.compilerSha256,p.diagnostic.sha256);
  if(mode==='oracle'){assert.equal(observation.sameOriginalHObservations,true);assert.equal(observation.smallOutputBytesEqual,true);assert.equal(observation.result,8)}
  verify();
 }
 report.complete=report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));
