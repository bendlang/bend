#!/usr/bin/env node
// A selected differential attempt; never bootstrap or infer full conformance.
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {PIN,PIN_MANIFEST,sha256} from './inventory.mjs';
import {probeKey} from './selection.mjs';
const [configFile,outputDirectory]=process.argv.slice(2);
if(!configFile||!outputDirectory)throw Error('usage: node target.mjs CONFIG.json NEW_OUTPUT_DIRECTORY');
const configPath=fs.realpathSync(configFile),config=JSON.parse(fs.readFileSync(configPath,'utf8')),relative=file=>fs.realpathSync(path.resolve(path.dirname(configPath),file));
const upstream=relative(config.upstream),output=path.resolve(outputDirectory);
if(fs.existsSync(output))throw Error('Use a fresh output directory');fs.mkdirSync(output,{recursive:true});
const hash=file=>sha256(fs.readFileSync(file)),save=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
function capture(command,args,env,label) {
  const stdout=path.join(output,label+'.stdout'),stderr=path.join(output,label+'.stderr');
  const a=fs.openSync(stdout,'wx'),b=fs.openSync(stderr,'wx');
  try {
    const result=spawnSync(command,args,{env,stdio:['ignore',a,b]});
    if(fs.statSync(stdout).size>2**24||fs.statSync(stderr).size>2**24)throw Error('Selected-run launcher output exceeded 16 MiB');
    return {...result,stdout:fs.readFileSync(stdout,'utf8'),stderr:fs.readFileSync(stderr,'utf8')};
  } finally {fs.closeSync(a);fs.closeSync(b);}
}
const artifacts={upstream},environment={BEND_UPSTREAM:upstream,BEND_BASE:path.join(upstream,'bend2/base.bend')};
let adapter=config.candidateAdapter?relative(config.candidateAdapter):null,bootstrap;
if(!adapter){
  const api=relative(config.api),runtime=relative(config.runtime),reportFile=relative(config.bootstrapReport);
  bootstrap=JSON.parse(fs.readFileSync(reportFile,'utf8'));
  if(bootstrap.revision!==PIN||bootstrap.apiSha256!==hash(api)||bootstrap.baseSha256!==hash(environment.BEND_BASE))throw Error('Checked API/bootstrap/Base identity mismatch');
  if(!bootstrap.source||bootstrap.sourceSha256!==hash(bootstrap.source)||!Array.isArray(bootstrap.modules)||!bootstrap.modules.length)throw Error('Missing or changed checked bootstrap source');
  for(const module of bootstrap.modules)if(hash(path.join(path.dirname(bootstrap.source),module.file))!==module.sha256)throw Error('Changed checked compiler module: '+module.file);
  Object.assign(artifacts,{api:{file:api,sha256:hash(api)},runtime:{file:runtime,sha256:hash(runtime)},bootstrapReport:{file:reportFile,sha256:hash(reportFile)}});
  Object.assign(environment,{BEND_TYPED_API:api,BEND_TYPED_RUNTIME:runtime});
  const frozen=capture(process.execPath,[path.join(import.meta.dirname,'freeze-adapter.mjs')],{...process.env,...environment},'freeze');
  if(frozen.status!==0||frozen.error)throw Error('Could not freeze typed host: '+(frozen.error?.message||frozen.stderr));adapter=frozen.stdout.trim();
}else{
  const allowed=['BEND_NATIVE_MANIFEST_DIRECTORY','BEND_NATIVE_BINARY','BEND_NATIVE_RUNTIME'];
  for(const [key,value] of Object.entries(config.candidateEnvironment||{})){if(!allowed.includes(key))throw Error('Unsupported candidate environment key: '+key);environment[key]=relative(value);}
  artifacts.candidateAdapter={file:adapter,sha256:hash(adapter)};
}
const cases=Array.isArray(config.cases)?config.cases:config.selection?JSON.parse(fs.readFileSync(relative(config.selection),'utf8')):null;
let entries=Array.isArray(cases)?cases:cases?.cases;
const selectionBase=config.selection?path.dirname(relative(config.selection)):path.dirname(configPath);
if(entries)entries=entries.map(entry=>({...entry,...entry.file?{file:fs.realpathSync(path.resolve(selectionBase,entry.file))}:{},lanes:entry.lanes||(entry.lane?[entry.lane]:(config.lanes||['check']))}));
const selectionFile=path.join(output,'selection.json');if(entries)save(selectionFile,{cases:entries});
const prior=config.rerun?relative(config.rerun):null;
if(!entries&&!prior)throw Error('Supply nonempty cases/selection or a prior candidate report');
const cpu=config.cpu;if(cpu!==undefined&&(!Number.isSafeInteger(cpu)||cpu<0))throw Error('CPU must be nonnegative integer');
// Freeze the whole harness as well as the typed host: concurrent tool edits
// cannot change workers already assigned to this immutable attempt.
const harness=path.join(output,'harness'),project=path.resolve(import.meta.dirname,'../..');
const harnessFiles=['run.mjs','worker.mjs','inventory.mjs','judge.mjs','selection.mjs','run-probe.mjs','replay.mjs','persistent-probe.mjs','persistent-worker.mjs','adapters/upstream.mjs'];
const harnessSources=[];
for(const file of harnessFiles){
  const sourceFile=path.join(import.meta.dirname,file),destination=path.join(harness,'tools/conformance',file);
  let source=fs.readFileSync(sourceFile,'utf8');
  if(file==='run.mjs')source=source.replace("const project=path.resolve(import.meta.dirname,'../..');",'const project='+JSON.stringify(project)+';');
  fs.mkdirSync(path.dirname(destination),{recursive:true});fs.writeFileSync(destination,source);harnessSources.push({file,sourceSha256:hash(sourceFile),consumedSha256:hash(destination)});
}
// inventory.mjs resolves its pin from the adjacent compiler source manifest,
// including in this smaller harness snapshot. Never fall back to a live pin.
const pinDestination=path.join(harness,'src/compiler.json'),pinSource=fs.readFileSync(PIN_MANIFEST);
if(JSON.parse(pinSource).upstream!==PIN)throw Error('Compiler upstream pin changed while freezing');
fs.mkdirSync(path.dirname(pinDestination),{recursive:true});fs.writeFileSync(pinDestination,pinSource);
harnessSources.push({file:'src/compiler.json',sourceSha256:sha256(pinSource),consumedSha256:hash(pinDestination)});
for(const file of ['native-build.mjs','node-resource-args.mjs'])fs.copyFileSync(path.join(project,'tools',file),path.join(harness,'tools',file));
if(adapter===path.join(import.meta.dirname,'adapters/native-graph.mjs')){
  const destination=path.join(harness,'tools/conformance/adapters/native-graph.mjs');fs.copyFileSync(adapter,destination);adapter=destination;
  const launcher=path.join(harness,'tools/performance/rapid/native-graph-run.mjs');fs.mkdirSync(path.dirname(launcher),{recursive:true});fs.copyFileSync(path.join(project,'tools/performance/rapid/native-graph-run.mjs'),launcher);
}
fs.copyFileSync(import.meta.filename,path.join(output,'target.mjs.source'));
const runner=path.join(harness,'tools/conformance/run.mjs'),common=['--upstream',upstream,'--timeout',String(config.timeoutMs??30000),'--jobs',String(config.jobs??1),'--worker-mode',config.workerMode??'isolated','--recycle-after',String(config.recycleAfter??64),'--rss-limit-mb',String(config.rssLimitMb??1024),'--stack-kb',String(config.stackKb??4096),'--heap-mb',String(config.heapMb??4096),'--retain',config.retain??'all','--selected-exit','1'];
if(entries)common.push('--selection',selectionFile);if(prior)common.push('--rerun',prior);
const report={kind:'targeted-paired-conformance',started:new Date().toISOString(),complete:false,selectedComplete:false,config:{file:configPath,sha256:hash(configPath)},artifacts,environment,harnessSources,targetSourceSha256:hash(path.join(output,'target.mjs.source')),cpu:cpu??null,attempts:{}};
const reportFile=path.join(output,'paired.json'),flush=()=>save(reportFile,report);flush();
const start=performance.now();
for(const [name,selectedAdapter] of [['reference',path.join(harness,'tools/conformance/adapters/upstream.mjs')],['candidate',adapter]]){
  const file=path.join(output,name+'.json'),args=[runner,...common,'--adapter',selectedAdapter,'--output',file];
  const command=cpu===undefined?process.execPath:'taskset',argv=cpu===undefined?args:['-c',String(cpu),process.execPath,...args];
  console.error('[target] '+name);const child=capture(command,argv,{...process.env,...environment},name);
  report.attempts[name]={file,argv:[command,...argv],exitCode:child.status,signal:child.signal,error:child.error?.message??null};
  if(child.error||child.signal||![0,1].includes(child.status)||!fs.existsSync(file)){report.error='No valid '+name+' report';flush();process.exitCode=1;break}
  report.attempts[name].sha256=hash(file);flush();
}
if(!report.error){
  const a=JSON.parse(fs.readFileSync(report.attempts.reference.file,'utf8')),b=JSON.parse(fs.readFileSync(report.attempts.candidate.file,'utf8')),before=new Map(a.results.map(row=>[probeKey(row),row]));
  const observation=row=>{const r=row.result||{};return {status:r.status??row.status,phase:r.phase??null,checked:r.checked??null,typeAccepted:r.typeAccepted??null,proofTrust:r.proofTrust??null,kernelChecked:r.kernelChecked??null,unsafeDefinitions:r.unsafeDefinitions??null,exitCode:r.exitCode??null,diagnostic:r.diagnostic??null,output:r.output??r.stdout??null}};
  report.rows=b.results.map(row=>{
    const reference=before.get(probeKey(row));before.delete(probeKey(row));const x=reference?observation(reference):null,y=observation(row);
    const semantic=value=>value&&({status:value.status,phase:value.phase,checked:value.checked,typeAccepted:value.typeAccepted,proofTrust:value.proofTrust,kernelChecked:value.kernelChecked,exitCode:value.exitCode,output:value.phase==='runtime'?value.output:null});
    return {id:row.id,lane:row.lane,referenceVerdict:reference?.status??'missing',candidateVerdict:row.status,reference:x,candidate:y,exactAgreement:JSON.stringify(x)===JSON.stringify(y),semanticAgreement:JSON.stringify(semantic(x))===JSON.stringify(semantic(y)),referenceEvidence:reference?.evidence??null,candidateEvidence:row.evidence??null};
  });
  report.missing=[...before.values()].map(row=>({id:row.id,lane:row.lane}));
  report.discrepancies=report.rows.filter(row=>!row.exactAgreement||!['pass','not-applicable','observed'].includes(row.referenceVerdict)||!['pass','not-applicable','observed'].includes(row.candidateVerdict));
  report.selectedComplete=a.selectedComplete&&b.selectedComplete&&!report.missing.length&&report.rows.every(row=>row.semanticAgreement);
  report.referenceSelectedComplete=a.selectedComplete;report.candidateSelectedComplete=b.selectedComplete;
  report.scope='Selected probes only. Exact fixture or explicit acceptance oracles and compiler agreement are separate. Complete full-suite conformance is never inferred.';
}
report.wallMs=performance.now()-start;report.finished=new Date().toISOString();flush();
console.log(JSON.stringify({report:reportFile,selectedComplete:report.selectedComplete,discrepancies:report.discrepancies?.length,error:report.error}));if(!report.selectedComplete)process.exitCode=1;
