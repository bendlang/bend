#!/usr/bin/env node
// Compose the maintained bootstrap and conformance tools. No compiler logic or
// replacement oracle lives here; a derived API never receives a bootstrap sidecar.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {PIN} from '../conformance/inventory.mjs';
import {supervise,requireExecution} from './process.mjs';

const project=path.resolve(import.meta.dirname,'../..');
export const digest=bytes=>createHash('sha256').update(bytes).digest('hex');
export const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:digest(fs.readFileSync(file))});
export function verifyIdentity(item) {
  const actual=identity(item.file);
  if(actual.canonicalPath!==item.canonicalPath||actual.sha256!==item.sha256)throw Error('Changed input: '+item.file);
}
const json=file=>JSON.parse(fs.readFileSync(file,'utf8'));
function launcherInputs(output) {
  const directory=path.join(output,'launcher');fs.mkdirSync(directory);
  return [import.meta.filename,path.join(import.meta.dirname,'process.mjs'),path.join(import.meta.dirname,'../conformance/inventory.mjs')].map(file=>{
    const original=identity(file),snapshot=path.join(directory,path.basename(file));fs.copyFileSync(file,snapshot);
    const frozen=identity(snapshot);if(original.sha256!==frozen.sha256)throw Error('Launcher changed while freezing');
    return {...original,snapshot:frozen};
  });
}
const verifyLauncher=items=>{for(const item of items){verifyIdentity(item);verifyIdentity(item.snapshot);}};
const write=(file,data)=>fs.writeFileSync(file,JSON.stringify(data,null,2)+'\n',{flag:'wx'});
const walk=directory=>fs.readdirSync(directory,{withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name)).flatMap(e=>e.isDirectory()?walk(path.join(directory,e.name)):[path.join(directory,e.name)]);
const integer=(value,name,min,max)=>{if(!Number.isSafeInteger(value)||value<min||value>max)throw Error('Invalid '+name);return value;};
export function configuration(value, directory=process.cwd()) {
  const known=new Set(['project','upstream','selection','profile','fullFrontend','strictExact','jobs','cpu','timeoutMs','phaseTimeoutMs','fullTimeoutMs','heapMb','recycleAfter']);
  for(const key of Object.keys(value))if(!known.has(key))throw Error('Unknown configuration key: '+key);
  const resolve=file=>fs.realpathSync(path.resolve(directory,file));
  const root=resolve(value.project??project),upstream=resolve(value.upstream??path.join(root,'.bootstrap/upstream-phase8'));
  const profile=value.profile??'checked';if(!['checked','equality'].includes(profile))throw Error('Unknown development profile');
  if(value.fullFrontend!==undefined&&typeof value.fullFrontend!=='boolean')throw Error('fullFrontend must be boolean');
  if(value.strictExact!==undefined&&typeof value.strictExact!=='boolean')throw Error('strictExact must be boolean');
  const cpu=value.cpu??null;
  if(cpu!==null&&(!/^(0|[1-9]\d*)(,(0|[1-9]\d*))*$/.test(String(cpu))||new Set(String(cpu).split(',')).size!==String(cpu).split(',').length))throw Error('Invalid CPU mask');
  return {project:root,upstream,selection:value.selection?resolve(value.selection):null,profile,fullFrontend:value.fullFrontend??false,strictExact:value.strictExact??false,
    jobs:integer(value.jobs??1,'jobs',1,4),cpu:cpu===null?null:String(cpu),timeoutMs:integer(value.timeoutMs??120000,'timeoutMs',100,300000),
    phaseTimeoutMs:integer(value.phaseTimeoutMs??900000,'phaseTimeoutMs',100,3600000),fullTimeoutMs:integer(value.fullTimeoutMs??3600000,'fullTimeoutMs',100,3600000),
    heapMb:integer(value.heapMb??4096,'heapMb',256,4096),recycleAfter:integer(value.recycleAfter??64,'recycleAfter',1,256)};
}
export function verifyBootstrap(api, reportFile, base) {
  const report=json(reportFile);
  if(report.stage!=='upstream-bootstrap'||report.revision!==PIN||report.provenance?.verifiedAfterBuild!==true||!report.provenance?.inputs?.length)
    throw Error('A genuine verified checked bootstrap is required');
  if(report.apiSha256!==identity(api).sha256||report.baseSha256!==identity(base).sha256||report.sourceSha256!==identity(report.source).sha256)
    throw Error('Checked bootstrap/API/source/Base mismatch');
  if(!report.modules?.length)throw Error('Missing checked source modules');
  for(const item of report.provenance.inputs)verifyIdentity(item);
  for(const item of report.modules)if(identity(path.join(path.dirname(report.source),item.file)).sha256!==item.sha256)throw Error('Checked module mismatch: '+item.file);
  return report;
}
export function validatedCache(directory, api, base) {
  const apiSha=identity(api).sha256,baseSha=identity(base).sha256,canonical=fs.realpathSync(base);
  const file=path.join(directory,`base-${apiSha}-${baseSha}-${digest(canonical)}.json`);
  const c=json(file);
  const sourceSpan=(c.version===4||(c.version===6&&c.termAbi===1))&&c.spanAbi===3&&c.sourceBegin===1&&c.sourceEnd===fs.readFileSync(base,'utf8').length+2;
  if((c.version!==2&&!sourceSpan)||c.compilerSha256!==apiSha||c.baseSha256!==baseSha||c.sourcePath!==canonical||c.validatedBy!=='check_book'||c.bookSha256!==digest(JSON.stringify(c.book)))
    throw Error('Invalid API-specific checked Base cache: '+file);
  return identity(file);
}
function environment(manifest,api) {
  const env={...process.env};
  for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];
  return {...env,BEND_UPSTREAM:manifest.config.upstream,BEND_BASE:manifest.base.file,BEND_TYPED_API:api,BEND_TYPED_RUNTIME:manifest.runtime.file,BEND_TYPED_TRACE:''};
}
async function command(manifest, label, script, args, output, api, timeoutMs) {
  const nodeArgs=['--stack-size=4096',`--max-old-space-size=${manifest.config.heapMb}`,script,...args];
  const cmd=manifest.config.cpu===null?process.execPath:'taskset';
  const argv=manifest.config.cpu===null?nodeArgs:['-c',manifest.config.cpu,process.execPath,...nodeArgs];
  return supervise(cmd,argv,{directory:path.join(output,label),env:environment(manifest,api),timeoutMs});
}
function selectedCases(file) {
  const document=json(file),cases=Array.isArray(document)?document:document.cases;
  if(!Array.isArray(cases)||!cases.length)throw Error('Nonempty selection required');
  return cases.map(row=>({...row,...row.file?{file:fs.realpathSync(path.resolve(path.dirname(file),row.file))}:{},lanes:row.lanes??(row.lane?[row.lane]:['check'])}));
}
function snapshot(config, output) {
  const root=path.join(output,'snapshot'),sources=[];
  const files=[...walk(path.join(config.project,'src')),...walk(path.join(config.project,'tools/conformance')).filter(f=>f.endsWith('.mjs')),
    ...['typed-driver','stage0-library','assemble','compiler-abi','native-build','node-resource-args'].map(name=>path.join(config.project,'tools',name+'.mjs')),
    ...walk(path.join(config.project,'tools/development')).filter(f=>f.endsWith('.mjs')),
    ...walk(path.join(config.project,'tests/frontend/phase2-rules'))];
  for(const file of files){const original=identity(file),relative=path.relative(config.project,file),destination=path.join(root,relative);fs.mkdirSync(path.dirname(destination),{recursive:true});fs.copyFileSync(file,destination);sources.push({original,frozen:identity(destination)});}
  for(const {original,frozen} of sources){verifyIdentity(original);verifyIdentity(frozen);if(original.sha256!==frozen.sha256)throw Error('Snapshot mismatch');}
  fs.mkdirSync(path.join(root,'dist'),{recursive:true});
  return {root,sources};
}
export async function verifyAttempt(directory) {
  const file=path.join(directory,'attempt.json'),m=json(file);
  if(m.kind!=='bend-development-attempt'||m.version!==1||m.checked!==true)throw Error('No completed checked build; use a fresh attempt');
  if(process.execPath!==m.node.file||process.version!==m.node.version)throw Error('Node identity differs from checked attempt');
  verifyIdentity(m.node);verifyIdentity(m.base);verifyIdentity(m.runtime);
  for(const {frozen} of m.snapshot.sources)verifyIdentity(frozen);
  for(const item of m.artifacts)verifyIdentity(item);
  verifyIdentity(m.api);
  verifyBootstrap(m.checkedApi.file,m.bootstrapReport.file,m.base.file);
  if(m.artifactKind==='derived-b1'){
    verifyIdentity(m.derivationReport);
    const helper=await import(pathToFileURL(path.join(m.snapshot.root,'tools/development/equality.mjs')));
    const derived=await helper.verifyEqualityDerivation(m.derivationReport.file),actual=identity(derived.api);
    if(actual.canonicalPath!==m.api.canonicalPath||actual.sha256!==m.api.sha256)throw Error('Selected API differs from verified derivation');
    if(derived.metadata.original.api.canonicalPath!==m.checkedApi.canonicalPath||derived.metadata.original.api.sha256!==m.checkedApi.sha256||derived.metadata.original.bootstrapReport.sha256!==m.bootstrapReport.sha256)
      throw Error('Derivation belongs to another checked build');
  }else if(m.artifactKind!=='checked-b1')throw Error('Unsupported development artifact kind');
  else if(m.api.canonicalPath!==m.checkedApi.canonicalPath||m.api.sha256!==m.checkedApi.sha256)throw Error('Selected API differs from checked bootstrap');
  return m;
}
export function observationHealth(report) {
  return !!report.finished&&Array.isArray(report.results)&&report.results.length===report.selection?.requested?.length&&
    report.changedInputs?.length===0&&report.identity?.changedArtifacts?.length===0&&report.identity.adapterChangedDuringRun===false&&
    (!report.workers||report.workers.every(w=>w.errors.length===0))&&
    report.results.every(row=>!['crash','timeout','unsupported'].includes(row.status)&&!['crash','timeout','unsupported'].includes(row.result?.status));
}
export async function validateAttempt(directory, selection, output, {fullFrontend=false}={}) {
  directory=fs.realpathSync(directory);output=path.resolve(output);
  const m=await verifyAttempt(directory);fs.mkdirSync(output,{recursive:false});
  const report={kind:'bend-development-validation',version:1,started:new Date().toISOString(),complete:false,pass:false,
    artifactKind:m.artifactKind,attempt:identity(path.join(directory,'attempt.json')),api:m.api,launcher:launcherInputs(output),scope:'Selected paired probes; no full-language conformance inferred.',phases:[]};
  const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');save();
  try {
    const cases=selectedCases(selection);report.selection=identity(selection);write(path.join(output,'selection.json'),{cases});
    const prime=await command(m,'prepare-base',path.join(m.snapshot.root,'tools/typed-driver.mjs'),['--prepare-base'],output,m.api.file,180000);
    report.phases.push({name:'prepare-base',execution:prime});save();requireExecution(prime);
    report.cache=validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
    const target={upstream:m.config.upstream,selection:path.join(output,'selection.json'),jobs:m.config.jobs,workerMode:cases.every(c=>c.lanes.every(l=>['parse','check'].includes(l)))?'persistent':'isolated',recycleAfter:m.config.recycleAfter,
      rssLimitMb:m.config.heapMb,heapMb:m.config.heapMb,stackKb:4096,timeoutMs:m.config.timeoutMs,retain:'failed'};
    if(m.artifactKind==='checked-b1')Object.assign(target,{api:m.api.file,runtime:m.runtime.file,bootstrapReport:m.bootstrapReport.file});
    else target.candidateAdapter=path.join(m.snapshot.root,'tools/conformance/adapters/typed.mjs');
    const configFile=path.join(output,'target.json');write(configFile,target);
    const selected=await command(m,'selected-command',path.join(m.snapshot.root,'tools/conformance/target.mjs'),[configFile,path.join(output,'selected')],output,m.api.file,m.config.phaseTimeoutMs);
    report.phases.push({name:'selected',execution:selected});save();requireExecution(selected,[0,1]);
    const paired=json(path.join(output,'selected/paired.json'));
    const reference=json(path.join(output,'selected/reference.json')),candidate=json(path.join(output,'selected/candidate.json'));
    if(!observationHealth(reference)||!observationHealth(candidate)||paired.error)throw Error('Selected observations incomplete');
    report.selected={file:identity(path.join(output,'selected/paired.json')),selectedComplete:paired.selectedComplete,exactDifferences:paired.rows.filter(row=>!row.exactAgreement).length,discrepancies:paired.discrepancies.length,reference:reference.summary,candidate:candidate.summary};
    report.strictExact=m.config.strictExact??false;
    report.pass=paired.selectedComplete&&selected.exitCode===0&&(!report.strictExact||report.selected.exactDifferences===0);
    if(fullFrontend&&report.pass){
      const file=path.join(output,'frontend.json');
      const args=['--upstream',m.config.upstream,'--adapter',path.join(m.snapshot.root,'tools/conformance/adapters/typed.mjs'),'--output',file,'--lanes','parse,check','--jobs',String(m.config.jobs),'--worker-mode','persistent','--recycle-after',String(m.config.recycleAfter),'--rss-limit-mb',String(m.config.heapMb),'--timeout',String(m.config.timeoutMs),'--stack-kb','4096','--heap-mb',String(m.config.heapMb),'--retain','failed','--selected-exit','1'];
      const execution=await command(m,'frontend-command',path.join(m.snapshot.root,'tools/conformance/run.mjs'),args,output,m.api.file,m.config.fullTimeoutMs);
      report.phases.push({name:'frontend',execution});save();requireExecution(execution,[0,1]);
      const observations=json(file);if(!observationHealth(observations)||observations.results.length!==observations.inventory.total*2)throw Error('Full frontend observations incomplete');
      report.frontend={file:identity(file),observationsComplete:true,strictPass:observations.selectedComplete,summary:observations.summary};
      report.pass &&= observations.selectedComplete&&execution.exitCode===0;
    }else if(fullFrontend)report.frontend={skipped:'Focused paired gate failed; inspect selected evidence before widening validation.'};
    await verifyAttempt(directory);verifyIdentity(report.attempt);verifyIdentity(report.selection);verifyIdentity(report.cache);verifyLauncher(report.launcher);
    report.complete=true;
  }catch(error){report.error=String(error.stack??error);}
  report.finished=new Date().toISOString();save();return report;
}
export async function runDevelopment(configFile, output) {
  configFile=fs.realpathSync(configFile);const config=configuration(json(configFile),path.dirname(configFile));output=path.resolve(output);
  fs.mkdirSync(output,{recursive:false});
  const report={kind:'bend-development-build',version:1,complete:false,started:new Date().toISOString(),config:identity(configFile),launcher:launcherInputs(output),phases:[]};
  const save=()=>fs.writeFileSync(path.join(output,'build.json'),JSON.stringify(report,null,2)+'\n');save();
  try {
    const frozen=snapshot(config,output),api=path.join(output,'api.mjs'),base=fs.realpathSync(path.join(config.upstream,'bend2/base.bend'));
    const manifest={kind:'bend-development-attempt',version:1,config,snapshot:frozen,node:{...identity(process.execPath),version:process.version},base:identity(base),runtime:identity(path.join(frozen.root,'src/runtime.mjs'))};
    const execution=await command(manifest,'bootstrap',path.join(frozen.root,'tools/typed-driver.mjs'),['--bootstrap'],output,api,180000);
    report.phases.push({name:'bootstrap',execution});save();requireExecution(execution);
    const bootstrapFile=api+'.bootstrap.json',build=verifyBootstrap(api,bootstrapFile,base);
    manifest.checked=true;manifest.artifactKind='checked-b1';manifest.checkedApi=identity(api);manifest.api=identity(api);manifest.bootstrapReport=identity(bootstrapFile);
    manifest.artifacts=[manifest.checkedApi,manifest.bootstrapReport,...build.provenance.inputs.map(item=>identity(item.file))];
    if(config.profile==='equality'){
      const helper=await import(pathToFileURL(path.join(frozen.root,'tools/development/equality.mjs')));
      const derived=await helper.deriveEquality({api,bootstrapReport:bootstrapFile,outputDirectory:path.join(output,'equality')});
      await helper.verifyEqualityDerivation(derived.report);
      manifest.api=identity(derived.api);manifest.artifactKind='derived-b1';manifest.derivationReport=identity(derived.report);manifest.artifacts.push(manifest.api,manifest.derivationReport);
    }
    for(const {frozen:entry} of frozen.sources)verifyIdentity(entry);
    verifyIdentity(report.config);verifyLauncher(report.launcher);write(path.join(output,'attempt.json'),manifest);
    report.complete=true;report.artifactKind=manifest.artifactKind;report.api=manifest.api;report.finished=new Date().toISOString();save();
    const selection=config.selection??path.join(frozen.root,'tests/frontend/phase2-rules/cases.json');
    const validation=await validateAttempt(output,selection,path.join(output,'validation-001'),{fullFrontend:config.fullFrontend});
    return {build:report,validation};
  }catch(error){report.error=String(error.stack??error);report.finished=new Date().toISOString();save();return {build:report};}
}

if(process.argv[1]&&path.resolve(process.argv[1])===import.meta.filename){
  const [mode,...args]=process.argv.slice(2);
  try {
    let result;
    if(mode==='run'&&args.length===2)result=await runDevelopment(...args);
    else if(mode==='validate'&&args.length===3)result=await validateAttempt(...args);
    else throw Error('Usage: workflow.mjs run CONFIG.json NEW_ATTEMPT | validate ATTEMPT SELECTION.json NEW_VALIDATION');
    console.log(JSON.stringify({complete:result.complete??result.validation?.complete??result.build.complete,pass:result.pass??result.validation?.pass,exactDifferences:result.selected?.exactDifferences??result.validation?.selected?.exactDifferences,strictExact:result.strictExact??result.validation?.strictExact,artifactKind:result.artifactKind??result.build.artifactKind,error:result.error??result.validation?.error??result.build?.error}));
    if(!(result.pass??result.validation?.pass))process.exitCode=1;
  }catch(error){console.error(error.stack??error);process.exitCode=1;}
}
