// Run the maintained genuine checked B1 -> H -> H gate, without resume or substitution.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {verifyAttempt,verifyIdentity,identity} from '../../../selfhost/tools/development/workflow.mjs';
import {supervise,requireExecution} from '../../../selfhost/tools/development/process.mjs';

const [attemptArg,outArg]=process.argv.slice(2);
assert.ok(attemptArg&&outArg,'Expected ATTEMPT NEW_OUTPUT');
const attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const m=await verifyAttempt(attempt);
const bootstrap=JSON.parse(fs.readFileSync(m.bootstrapReport.file,'utf8'));
const host=path.join(m.snapshot.root,'tools/typed-driver.mjs');
const runner=path.join(m.snapshot.root,'tools/conformance/selfhost.mjs');
const report={kind:'S4-genuine-checked-self-reproduction',complete:false,pass:false,
  source:identity(bootstrap.source),api:m.checkedApi,base:m.base,runtime:m.runtime,
  node:{...identity(process.execPath),version:process.version},
  inputs:[identity(import.meta.filename),identity(path.join(attempt,'attempt.json')),m.bootstrapReport,
    identity(host),identity(runner),identity(path.join(path.dirname(import.meta.filename),'../../../selfhost/tools/development/workflow.mjs')),
    identity(path.join(path.dirname(import.meta.filename),'../../../selfhost/tools/development/process.mjs'))],
  policy:'Unchanged maintained runner; genuine checked API as initial compiler; actual emitted H compiles the same source; no resume or fabricated stage/sidecar.',
  cpu:'0',heapMb:12288,stackKb:4096,stageTimeoutMs:2400000,outerTimeoutMs:3300000,
  started:new Date().toISOString()};
const save=()=>fs.writeFileSync(path.join(out,'launch.json'),JSON.stringify(report,null,2)+'\n');save();
try {
  const env={...process.env};
  for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];
  Object.assign(env,{BEND_UPSTREAM:m.config.upstream,BEND_BASE:m.base.file,BEND_TYPED_API:m.checkedApi.file,
    BEND_TYPED_RUNTIME:m.runtime.file,BEND_SELFHOST_DRIVER:host,BEND_SELFHOST_TIMEOUT:'2400000',
    BEND_SELFHOST_STACK_KB:'4096',BEND_SELFHOST_HEAP_MB:'12288'});
  report.execution=await supervise('taskset',['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=12288',runner,
    bootstrap.source,path.join(out,'proof')],{directory:path.join(out,'command'),env,timeoutMs:3300000});
  save();requireExecution(report.execution);
  const proof=JSON.parse(fs.readFileSync(path.join(out,'proof/report.json'),'utf8'));
  assert.equal(proof.complete,true);assert.deepEqual(proof.requestedStages,[2,3]);assert.equal(proof.stages.length,2);
  assert.equal(proof.initialCompiler.sha256,m.checkedApi.sha256);assert.equal(proof.sourceSha256,report.source.sha256);
  assert.ok(!proof.previousAttempts&&!proof.interrupted&&!proof.error);
  const bytes=proof.stages.map(stage=>{
    assert.equal(stage.code,0);assert.equal(stage.signal,null);assert.equal(stage.inputsVerified,true);
    const value=fs.readFileSync(stage.output);
    assert.equal(createHash('sha256').update(value).digest('hex'),stage.outputSha256);return value;
  });
  assert.ok(bytes[0].equals(bytes[1]),'Actual stage outputs differ');
  assert.equal(proof.stages[1].compilerSha256,proof.stages[0].outputSha256);
  for(const item of [...report.inputs,report.source,report.api,report.base,report.runtime,report.node])verifyIdentity(item);
  await verifyAttempt(attempt);
  report.proof=identity(path.join(out,'proof/report.json'));report.outputBytes=bytes[0].length;
  report.outputSha256=proof.stages[0].outputSha256;report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
report.finished=new Date().toISOString();save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,outputSha256:report.outputSha256,error:report.error}));
