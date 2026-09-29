import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyIdentity,verifyAttempt,observationHealth} from '../../development/workflow.mjs';
import {requireExecution} from '../../development/process.mjs';
import {compareReports} from './frontend-layout-compare.mjs';
const [attemptArg,vectorArg,previousArg,descriptorArg,outArg]=process.argv.slice(2);
const project=path.resolve(import.meta.dirname,'../../..'),out=path.resolve(outArg),attempt=fs.realpathSync(attemptArg),vector=fs.realpathSync(vectorArg),previous=fs.realpathSync(previousArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const read=file=>JSON.parse(fs.readFileSync(file)),write=(name,value)=>fs.writeFileSync(path.join(out,name),JSON.stringify(value,null,2)+'\n');
const report={kind:'phase22-full-frontend-module-layout-reaudit',started:new Date().toISOString(),complete:false,pass:false,scope:'Reaudit healthy existing full acquisition with exact paths/oracles and an explicit audited module-layout migration. No compiler rerun or oracle change.'};
const save=()=>write('report.json',report),key=r=>r.id+'\0'+r.lane;
const semantic=r=>Object.fromEntries(['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','output'].map(k=>[k,k==='output'?r?.output??r?.stdout??null:r?.[k]??null]));
save();
try {
 const m=await verifyAttempt(attempt),originalFile=path.join(vector,'report.json'),original=read(originalFile),previousReportFile=path.join(previous,'report.json'),accepted=read(previousReportFile);
 original.inputs.forEach(verifyIdentity);accepted.inputs.forEach(verifyIdentity);verifyIdentity(accepted.candidate);assert.equal(accepted.complete,true);assert.equal(accepted.pass,true);
 assert.equal(original.api.sha256,m.api.sha256);assert.equal(original.api.canonicalPath,m.api.canonicalPath);
 const acquisition=original.phases.find(x=>x.name==='frontend');assert.ok(acquisition);requireExecution(acquisition.execution,[0,1]);
 const candidateFile=path.join(vector,'candidate.json'),referenceFile=path.join(project,'build/phase8/reference-frontend-01/reference.json'),baselineFile=path.join(project,'build/phase15/frontend-01/candidate.json'),previousFile=path.join(previous,'candidate.json');
 const descriptorFile=path.resolve(descriptorArg),descriptor=read(descriptorFile),controlsFile=path.join(project,'build/phase22/frontend-layout-controls-01/report.json'),controls=read(controlsFile);
 assert.equal(controls.pass,true);for(const item of controls.inputs){assert.equal(identity(item.file).sha256,item.sha256);if(item.canonicalPath!==undefined)assert.equal(fs.realpathSync(item.file),item.canonicalPath);}
 report.inputs=[originalFile,previousReportFile,candidateFile,referenceFile,baselineFile,previousFile,descriptorFile,controlsFile,import.meta.filename,path.join(import.meta.dirname,'frontend-layout-compare.mjs'),path.join(project,'tools/conformance/compare-artifacts.mjs'),path.join(attempt,'attempt.json')].map(identity);
 report.inputs.forEach(verifyIdentity);report.api=m.api;report.reusedAcquisition=acquisition;report.originalPostprocessingFailure=original.error;
 const candidate=read(candidateFile),reference=read(referenceFile),baseline=read(baselineFile),preceding=read(previousFile);
 assert.ok(observationHealth(candidate),'Unhealthy acquisition');assert.equal(candidate.results.length,2996);assert.equal(candidate.inventory.total,1498);
 assert.equal(candidate.options.upstream,m.config.upstream);assert.equal(String(candidate.options['stack-kb']),'4096');assert.equal(String(candidate.options['heap-mb']),'4096');
 const artifacts={compiler:m.api,runtime:m.runtime,base:m.base,driver:identity(path.join(m.snapshot.root,'tools/typed-driver.mjs')),compilerManifest:identity(path.join(m.snapshot.root,'src/compiler.json'))};
 for(const [name,expected] of Object.entries(artifacts)){const actual=candidate.identity.artifacts[name];assert.equal(fs.realpathSync(actual.file),expected.canonicalPath);assert.equal(actual.sha256,expected.sha256);assert.equal(candidate.identity.finalArtifactHashes[name],expected.sha256);}
 const adapter=identity(path.join(m.snapshot.root,'tools/conformance/adapters/typed.mjs'));assert.equal(fs.realpathSync(candidate.options.adapter),adapter.canonicalPath);assert.equal(candidate.identity.adapterSha256,adapter.sha256);assert.equal(candidate.identity.finalAdapterSha256,adapter.sha256);
 const opts={strictPaths:true,moduleLayoutMigration:descriptor},current=compareReports(reference,candidate,opts),prior=compareReports(reference,baseline,{strictPaths:true}),before=compareReports(reference,preceding,{strictPaths:true}),delta=compareReports(baseline,candidate,opts),since=compareReports(preceding,candidate,opts);
 write('reference-comparison.json',current);write('baseline-comparison.json',delta);write('preceding-comparison.json',since);
 assert.equal(prior.changes.length,459);assert.equal(current.missing.length,0);assert.equal(delta.missing.length,0);assert.equal(since.missing.length,0);
 const refMap=new Map(reference.results.map(r=>[key(r),r])),newDiff=new Set(current.changes.map(key)),oldDiff=new Set(before.changes.map(key));
 const primitive=candidate.results.filter(r=>JSON.stringify(semantic(r.result))!==JSON.stringify(semantic(refMap.get(key(r))?.result))).map(r=>({id:r.id,lane:r.lane,before:semantic(refMap.get(key(r))?.result),after:semantic(r.result)}));
 const lost=current.changes.filter(r=>!oldDiff.has(key(r))),gained=before.changes.filter(r=>!newDiff.has(key(r)));
 write('primitive-differences.json',primitive);write('lost-exact-differences.json',lost);write('new-exact-differences.json',gained);
 report.identityAndLayoutPass=true;report.candidate=identity(candidateFile);report.moduleLayout=current.moduleLayout;report.exact={phase15:459,preceding:before.changes.length,after:current.changes.length,newExact:gained.length,lostExact:lost.length};report.primitiveDifferences=primitive.length;report.observations=candidate.results.length;report.summary=candidate.summary;
 report.complete=true;report.pass=lost.length===0&&primitive.length===0;report.fullFrontendConformance=current.changes.length===0;report.verdict=report.pass?'No-regression gates passed':'UNSELECTED: retained exact or primitive-axis regressions require source correction';
 await verifyAttempt(attempt);report.inputs.forEach(verifyIdentity);
} catch(error){report.error=String(error.stack??error);report.pass=false;}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,exact:report.exact,primitiveDifferences:report.primitiveDifferences,error:report.error}));if(!report.pass)process.exitCode=1;
