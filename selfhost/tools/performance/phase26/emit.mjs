// Checked emission using an explicitly verified immutable development attempt.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [attempt,inputArgument,outputArgument]=process.argv.slice(2);
const input=fs.realpathSync(inputArgument),output=path.resolve(outputArgument);
const report={kind:'phase26-checked-emission',complete:false,input:identity(input),started:new Date().toISOString()};
const start=performance.now();
try{
  const m=await verifyAttempt(attempt);
  report.attempt=identity(path.join(attempt,'attempt.json'));
  report.api=m.api;report.runtime=m.runtime;report.base=m.base;
  report.driver=identity(path.join(m.snapshot.root,'tools/typed-driver.mjs'));
  process.env.BEND_TYPED_API=m.api.file;process.env.BEND_TYPED_RUNTIME=m.runtime.file;process.env.BEND_BASE=m.base.file;
  const D=await import(pathToFileURL(report.driver.file));
  const result=await D.inspect(input,{mode:'library'});
  const {code,...observation}=result;report.observation=observation;
  assert.equal(result.status,'ok');assert.equal(result.checked,true);
  fs.writeFileSync(output,code,{flag:'wx'});report.output=identity(output);
  verifyIdentity(report.input);verifyIdentity(report.attempt);await verifyAttempt(attempt);report.complete=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
report.elapsedMs=performance.now()-start;
report.timingScope='Acquisition only, includes verification; not compiler throughput.';
fs.writeFileSync(output+'.json',JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify(report));
