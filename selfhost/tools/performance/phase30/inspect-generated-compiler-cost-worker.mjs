// Receipt-bound small compiler request; H is an output, never a fake attempt.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';import {spawnSync} from 'node:child_process';
const [requestFile,resultFile]=process.argv.slice(2),r=JSON.parse(fs.readFileSync(requestFile)),p=r.plan;
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:hash(file),bytes:fs.statSync(file).size});
const verify=()=>{for(const item of p.inputs)assert.equal(hash(item.file),item.sha256)};
const report={kind:'phase30-generated-compiler-small-worker',complete:false,pass:false,mode:r.mode,variant:r.variant,
 node:process.version,args:process.execArgv,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),
 requests:[],scope:p.scope};
const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n');save();
try{
 verify();const selected=p.variants[r.variant];assert.deepEqual(identity(selected.file),selected);
 for(const key of Object.keys(process.env))if(key.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(key))delete process.env[key];
 Object.assign(process.env,{BEND_TYPED_API:selected.file,BEND_TYPED_RUNTIME:p.runtime.file,BEND_BASE:p.base.file,BEND_TYPED_TRACE:''});
 const imported=performance.now(),D=await import(pathToFileURL(p.driver.file)),api=await D.loadApi();report.importMs=performance.now()-imported;
 for(const [name,value]of Object.entries(p.abi))assert.equal(api[name](),value);
 const location=createHash('sha256').update(fs.realpathSync(p.base.file)).digest('hex');
 const cacheFile=path.join(D.project,'build/typed/cache',`base-${selected.sha256}-${p.base.sha256}-${location}.json`);
 const before=fs.existsSync(cacheFile)?identity(cacheFile):null;
 if(r.mode==='trial')assert.deepEqual(before,r.prepared.cache.after,'Prepared cache changed before trial');
 const prepareStart=performance.now(),cache=await D.prepareBase(api);report.prepareBaseMs=performance.now()-prepareStart;
 const after=identity(cacheFile);assert.equal(cache.compilerSha256,selected.sha256);assert.equal(cache.baseSha256,p.base.sha256);assert.equal(cache.validatedBy,'check_book');
 report.cache={before,after,disposition:before?(before.sha256===after.sha256?'validated-existing':'replaced-invalid'):'created',compilerSha256:cache.compilerSha256,validatedBy:cache.validatedBy};
 if(r.mode==='trial')assert.deepEqual(after,r.prepared.cache.after);save();
 const count=r.mode==='prepare'?1:p.warmRequests+p.timedRequests;assert.ok(['prepare','trial'].includes(r.mode));
 for(let i=0;i<count;i++){
  const start=performance.now(),result=await D.inspect(p.source.file,{mode:'library',api}),elapsedMs=performance.now()-start;
  const {code,...observation}=result;assert.equal(result.status,'ok');assert.equal(result.checked,true);assert.equal(typeof code,'string');
  const digest=createHash('sha256').update(code).digest('hex');assert.equal(digest,p.expected.sha256);
  if(r.mode==='trial')assert.deepEqual(observation,r.prepared.observation);
  report.requests.push({kind:r.mode==='prepare'?'preparation':i===0?'warm':'timed',elapsedMs,outputSha256:digest});
  if(r.mode==='prepare'){
   report.observation=observation;const output=path.join(path.dirname(resultFile),'prepared.mjs');fs.writeFileSync(output,code,{flag:'wx'});report.output=identity(output);
   const runner=path.join(path.dirname(resultFile),'execute.mjs');fs.writeFileSync(runner,'import target from '+JSON.stringify(pathToFileURL(output).href)+';import assert from "node:assert/strict";const result=target.main();assert.equal(result,8);console.log(JSON.stringify({result}));\n',{flag:'wx'});
   const stdoutFile=path.join(path.dirname(resultFile),'program.stdout'),stderrFile=path.join(path.dirname(resultFile),'program.stderr');
   const stdout=fs.openSync(stdoutFile,'wx'),stderr=fs.openSync(stderrFile,'wx');let child;
   try{child=spawnSync(process.execPath,['--stack-size=4096','--max-old-space-size=1024',runner],{timeout:10000,stdio:['ignore',stdout,stderr]})}finally{fs.closeSync(stdout);fs.closeSync(stderr)}
   const stdoutText=fs.readFileSync(stdoutFile,'utf8'),stderrText=fs.readFileSync(stderrFile,'utf8');
   report.program={status:child.status,signal:child.signal,error:child.error?String(child.error):null,stdout:identity(stdoutFile),stderr:identity(stderrFile)};assert.equal(child.status,0);assert.equal(child.error,undefined);assert.equal(stderrText,'');assert.equal(JSON.parse(stdoutText).result,p.expectedResult);
  }
  save();
 }
 if(r.mode==='trial'){
  const values=report.requests.filter(x=>x.kind==='timed').map(x=>x.elapsedMs);assert.equal(values.length,2);
  report.meanRequestMs=(values[0]+values[1])/2;report.secondVsFirstPercent=(values[1]/values[0]-1)*100;
 }
 verify();assert.deepEqual(identity(cacheFile),after);report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
report.maxRssKiB=process.resourceUsage().maxRSS;save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,variant:r.variant,mode:r.mode,meanRequestMs:report.meanRequestMs,error:report.error}));
