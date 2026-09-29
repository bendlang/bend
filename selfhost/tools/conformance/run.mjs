#!/usr/bin/env node
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawn} from 'node:child_process';
import {pathToFileURL} from 'node:url';
import {inventory,probes,sha256,walk,PIN_MANIFEST} from './inventory.mjs';
import {selectProbes,successful} from './selection.mjs';
import {runProbe} from './run-probe.mjs';
import {createPersistentRunner} from './persistent-probe.mjs';
import {judge} from './judge.mjs';

const project=path.resolve(import.meta.dirname,'../..');
const options={upstream:process.env.BEND_UPSTREAM||path.join(project,'.bootstrap/upstream-phase23'),
  adapter:path.join(import.meta.dirname,'adapters/prototype.mjs'),output:path.join(project,'tests/conformance/latest.json'),
  jobs:8,timeout:5000,'worker-mode':'isolated','recycle-after':'64','rss-limit-mb':'1024',lanes:'parse,check,interpreter,js,native,metal,cuda',filter:'',gpu:'','stack-kb':0,'heap-mb':0,selection:'',rerun:'',retain:'none','selected-exit':'0'};
for(let i=2;i<process.argv.length;i++) {
  const arg=process.argv[i];
  if(arg==='--help') {
    console.log('node tools/conformance/run.mjs [--upstream PATH] [--adapter PATH] [--output PATH] [--jobs N] [--timeout MS] [--worker-mode isolated|persistent] [--recycle-after N] [--rss-limit-mb N] [--stack-kb N] [--heap-mb N] [--lanes parse,check,interpreter,js,native,metal,cuda] [--filter REGEX] [--gpu metal,cuda] [--selection JSON] [--rerun REPORT] [--retain none|failed|all] [--selected-exit 0|1]');
    process.exit(0);
  }
  const key=arg.slice(2);
  if(!arg.startsWith('--')||!(key in options)||process.argv[i+1]===undefined) throw Error('Unknown/incomplete option '+arg);
  options[key]=process.argv[++i];
}
for(const key of ['upstream','adapter','output']) options[key]=path.resolve(options[key]);
for(const key of ['jobs','timeout']) {
  options[key]=Number(options[key]);
  if(!Number.isSafeInteger(options[key])||options[key]<1||(key==='timeout'&&options[key]>2147483647)) throw Error(`Invalid --${key}`);
}
if(!['isolated','persistent'].includes(options['worker-mode']))throw Error('Invalid --worker-mode');
for(const key of ['recycle-after','rss-limit-mb']) {
  options[key]=Number(options[key]);
  if(!Number.isSafeInteger(options[key])||options[key]<1)throw Error(`Invalid --${key}`);
}
for(const key of ['stack-kb','heap-mb']) {
  options[key]=Number(options[key]);
  if(!Number.isInteger(options[key])||options[key]<0)throw Error(`Invalid --${key}`);
}
const workerNodeArgs=[...(options['stack-kb']?[`--stack-size=${options['stack-kb']}`]:[]),
  ...(options['heap-mb']?[`--max-old-space-size=${options['heap-mb']}`]:[])];
const laneNames=['parse','check','interpreter','js','native','metal','cuda'];
const lanes=options.lanes.split(',');
if(lanes.some(l=>!laneNames.includes(l))) throw Error('Unknown lane');
const manifest=inventory(options.upstream);
const adapter=await import(pathToFileURL(options.adapter));
if(!adapter.capabilities||typeof adapter.probe!=='function') throw Error('Adapter must export capabilities and probe');
const persistent=options['worker-mode']==='persistent';
if(persistent&&(!Array.isArray(adapter.persistentLanes)||typeof adapter.createPersistentSession!=='function'))throw Error('Persistent mode requires adapter persistentLanes and createPersistentSession');
const harnessFiles=['run.mjs','worker.mjs','inventory.mjs','judge.mjs','selection.mjs','run-probe.mjs','replay.mjs',...(persistent?['persistent-probe.mjs','persistent-worker.mjs']:[])];
const initialIdentity={adapter:adapter.name||options.adapter,capabilities:adapter.capabilities,persistentLanes:adapter.persistentLanes??null,workerMode:options['worker-mode'],adapterSha256:sha256(fs.readFileSync(options.adapter)),
  artifacts:Object.fromEntries(Object.entries({...adapter.artifacts,'harness/compilerManifest':PIN_MANIFEST,...Object.fromEntries(harnessFiles.map(file=>['harness/'+file,path.join(import.meta.dirname,file)]))}).map(([name,file])=>[name,{file,sha256:sha256(fs.readFileSync(file))}]))};
if(!['none','failed','all'].includes(options.retain))throw Error('Invalid --retain');
if(!['0','1'].includes(String(options['selected-exit'])))throw Error('Invalid --selected-exit');
for(const key of ['selection','rerun'])if(options[key])options[key]=path.resolve(options[key]);
if((options.selection||options.rerun)&&fs.existsSync(options.output))throw Error('Selected attempts require a fresh output report');
const selected=selectProbes(manifest,{selection:options.selection,rerun:options.rerun,filter:options.filter,lanes});
const {tests,jobs}=selected;
manifest.tests.push(...selected.external);
const inputFiles=new Set([...manifest.tests.map(test=>test.file),...walk(path.join(options.upstream,'tests')),...walk(path.join(options.upstream,'bend2/effs')),...manifest.sources.map(source=>path.join(options.upstream,source.file))]);
for(const test of selected.external)for(const file of walk(path.dirname(test.file)))inputFiles.add(file);
for(const file of typeof adapter.inputFiles==='function'?await adapter.inputFiles({tests}):adapter.inputFiles||[])inputFiles.add(path.resolve(file));
for(const test of tests)if(sha256(fs.readFileSync(test.file))!==test.sha256)throw Error('Fixture changed during selection: '+test.file);
const inputHashes=Object.fromEntries([...inputFiles].map(file=>[file,fs.existsSync(file)?sha256(fs.readFileSync(file)):null]));
const inputPaths=Object.fromEntries([...inputFiles].map(file=>[file,fs.existsSync(file)?fs.realpathSync(file):null]));
fs.mkdirSync(path.dirname(options.output),{recursive:true});
const temporary=options.retain==='none'?fs.mkdtempSync(path.join(os.tmpdir(),'bend-conformance-')):options.output+'.artifacts';
if(options.retain!=='none')fs.mkdirSync(temporary,{recursive:false});
const identityFile=path.join(temporary,'identity.json');
const environmentKeys=['BEND_TYPED_API','BEND_TYPED_RUNTIME','BEND_BASE','BEND_UPSTREAM','BEND_TYPED_TRACE','BEND_NATIVE_MANIFEST_DIRECTORY','BEND_NATIVE_BINARY','BEND_NATIVE_RUNTIME','CC','CPATH','LIBRARY_PATH','LD_LIBRARY_PATH'];
const environment=Object.fromEntries(environmentKeys.filter(key=>process.env[key]!==undefined).map(key=>[key,process.env[key]]));
fs.writeFileSync(identityFile,JSON.stringify({identity:initialIdentity,inputHashes,inputPaths,environment,environmentKeys,workerNodeArgs,node:process.execPath,nodeVersion:process.version},null,2)+'\n');
const results=[];
const workerReports=[];
fs.mkdirSync(path.dirname(options.output),{recursive:true});
const progressFile=options.output.replace(/\.json$/, '')+'.progress.jsonl';
fs.writeFileSync(progressFile,'');
function record(row) {results.push(row);fs.appendFileSync(progressFile,JSON.stringify(row)+'\n');}
let next=0;
const started=new Date().toISOString();


function hardwareGate(lane) {
  if(lane!=='metal'&&lane!=='cuda') return null;
  if(!options.gpu.split(',').includes(lane)) return 'GPU execution requires explicit --gpu '+lane+' on a verified host.';
  if(lane==='metal'&&process.platform!=='darwin') return 'Metal requires an Apple host.';
  if(lane==='cuda'&&!fs.existsSync('/dev/nvidiactl')) return 'CUDA device is unavailable.';
  return null;
}
try {
  await Promise.all(Array.from({length:Math.min(options.jobs,jobs.length)},async(_,slot)=>{
    const runner=persistent?createPersistentRunner({directory:path.join(temporary,`worker-${slot}`),workerNodeArgs,recycleAfter:options['recycle-after'],rssLimitMb:options['rss-limit-mb']}):null;
    try {
    while(next<jobs.length) {
      const index=next++,{test,lane}=jobs[index],start=performance.now();
      const base={id:test.id,namespace:test.namespace,negative:test.negative,failureKind:test.failureKind,lane};
      const gate=hardwareGate(lane);
      if(gate) {record({...base,status:'hardware-gated',reason:gate,implemented:!!adapter.capabilities[lane]});continue;}
      if(persistent&&!adapter.persistentLanes.includes(lane)) {record({...base,status:'unsupported',reason:`Persistent mode does not implement ${lane}; rerun with --worker-mode isolated.`,implemented:false});continue;}
      if(!adapter.capabilities[lane]) {record({...base,status:'unsupported',reason:'Adapter does not implement '+lane});continue;}
      const workdir=path.join(temporary,String(index));fs.mkdirSync(workdir);
      const request={adapter:options.adapter,test,lane,upstream:options.upstream,project,workdir,timeoutMs:options.timeout,response:path.join(workdir,'response.json'),identityFile,workerNodeArgs};
      const execution=runner?await runner.run(request):null;
      const result=execution?execution.result:await runProbe(request,{workerNodeArgs});
      const verdict=judge(test,lane,result,adapter.capabilities);
      const retained=options.retain==='all'||options.retain==='failed'&&!successful({...base,...verdict});
      record({...base,...verdict,ms:Math.round(performance.now()-start),result,...execution?{worker:execution.worker}:{},...retained?{artifacts:workdir,replay:[process.execPath,path.join(import.meta.dirname,'replay.mjs'),path.join(workdir,'request.json')]}:{}});
      if(!retained)fs.rmSync(workdir,{recursive:true,force:true});
    }
    } finally {
      runner?.close();
      if(runner)workerReports[slot]={stats:{...runner.stats},errors:[...runner.errors]};
    }
  }));
} finally {if(options.retain==='none')fs.rmSync(temporary,{recursive:true,force:true});}
results.sort((a,b)=>a.id.localeCompare(b.id)||laneNames.indexOf(a.lane)-laneNames.indexOf(b.lane));
function counts(rows) {return rows.reduce((a,r)=>(a[r.status]=(a[r.status]||0)+1,a),{});}
const summary={tests:tests.length,allTests:manifest.total,externalTests:selected.external.length,excludedTests:manifest.total-(tests.length-selected.external.length),probes:results.length,
  statuses:counts(results),lanes:Object.fromEntries(lanes.map(l=>[l,counts(results.filter(r=>r.lane===l))])),
  namespaces:Object.fromEntries(Object.keys(manifest.namespaces).map(n=>[n,counts(results.filter(r=>r.namespace===n))])),
  checkerRejections:results.filter(r=>r.evidence==='checker-rejection').length,
  proofTrustRejections:results.filter(r=>r.evidence==='proof-trust-rejection').length,
  frontendRejections:results.filter(r=>r.evidence==='frontend-rejection').length,
  uncheckedExecutions:results.filter(r=>r.evidence==='unchecked-execution').length};
const allRequired=manifest.tests.flatMap(t=>probes(t)).length;
const identity=initialIdentity;
identity.finalAdapterSha256=fs.existsSync(options.adapter)?sha256(fs.readFileSync(options.adapter)):null;
identity.adapterChangedDuringRun=identity.finalAdapterSha256!==identity.adapterSha256;
identity.finalArtifactHashes=Object.fromEntries(Object.entries(identity.artifacts).map(([name,artifact])=>[name,fs.existsSync(artifact.file)?sha256(fs.readFileSync(artifact.file)):null]));
identity.changedArtifacts=Object.entries(identity.artifacts).filter(([name,artifact])=>identity.finalArtifactHashes[name]!==artifact.sha256).map(([name])=>name);
const changedInputs=Object.entries(inputHashes).filter(([file,hash])=>(fs.existsSync(file)?sha256(fs.readFileSync(file)):null)!==hash||(fs.existsSync(file)?fs.realpathSync(file):null)!==inputPaths[file]).map(([file])=>file);
const workerHealthy=!persistent||workerReports.length===Math.min(options.jobs,jobs.length)&&workerReports.every(report=>report&&!report.errors.length);
const selectedComplete=!identity.adapterChangedDuringRun&&!identity.changedArtifacts.length&&!changedInputs.length&&workerHealthy&&results.length===jobs.length&&results.every(successful);
const complete=workerHealthy&&!options.selection&&!options.rerun&&!selected.external.length&&!changedInputs.length&&!identity.adapterChangedDuringRun&&!identity.changedArtifacts.length&&tests.length===manifest.total&&results.length===allRequired&&results.every(r=>r.status==='pass'||r.status==='not-applicable'||(r.lane==='parse'&&r.status==='observed'));
if(identity.adapter==='unchecked-prototype') {
  identity.compilerSha256=sha256(fs.readFileSync(process.env.BEND_CONFORMANCE_COMPILER||path.join(project,'dist/bend2c.mjs')));
  identity.runtimeSha256=sha256(fs.readFileSync(process.env.BEND_CONFORMANCE_RUNTIME||path.join(project,'src/runtime.mjs')));
}
const report={schemaVersion:1,started,finished:new Date().toISOString(),host:{platform:process.platform,arch:process.arch,node:process.version,workerNodeArgs,workerMode:options['worker-mode']},workers:persistent?workerReports:null,
  options,identity,complete,selectedComplete,selection:{requested:jobs.map(({test,lane})=>({id:test.id,lane})),previous:selected.previous??null,external:selected.external.map(test=>test.id)},inputHashes,inputPaths,changedInputs,summary,inventory:manifest,results};
fs.mkdirSync(path.dirname(options.output),{recursive:true});fs.writeFileSync(options.output,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({complete,selectedComplete,summary,report:options.output},null,2));
// Unsupported features, gated GPU lanes and filters never turn a full suite green.
if(!(String(options['selected-exit'])==='1'?selectedComplete:complete)) process.exitCode=1;
