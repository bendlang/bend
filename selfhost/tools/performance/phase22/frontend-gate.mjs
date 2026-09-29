// One entry for fresh or explicitly reused full frontend acquisition and exact layout-audited gates.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [attemptArg,outArg,previousArg,descriptorArg,reuseArg]=process.argv.slice(2);
if(!descriptorArg)throw Error('Usage: frontend-gate.mjs ATTEMPT OUTPUT PREVIOUS_ACCEPTED_GATE MODULE_LAYOUT.json [REUSE_ACQUISITION]');
const attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg),previous=fs.realpathSync(previousArg),descriptor=fs.realpathSync(descriptorArg),m=await verifyAttempt(attempt);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const read=f=>JSON.parse(fs.readFileSync(f)),write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
const reauditor=path.join(import.meta.dirname,'frontend-layout-reaudit-v3.mjs'),comparator=path.join(import.meta.dirname,'frontend-layout-compare.mjs');
const inputs=[import.meta.filename,reauditor,comparator,descriptor,path.join(attempt,'attempt.json'),process.execPath].map(identity);
const report={kind:'phase22-full-frontend-gate',complete:false,pass:false,noRegressionPass:false,fullFrontendConformance:false,started:new Date().toISOString(),inputs,api:m.api,phases:[],policy:{fixtures:1498,observations:2996,paths:'exact',oracles:'exact',moduleLayout:'explicit descriptor; actual/initial/final hashes and all non-module fields verified',pass:'zero exact differences plus health, identity and predecessor no-regression gates'},scope:'Pinned full parse/check observations; no backend, kernel proof or performance claim.'};
const save=()=>write(path.join(out,'report.json'),report);save();
const env={...process.env};for(const name of Object.keys(env))if(name.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(name))delete env[name];
Object.assign(env,{BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file,BEND_UPSTREAM:m.config.upstream});
try {
 inputs.forEach(verifyIdentity);
 let acquisition;
 if(reuseArg){
  acquisition=fs.realpathSync(reuseArg);report.reusedAcquisition=identity(path.join(acquisition,'report.json'));
 } else {
  acquisition=path.join(out,'acquisition');fs.mkdirSync(acquisition);
  const acq={kind:'phase22-full-frontend-acquisition',complete:false,pass:false,started:new Date().toISOString(),inputs:[...inputs],api:m.api,phases:[]};
  write(path.join(acquisition,'report.json'),acq);
  const execution=await supervise(process.execPath,[path.join(m.snapshot.root,'tools/conformance/run.mjs'),
   '--upstream',m.config.upstream,'--adapter',path.join(m.snapshot.root,'tools/conformance/adapters/typed.mjs'),
   '--output',path.join(acquisition,'candidate.json'),'--jobs','4','--timeout','30000','--worker-mode','persistent',
   '--recycle-after','64','--rss-limit-mb','4096','--lanes','parse,check','--stack-kb','4096','--heap-mb','4096','--retain','failed','--selected-exit','1'],
   {directory:path.join(acquisition,'frontend'),env,timeoutMs:1800000});
  acq.phases.push({name:'frontend',execution});acq.finished=new Date().toISOString();
  try{requireExecution(execution,[0,1]);acq.complete=true;}catch(error){acq.error=String(error.stack??error);}
  write(path.join(acquisition,'report.json'),acq);report.phases.push(...acq.phases);save();requireExecution(execution,[0,1]);
 }
 const auditDir=path.join(out,'audit'),execution=await supervise(process.execPath,[reauditor,attempt,acquisition,previous,descriptor,auditDir],{directory:path.join(out,'audit-process'),env,timeoutMs:180000});
 report.phases.push({name:'exact-layout-audit',execution});save();requireExecution(execution,[0,1]);
 const auditFile=path.join(auditDir,'report.json'),audit=read(auditFile);assert.equal(audit.complete,true,audit.error??'Audit did not complete');
 fs.copyFileSync(audit.candidate.file,path.join(out,'candidate.json'));
 for(const name of ['reference-comparison.json','baseline-comparison.json','preceding-comparison.json','primitive-differences.json','lost-exact-differences.json','new-exact-differences.json'])fs.copyFileSync(path.join(auditDir,name),path.join(out,name));
 Object.assign(report,{complete:true,identityAndLayoutPass:audit.identityAndLayoutPass,noRegressionPass:audit.pass,fullFrontendConformance:audit.fullFrontendConformance,
  pass:audit.pass&&audit.fullFrontendConformance,exact:audit.exact,primitiveDifferences:audit.primitiveDifferences,observations:audit.observations,summary:audit.summary,
  candidate:identity(path.join(out,'candidate.json')),audit:identity(auditFile),moduleLayout:audit.moduleLayout});
 report.inputs.push(...audit.inputs,identity(auditFile));await verifyAttempt(attempt);report.inputs.forEach(verifyIdentity);
} catch(error){report.error=String(error.stack??error);report.pass=false;}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,noRegressionPass:report.noRegressionPass,fullFrontendConformance:report.fullFrontendConformance,exact:report.exact,error:report.error}));if(!report.pass)process.exitCode=1;
