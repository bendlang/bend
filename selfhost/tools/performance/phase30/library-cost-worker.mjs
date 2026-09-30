// One fresh normal checked-library compilation, with explicit timing boundaries.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const entered=performance.now(),[requestFile,resultFile]=process.argv.slice(2);
const request=JSON.parse(fs.readFileSync(requestFile));
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const verify=items=>{for(const item of items)assert.deepEqual(identity(item.file),item,'Changed input '+item.file)};
const report={kind:'phase30-checked-library-cost-worker',complete:false,pass:false,variant:request.variant,
 source:request.source,node:process.version,args:process.execArgv,workerEntryMs:entered,
 affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),
 timingBoundary:'Normal checked-library request. Host import separate; Bend lazy API loading and normal Base cache handling remain inside inspect. No emission-only attribution.'};
let verifier;
try{
 verify(request.inputs);
 const preflight=performance.now();
 verifier=await import(pathToFileURL(request.verifier));
 const manifest=await verifier.verifyAttempt(request.attempt);
 assert.equal(manifest.api.sha256,request.api.sha256);
 if(!request.typescript)assert.deepEqual(verifier.validatedCache(path.join(manifest.snapshot.root,'build/typed/cache'),manifest.api.file,manifest.base.file),request.cache);
 report.preflightMs=performance.now()-preflight;
 let B,C,D;
 const beginImport=performance.now();
 if(request.typescript){
  B=await import(pathToFileURL(path.join(request.upstream,'bend2/bend.ts')));
  C=await import(pathToFileURL(path.join(request.upstream,'bend2/comp.ts')));
 }else{
  process.env.BEND_TYPED_API=manifest.api.file;process.env.BEND_TYPED_RUNTIME=manifest.runtime.file;process.env.BEND_BASE=manifest.base.file;
  D=await import(pathToFileURL(request.driver.file));
 }
 report.hostImportMs=performance.now()-beginImport;
 let code;
 const beginRequest=performance.now();
 try{
  if(request.typescript){
   const book=B.book_nil();await B.book_load(book,request.source.file,'',new Map());B.book_valid(book);
   assert.equal(book.hols,0);code=C.js_lib(book,true);report.observation={checked:true,holes:book.hols};
  }else{
   const result=await D.inspect(request.source.file,{mode:'library'});
   assert.equal(result.status,'ok');assert.equal(result.checked,true);
   ({code,...report.observation}=result);
  }
 }finally{report.requestMs=performance.now()-beginRequest}
 report.importAndRequestMs=report.hostImportMs+report.requestMs;
 assert.equal(typeof code,'string');
 fs.writeFileSync(request.output,code,{flag:'wx'});report.output={...identity(request.output),bytes:Buffer.byteLength(code)};
 assert.equal(report.output.sha256,request.expected.sha256,'Independent checked output bytes differ');
 if(!request.typescript)assert.deepEqual(report.observation.files.map(x=>fs.realpathSync(x)).sort(),[request.source.canonicalPath,manifest.base.canonicalPath].sort(),'Unexpected source import closure');
 verify(request.inputs);await verifier.verifyAttempt(request.attempt);
 if(!request.typescript)assert.deepEqual(verifier.validatedCache(path.join(manifest.snapshot.root,'build/typed/cache'),manifest.api.file,manifest.base.file),request.cache);
 report.complete=true;report.pass=true;
}catch(error){report.error=String(error?.stack??error);process.exitCode=1}
report.workerElapsedMs=performance.now()-entered;report.maxRssKiB=process.resourceUsage().maxRSS;
fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify(report));
