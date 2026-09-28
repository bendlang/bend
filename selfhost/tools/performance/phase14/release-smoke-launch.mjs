import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [projectArg,outArg,expectedApi]=process.argv.slice(2),project=fs.realpathSync(projectArg),out=path.resolve(outArg);
assert.match(expectedApi,/^[0-9a-f]{64}$/);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-launcher.mjs'));
const runner=path.join(import.meta.dirname,'release-smoke.mjs');
const inputs=[import.meta.filename,runner,process.execPath,path.join(project,'dist/release.json'),path.join(project,'dist/typed-api.mjs')].map(identity);
const report={kind:'phase14-release-smoke-launch',complete:false,pass:false,inputs,expectedApi,cpu:2};
const save=()=>fs.writeFileSync(path.join(out,'launcher.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 assert.equal(identity(path.join(project,'dist/typed-api.mjs')).sha256,expectedApi);
 const env={...process.env};for(const k of Object.keys(env))if(k.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(k))delete env[k];
 report.execution=await supervise('taskset',['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',runner,project,path.join(out,'checks'),expectedApi],{directory:path.join(out,'process'),env,timeoutMs:1200000});save();requireExecution(report.execution);
 const resultFile=path.join(out,'checks/report.json'),r=JSON.parse(fs.readFileSync(resultFile));assert.ok(r.pass);assert.equal(r.steps.length,42);assert.equal(r.apiSha256,expectedApi);assert.ok(r.steps.every(s=>s.pass&&!s.error&&!s.signal&&!s.timedOut&&!s.overflow));inputs.forEach(verifyIdentity);report.checks=identity(resultFile);report.steps=42;report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,steps:report.steps,error:report.error}));
