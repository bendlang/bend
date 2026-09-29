// Final unchanged equality tests and authentic historical replay, no installation.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {supervise,requireExecution} from '../../development/process.mjs';
const [attemptArg,outArg]=process.argv.slice(2),attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg);
const project=path.resolve(import.meta.dirname,'../../..');
const workflowFile=path.join(attempt,'snapshot/tools/development/workflow.mjs');
const {identity,verifyIdentity,verifyAttempt}=await import(pathToFileURL(workflowFile));
// Authentic replay inputs use repository-relative historical paths.
process.chdir(path.dirname(project));
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-launcher.mjs'));
const tests=path.join(project,'tools/development/equality.test.mjs'),helper=path.join(project,'tools/development/equality.mjs'),replay=path.join(project,'tools/performance/phase12/call-replay.mjs');
const validationFile=path.join(attempt,'validation-001/report.json');
const read=file=>JSON.parse(fs.readFileSync(file));
const inputs=[import.meta.filename,workflowFile,process.execPath,tests,helper,replay,validationFile,path.join(attempt,'attempt.json'),path.join(attempt,'api.mjs'),path.join(attempt,'api.mjs.bootstrap.json')].map(identity);
for(const file of [tests,helper,replay])fs.copyFileSync(file,path.join(out,'consumed-'+path.basename(file)));
const report={kind:'phase16-final-equality-gates',complete:false,pass:false,started:new Date().toISOString(),cpu:2,inputs,steps:[],scope:'Unchanged 16 maintained equality test groups on final genuine checked B1; current v5 and authentic v1-v4 replay. Tests and historical emitter bytes remain unchanged; final snapshot workflow verifies termABI1/cache6 lineage. No ABI payload projection or helper guard adjustment. No release installation, new bootstrap, performance or broad conformance claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const m=await verifyAttempt(attempt),v=read(validationFile);
 assert.ok(v.complete&&v.pass);assert.equal(v.selected.candidate.probes,36);assert.equal(v.selected.candidate.statuses.pass,36);
 for(const name of ['equality.mjs','equality.test.mjs'])assert.equal(identity(path.join(project,'tools/development',name)).sha256,identity(path.join(m.snapshot.root,'tools/development',name)).sha256);
 report.api=m.api;report.checkedApi=m.checkedApi;report.focused={observations:36,pass:true};save();
 const env={...process.env};for(const k of Object.keys(env))if(k.startsWith('BEND_')||k.startsWith('EQUALITY_TEST_')||['NODE_OPTIONS','NODE_PATH'].includes(k))delete env[k];
 Object.assign(env,{EQUALITY_TEST_API:m.checkedApi.file,EQUALITY_TEST_BOOTSTRAP:m.bootstrapReport.file,EQUALITY_TEST_REPORT:path.join(out,'tests-report.json')});
 async function run(label,args){const execution=await supervise('taskset',['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',...args],{directory:path.join(out,label),env,timeoutMs:180000});report.steps.push({label,execution});save();requireExecution(execution);}
 await run('tests',['--test',tests]);const tr=read(env.EQUALITY_TEST_REPORT);assert.ok(tr.pass);assert.equal(tr.completed.length,16);assert.equal(tr.failures.length,0);report.tests=identity(env.EQUALITY_TEST_REPORT);save();
 await run('replay-command',[replay,project,attempt,path.join(out,'replay')]);const rr=read(path.join(out,'replay/report.json'));assert.ok(rr.complete&&rr.pass);assert.equal(rr.checks.length,5);report.replay=identity(path.join(out,'replay/report.json'));report.replayChecks=rr.checks;
 await verifyAttempt(attempt);inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,tests:report.tests,replay:report.replay,error:report.error}));
