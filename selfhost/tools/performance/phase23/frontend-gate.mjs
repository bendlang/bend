// Fresh exact new-pin frontend acquisition; raw fixture verdicts stay visible.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {compareReports} from '../phase22/frontend-layout-compare.mjs';
const [attemptArg,outArg,scope='main',selectionArg]=process.argv.slice(2);
assert.ok(['main','broader'].includes(scope));
const attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg),raw=JSON.parse(fs.readFileSync(path.join(attempt,'attempt.json')));
const {verifyAttempt,identity,verifyIdentity}=await import(pathToFileURL(path.join(raw.snapshot.root,'tools/development/workflow.mjs')));
const {supervise,requireExecution}=await import(pathToFileURL(path.join(raw.snapshot.root,'tools/development/process.mjs')));
const {inventory}=await import(pathToFileURL(path.join(raw.snapshot.root,'tools/conformance/inventory.mjs')));
const m=await verifyAttempt(attempt),inv=inventory(m.config.upstream);
assert.equal(inv.revision,'018751270e800bc222a93dad7f257083ee53a5f7');assert.equal(inv.total,1513);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const read=f=>JSON.parse(fs.readFileSync(f)),write=(f,x)=>fs.writeFileSync(f,JSON.stringify(x,null,2)+'\n');
const cases=scope==='main'?inv.tests.map(t=>({id:t.id,lanes:['parse','check']})):read(fs.realpathSync(selectionArg)).cases;
const expected=scope==='main'?3026:196;assert.equal(cases.reduce((n,c)=>n+c.lanes.length,0),expected);
const selection=path.join(out,'selection.json');write(selection,{cases});
const config=path.join(out,'target.json');write(config,{upstream:m.config.upstream,selection,jobs:4,workerMode:'persistent',recycleAfter:64,rssLimitMb:4096,heapMb:4096,stackKb:4096,timeoutMs:30000,retain:'all',candidateAdapter:path.join(m.snapshot.root,'tools/conformance/adapters/typed.mjs')});
const inputs=[import.meta.filename,process.execPath,path.join(attempt,'attempt.json'),path.join(m.snapshot.root,'tools/conformance/target.mjs'),path.resolve(import.meta.dirname,'../phase22/frontend-layout-compare.mjs'),selection,config,...(selectionArg?[fs.realpathSync(selectionArg)]:[])].map(identity);
const report={kind:'phase23-fresh-frontend-gate',scope,complete:false,pass:false,exactAgreement:false,healthPass:false,expected,inputs,api:m.api,referencePin:inv.revision,comparisonPolicy:'Exact fixture paths/oracles, verdict/evidence and every behavioral result field; candidate-only file/sourceFile/hostProvenance independently checked as metadata. Unknown result fields fail closed. Timing and process metadata are not program behavior.',affinity:'4,5,6,7',performanceClaim:false};
const save=()=>write(path.join(out,'report.json'),report);save();
try{
 const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(key))delete env[key];
 Object.assign(env,{BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file,BEND_UPSTREAM:m.config.upstream,BEND_TYPED_TRACE:''});
 const destination=path.join(out,'selected');
 const execution=await supervise('taskset',['-c','4,5,6,7',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(m.snapshot.root,'tools/conformance/target.mjs'),config,destination],{directory:path.join(out,'launcher'),env,timeoutMs:1800000});
 report.execution=execution;save();requireExecution(execution,[0,1]);
 const paired=read(path.join(destination,'paired.json')),a=read(path.join(destination,'reference.json')),b=read(path.join(destination,'candidate.json'));
 report.paired=identity(path.join(destination,'paired.json'));report.reference=identity(path.join(destination,'reference.json'));report.candidate=identity(path.join(destination,'candidate.json'));
 assert.ok(!paired.error,paired.error);for(const r of [a,b]){
  assert.ok(r.finished);assert.equal(r.changedInputs.length,0);assert.equal(r.identity.adapterChangedDuringRun,false);assert.equal(r.identity.changedArtifacts.length,0);assert.equal(r.results.length,expected);
  assert.equal(r.workers.length,4);for(const w of r.workers){assert.equal(w.errors.length,0);assert.equal(w.stats.timeouts,0);assert.equal(w.stats.failures,0);}
  for(const [file,digest] of Object.entries(r.inputHashes)){assert.equal(fs.realpathSync(file),r.inputPaths[file]);assert.equal(createHash('sha256').update(fs.readFileSync(file)).digest('hex'),digest);}
  for(const [name,artifact] of Object.entries(r.identity.artifacts)){assert.equal(r.identity.finalArtifactHashes[name],artifact.sha256);assert.equal(createHash('sha256').update(fs.readFileSync(artifact.file)).digest('hex'),artifact.sha256);}
 }
 const comparison=compareReports(a,b,{strictPaths:true});write(path.join(out,'behavior-comparison.json'),comparison);
 const behavioral=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','diagnostic','stdout','stderr','output','error','signal','reason'];
 const metadata=['files','sourceFile','hostProvenance'],allowed=new Set([...behavioral,...metadata]),prior=new Map(a.results.map(r=>[r.id+'\0'+r.lane,r]));
 const canonical=x=>JSON.stringify(behavioral.map(k=>[k,x[k]??null]));
 const extraChanges=[],metadataChecks=[];
 for(const row of b.results){const previous=prior.get(row.id+'\0'+row.lane);assert.ok(previous);prior.delete(row.id+'\0'+row.lane);
  for(const result of [previous.result,row.result])for(const key of Object.keys(result??{}))assert.ok(allowed.has(key),'Unknown result key '+key);
  if(canonical(previous.result??{})!==canonical(row.result??{}))extraChanges.push({id:row.id,lane:row.lane,reference:previous.result,candidate:row.result});
  const r=row.result??{},checks={id:row.id,lane:row.lane};
  if(r.hostProvenance){assert.equal(r.hostProvenance.driverSha256,b.identity.artifacts.driver.sha256);assert.equal(r.hostProvenance.adapterSha256,b.identity.adapterSha256);checks.host=true;}
  for(const file of [...(r.files??[]),...(r.sourceFile?[r.sourceFile]:[])]){assert.equal(typeof file,'string');assert.ok(path.isAbsolute(file));assert.ok(b.inputHashes[file]||Object.values(b.identity.artifacts).some(x=>x.file===file),'Unregistered source metadata '+file);}
  checks.files=r.files??null;checks.sourceFile=r.sourceFile??null;metadataChecks.push(checks);
 }
 assert.equal(prior.size,0);write(path.join(out,'all-fields-differences.json'),extraChanges);write(path.join(out,'metadata-checks.json'),metadataChecks);
 report.healthPass=true;report.exact=expected-extraChanges.length;report.exactAgreement=comparison.sameObservedBehavior&&extraChanges.length===0;
 report.raw={referenceSelectedComplete:a.selectedComplete,candidateSelectedComplete:b.selectedComplete,pairedSelectedComplete:paired.selectedComplete,referenceSummary:a.summary,candidateSummary:b.summary,referenceFailures:a.results.filter(r=>!['pass','observed','not-applicable'].includes(r.status)).map(r=>({id:r.id,lane:r.lane,status:r.status,evidence:r.evidence,result:r.result})),candidateFailures:b.results.filter(r=>!['pass','observed','not-applicable'].includes(r.status)).map(r=>({id:r.id,lane:r.lane,status:r.status,evidence:r.evidence,result:r.result}))};
 report.workerStats={reference:a.workers.map(w=>w.stats),candidate:b.workers.map(w=>w.stats)};
 report.inputs.push(report.reference,report.candidate,report.paired);await verifyAttempt(attempt);report.inputs.forEach(verifyIdentity);
 report.complete=true;report.pass=report.healthPass&&report.exactAgreement;report.differences=comparison.changes.length;report.extraFieldDifferences=extraChanges.length;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,exact:report.exact,expected:report.expected,error:report.error}));if(!report.pass)process.exitCode=1;
