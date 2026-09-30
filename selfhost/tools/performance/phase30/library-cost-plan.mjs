// Freeze identities for a later exclusive checked-library cost comparison.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [finalAttemptArg,finalTransferArg,outArg]=process.argv.slice(2);
assert.ok(finalAttemptArg&&finalTransferArg&&outArg);
const finalAttempt=fs.realpathSync(finalAttemptArg),finalTransfer=fs.realpathSync(finalTransferArg),out=path.resolve(outArg);
const root=path.resolve(import.meta.dirname,'../../../..');fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs=new Map(),add=file=>{const item=identity(file);inputs.set(item.file,item);return item};
const read=file=>JSON.parse(fs.readFileSync(file));
const attempts={typescript:path.join(root,'selfhost/build/phase29/attempt-04'),phase29:path.join(root,'selfhost/build/phase29/attempt-04'),candidate:finalAttempt};
const variants={};
for(const [name,attempt]of Object.entries(attempts)){
 const prior=read(path.join(attempt,'attempt.json')),verifier=path.join(prior.snapshot.root,'tools/development/workflow.mjs');
 const helper=await import(pathToFileURL(verifier)),m=await helper.verifyAttempt(attempt);
 const typescript=name==='typescript',cache=typescript?null:helper.validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
 variants[name]={typescript,attempt,manifest:add(path.join(attempt,'attempt.json')),verifier:add(verifier),api:m.api,runtime:m.runtime,base:m.base,
  driver:add(path.join(m.snapshot.root,'tools/typed-driver.mjs')),upstream:m.config.upstream,cache};
 for(const item of [m.node,m.api,m.runtime,m.base,m.bootstrapReport,...m.artifacts,...m.snapshot.sources.map(x=>x.frozen),...(cache?[cache]:[])])add(item.file);
}
assert.equal(variants.phase29.base.sha256,variants.candidate.base.sha256);
assert.equal(variants.typescript.upstream,variants.candidate.upstream);
const walk=dir=>fs.readdirSync(dir,{withFileTypes:true}).sort((a,b)=>a.name.localeCompare(b.name)).flatMap(e=>e.isDirectory()?walk(path.join(dir,e.name)):[path.join(dir,e.name)]);
for(const file of walk(path.join(variants.typescript.upstream,'bend2')).filter(f=>/\.(ts|bend|mjs|js)$/.test(f)))add(file);
const cases=[];
for(const name of ['mandelbrot','editdist']){
 const source=add(path.join(root,'selfhost/tools/performance/phase28/corpus',name+'.bend'));
 const finalModule=path.join(finalTransfer,name,'candidate.mjs'),saved12=path.join(root,'selfhost/build/phase30/transfer-12',name,'candidate.mjs.json');
 const provenance12=read(saved12);assert.equal(provenance12.input.sha256,source.sha256);add(saved12);
 const paths={typescript:path.join(root,'selfhost/build/phase28/runtime-01',name,'upstream.mjs'),
  phase29:path.join(root,'selfhost/build/phase29/transfer-04',name,'candidate.mjs'),candidate:finalModule};
 const expected={},receipts={};
 for(const [side,file]of Object.entries(paths)){
  const receiptFile=file+'.json',r=read(receiptFile);assert.equal(r.complete,true);assert.equal(r.input.sha256,source.sha256);
  if(side==='typescript')assert.equal(r.checked,true);
  else {assert.equal(r.observation.checked,true);assert.equal(r.attempt.sha256,variants[side].manifest.sha256);}
  expected[side]=add(file);assert.equal(r.output.sha256,expected[side].sha256);receipts[side]=add(receiptFile);
 }
 cases.push({id:name,source,expected,receipts,originalTransfer12:identity(saved12)});
}
const worker=path.join(out,'worker.mjs');fs.copyFileSync(path.join(import.meta.dirname,'library-cost-worker.mjs'),worker,fs.constants.COPYFILE_EXCL);
for(const file of [import.meta.filename,path.join(import.meta.dirname,'library-cost-worker.mjs'),path.join(import.meta.dirname,'library-cost-run.mjs'),
 path.join(root,'design/phase30/checked-library-compilation-cost.md'),path.join(root,'selfhost/tools/development/process.mjs'),process.execPath,worker])add(file);
const config={kind:'phase30-checked-library-cost-plan',complete:true,cpu:'0',samples:3,timeoutMs:180000,
 node:identity(process.execPath),worker:identity(worker),variants,cases,order:['typescript','phase29','candidate'],inputs:[...inputs.values()],
 scope:'Normal checked library request on identical source, each compiler with its own existing validated Base pipeline. No verdict; no emission-only claim. Fresh CPU0 processes, rotated three samples, all output bytes retained.'};
for(const item of config.inputs)assert.deepEqual(identity(item.file),item);
fs.writeFileSync(path.join(out,'config.json'),JSON.stringify(config,null,2)+'\n',{flag:'wx'});
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-plan.mjs'),fs.constants.COPYFILE_EXCL);
console.log(JSON.stringify({complete:true,config:path.join(out,'config.json'),finalAttempt,cases:cases.map(x=>x.id),inputs:inputs.size}));
