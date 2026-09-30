// Small B1/H functional gate using the unchanged frozen driver and ABI adapter.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';import {spawnSync} from 'node:child_process';
const [planArg,apiArg,outArg,mode,referenceArg]=process.argv.slice(2);
const planFile=fs.realpathSync(planArg),plan=JSON.parse(fs.readFileSync(planFile)),apiFile=fs.realpathSync(apiArg),out=path.resolve(outArg);
assert.ok(['base','oracle'].includes(mode));fs.mkdirSync(out,{recursive:false});
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:hash(file),bytes:fs.statSync(file).size});
const verify=()=>{for(const item of plan.inputs){assert.equal(fs.realpathSync(item.file),item.canonicalPath??item.file);assert.equal(hash(item.file),item.sha256)}};
const apiIdentity=identity(apiFile),report={kind:'phase30-self-emission-small-oracle',complete:false,pass:false,mode,
 inputs:[identity(planFile),identity(import.meta.filename),apiIdentity],node:{path:process.execPath,version:process.version,args:process.execArgv},
 affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:')),
 scope:'Small functional and cache gate only; no fixed-point or full H conformance claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-oracle.mjs'));
try{
 verify();
 if(apiFile!==fs.realpathSync(plan.api.file)){
  assert.equal(apiFile,fs.realpathSync(plan.output));const receiptFile=apiFile+'.json',receipt=JSON.parse(fs.readFileSync(receiptFile));
  assert.equal(receipt.complete,true);assert.equal(receipt.input.sha256,plan.source.sha256);assert.equal(receipt.output.sha256,apiIdentity.sha256);
  assert.equal(receipt.attempt.sha256,plan.attempt.sha256);report.inputs.push(identity(receiptFile));
 }else assert.equal(apiIdentity.sha256,plan.api.sha256);
 for(const key of Object.keys(process.env))if(key.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(key))delete process.env[key];
 Object.assign(process.env,{BEND_TYPED_API:apiFile,BEND_TYPED_RUNTIME:plan.runtime.file,BEND_BASE:plan.base.file,BEND_TYPED_TRACE:'1'});
 const D=await import(pathToFileURL(plan.driver.file)),api=await D.loadApi();
 report.abi={};for(const [name,expected] of Object.entries(plan.oracle.requiredAbi)){assert.equal(typeof api[name],'function');report.abi[name]=api[name]();assert.equal(report.abi[name],expected)}save();
 const basePath=fs.realpathSync(plan.base.file),location=createHash('sha256').update(basePath).digest('hex');
 const cacheFile=path.join(D.project,'build/typed/cache',`base-${apiIdentity.sha256}-${plan.base.sha256}-${location}.json`);
 const before=fs.existsSync(cacheFile)?identity(cacheFile):null,cached=await D.prepareBase(api),after=identity(cacheFile);
 assert.equal(cached.compilerSha256,apiIdentity.sha256);assert.equal(cached.baseSha256,plan.base.sha256);assert.equal(cached.validatedBy,'check_book');
 const stored=JSON.parse(fs.readFileSync(cacheFile));assert.equal(stored.compilerSha256,apiIdentity.sha256);assert.equal(stored.bookSha256,cached.bookSha256);
 report.cache={before,after,disposition:before?(before.sha256===after.sha256?'validated-existing':'replaced-invalid'):'created',
  compilerSha256:cached.compilerSha256,baseSha256:cached.baseSha256,bookSha256:cached.bookSha256,validatedBy:cached.validatedBy,generated:cached.generated};save();
 if(mode==='oracle'){
  const positive=await D.inspect(plan.fixtures.positive.file,{mode:'library',api}),{code,...observation}=positive;
  report.positive=observation;assert.equal(positive.status,'ok');assert.equal(positive.checked,true);assert.equal(typeof code,'string');
  const program=path.join(out,'small.mjs');fs.writeFileSync(program,code,{flag:'wx'});report.program=identity(program);save();
  const negative=await D.inspect(plan.fixtures.negative.file,{mode:'check',api});report.negative=negative;
  assert.equal(negative.status,plan.oracle.negativeStatus);assert.equal(negative.phase,plan.oracle.negativePhase);assert.equal(negative.checked,true);
  const runner=path.join(out,'small-run.mjs');fs.writeFileSync(runner,
   'import target from '+JSON.stringify(pathToFileURL(program).href)+';\nimport assert from "node:assert/strict";\nconst result=target.main();assert.equal(result,'+plan.oracle.positiveResult+');console.log(JSON.stringify({result}));\n',{flag:'wx'});
  const stdoutFile=path.join(out,'small.stdout'),stderrFile=path.join(out,'small.stderr'),stdout=fs.openSync(stdoutFile,'wx'),stderr=fs.openSync(stderrFile,'wx');
  let child;try{child=spawnSync(process.execPath,['--stack-size=4096','--max-old-space-size=1024',runner],{timeout:plan.resources.programTimeoutSeconds*1000,stdio:['ignore',stdout,stderr],env:process.env})}finally{fs.closeSync(stdout);fs.closeSync(stderr)}
  report.execution={status:child.status,signal:child.signal,error:child.error?String(child.error):null,stdout:identity(stdoutFile),stderr:identity(stderrFile)};save();
  assert.equal(child.status,0);assert.equal(child.error,undefined);assert.equal(fs.readFileSync(stderrFile,'utf8'),'');
  report.result=JSON.parse(fs.readFileSync(stdoutFile,'utf8')).result;assert.equal(report.result,plan.oracle.positiveResult);
  if(referenceArg){const reference=JSON.parse(fs.readFileSync(referenceArg));report.inputs.push(identity(referenceArg));assert.equal(reference.complete,true);assert.equal(reference.pass,true);
   assert.deepEqual(report.positive,reference.positive);assert.deepEqual(report.negative,reference.negative);assert.equal(report.result,reference.result);report.sameB1Observations=true;
   report.smallOutputBytesEqual=report.program.sha256===reference.program.sha256;
  }
 }
 verify();assert.equal(hash(apiFile),apiIdentity.sha256);report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
report.maxRssKiB=process.resourceUsage().maxRSS;save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,mode,result:report.result,cache:report.cache?.disposition,error:report.error}));
