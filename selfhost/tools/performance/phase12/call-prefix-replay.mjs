// Counterfactual exact-request-history replay. This does not change any gate.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {identity,verifyIdentity,verifyAttempt,validatedCache} from '../../development/workflow.mjs';
import {createPersistentRunner,resultDigest,validatePersistentReplay} from '../../conformance/persistent-probe.mjs';
const [requestArg,outArg]=process.argv.slice(2),requestFile=path.resolve(requestArg),out=path.resolve(outArg);fs.mkdirSync(out);
const old=JSON.parse(fs.readFileSync(requestFile)),oldIdentity=JSON.parse(fs.readFileSync(old.identityFile)),session=JSON.parse(fs.readFileSync(old.workerSession.file));
validatePersistentReplay(old,session,oldIdentity.workerNodeArgs);assert.equal(oldIdentity.node,process.execPath);assert.equal(oldIdentity.nodeVersion,process.version);assert.deepEqual(oldIdentity.workerNodeArgs,['--stack-size=4096','--max-old-space-size=4096']);
const inputMap=new Map(),add=file=>{const i=identity(file);inputMap.set(i.file,i);return i};
for(const f of [import.meta.filename,process.execPath,requestFile,old.identityFile,old.workerSession.file,session.worker])add(f);
for(const [file,hash] of Object.entries(oldIdentity.inputHashes)){const actual=fs.existsSync(file)?identity(file).sha256:null;assert.equal(actual,hash,'Original input drift: '+file);if(actual)add(file);}
for(const [file,canonical] of Object.entries(oldIdentity.inputPaths??{}))assert.equal(fs.existsSync(file)?fs.realpathSync(file):null,canonical);
for(const [name,file] of [['original-request.json',requestFile],['original-identity.json',old.identityFile],['original-session.json',old.workerSession.file],['consumed-tool.mjs',import.meta.filename]])fs.copyFileSync(file,path.join(out,name));
const attempts={baseline:'selfhost/build/phase11/integrated-01',leaf:'selfhost/build/phase12/integrated-02',A:'selfhost/build/phase12/call-native-maintained-01/attempt'};
const report={kind:'phase12-matched-prefix-counterfactual',complete:false,inputs:[],original:{request:identity(requestFile),identity:identity(old.identityFile),session:identity(old.workerSession.file),targetIndex:old.workerSession.index},order:['baseline','leaf','A'],variants:{},rows:[],scope:'Original53requests through failure, same byte-verified worker/adapter/host/runtime/Base and4MiBstack4GiBheap; only compiler image plus private identity-bound cache/project and output paths vary. Original prefix integrity is verified before substitutions. CPU3. No timing or promotion claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(const [name,attemptDir] of Object.entries(attempts)){
  const m=await verifyAttempt(path.resolve(attemptDir)),directory=path.join(out,name),project=path.join(directory,'project');fs.mkdirSync(directory);fs.mkdirSync(project);
  for(const n of ['src','tools'])fs.cpSync(path.join(m.snapshot.root,n),path.join(project,n),{recursive:true});
  const oldCache=validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file),cacheDir=path.join(project,'build/typed/cache');fs.mkdirSync(cacheDir,{recursive:true});fs.copyFileSync(oldCache.file,path.join(cacheDir,path.basename(oldCache.file)));
  const cache=validatedCache(cacheDir,m.api.file,m.base.file),adapter=path.join(project,'tools/conformance/adapters/typed.mjs');assert.equal(identity(adapter).sha256,session.adapterSha256);
  for(const n of ['typed-driver.mjs','compiler-abi.mjs','node-resource-args.mjs'])assert.equal(identity(path.join(project,'tools',n)).sha256,identity(path.join(path.dirname(old.adapter),'../../',n)).sha256,'Host drift: '+n);
  assert.equal(m.runtime.sha256,oldIdentity.identity.artifacts.runtime.sha256);assert.equal(m.base.sha256,oldIdentity.identity.artifacts.base.sha256);
  for(const f of [path.join(attemptDir,'attempt.json'),m.api.file,m.runtime.file,m.base.file,oldCache.file,cache.file,adapter,path.join(project,'tools/typed-driver.mjs'),path.join(project,'tools/compiler-abi.mjs'),path.join(project,'src/compiler.json')])add(f);
  const environment={...oldIdentity.environment,BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file,BEND_UPSTREAM:m.config.upstream};
  const identityFile=path.join(directory,'substitution-identity.json'),substitution={kind:'explicit-replay-counterfactual',original:report.original,variant:name,api:m.api,cache,adapter:identity(adapter),project,environment,changes:['compiler image','same-bytes private host project','per-image validated cache','output work/response/identity paths']};fs.writeFileSync(identityFile,JSON.stringify(substitution,null,2)+'\n');add(identityFile);
  report.variants[name]={directory,project,adapter,identityFile,environment,api:m.api,cache};
 }
 report.inputs=[...inputMap.values()];save();
 for(const name of report.order){
  report.inputs.forEach(verifyIdentity);const v=report.variants[name];for(const key of oldIdentity.environmentKeys)delete process.env[key];delete process.env.NODE_OPTIONS;Object.assign(process.env,v.environment);
  const runner=createPersistentRunner({directory:path.join(v.directory,'worker'),workerNodeArgs:oldIdentity.workerNodeArgs,worker:session.worker,recycleAfter:session.recycleAfter,rssLimitMb:session.rssLimitMb});
  const row={name,requests:[],complete:false};report.rows.push(row);save();
  try{
   for(let i=0;i<=old.workerSession.index;i++){
    const recorded=session.requests[i].request,dir=path.join(v.directory,'request-'+i);fs.mkdirSync(dir);
    const request={...recorded,adapter:v.adapter,project:v.project,identityFile:v.identityFile,workdir:dir,response:path.join(dir,'response.json'),workerSession:undefined};
    for(const k of ['done','workerStdout','workerStderr'])delete request[k];
    const execution=await runner.run(request),result=execution.result;
    assert.ok(!['crash','timeout'].includes(result.status),'Worker launch/protocol/resource error: '+JSON.stringify(result));
    assert.equal(execution.worker.index,i,'Unexpected worker recycle');assert.equal(execution.worker.generation,1,'Unexpected worker generation');
    row.requests.push({index:i,id:recorded.test.id,lane:recorded.lane,result,worker:execution.worker,resultDigest:resultDigest(result),originalResultDigest:session.requests[i].resultDigest,exactOriginal:resultDigest(result)===session.requests[i].resultDigest});
    save();
   }
   row.complete=true;row.prefixExact=row.requests.slice(0,-1).every(x=>x.exactOriginal);row.target=row.requests.at(-1);assert.ok(row.prefixExact,'Pre-target results differ');assert.equal(runner.errors.length,0);report.inputs.forEach(verifyIdentity);
  }finally{runner.close();row.runner={stats:runner.stats,errors:runner.errors};save();}
  console.log(JSON.stringify({variant:name,complete:row.complete,prefixExact:row.prefixExact,target:row.target.result}));
 }
 report.complete=true;report.inputsVerified=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
save();
