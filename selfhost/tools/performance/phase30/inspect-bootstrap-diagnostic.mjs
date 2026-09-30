#!/usr/bin/env node
// Freeze and exercise the bootstrap-only diagnostic boundary; no benchmark.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../../../..');
const [outputArg,frozenSourceArg]=process.argv.slice(2);
if(!outputArg||!frozenSourceArg)throw Error('Usage: inspect-bootstrap-diagnostic.mjs NEW_OUTPUT FROZEN_ATTEMPT02_SOURCE');
const out=path.resolve(outputArg),source=path.resolve(frozenSourceArg);
fs.mkdirSync(out,{recursive:false});
const upstream=fs.realpathSync(process.env.BEND_UPSTREAM||path.join(root,'selfhost/.bootstrap/upstream-phase23'));
const hash=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:hash(file),bytes:fs.statSync(file).size});
const inputs=[identity(import.meta.filename),identity(source)];
const copy=(file,name)=>{inputs.push(identity(file));const target=path.join(out,name);fs.copyFileSync(file,target);return target;};
const old=copy(path.join(root,'selfhost/build/phase30/attempt-02/snapshot/tools/stage0-library.mjs'),'old-helper.mjs');
const fresh=copy(path.join(root,'selfhost/tools/stage0-library.mjs'),'new-helper.mjs');
for(const name of ['bend.ts','comp.ts','base.bend'])inputs.push(identity(path.join(upstream,'bend2',name)));
for(const name of ['library.bend','foreign.js','hole.bend','invalid-private.bend'])copy(path.join(root,'selfhost/tests/phase8-bootstrap/fixtures',name),name);
fs.writeFileSync(path.join(out,'parse-error.bend'),'import Base\ndef broken(:\n');
const report={kind:'phase30-bootstrap-diagnostic-controls',complete:false,pass:false,scope:'Bootstrap adapter diagnostics only; elapsed times are diagnostic-loop observations, not clean compiler/program benchmarks.',node:{file:process.execPath,version:process.version},affinity:fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(.*)$/m)?.[1],inputs,executions:[],checks:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
const run=(name,helper,input,exports=[])=>{
  const target=path.join(out,name+'.mjs'),stdout=path.join(out,name+'.stdout'),stderr=path.join(out,name+'.stderr');
  const a=fs.openSync(stdout,'wx'),b=fs.openSync(stderr,'wx');
  const command=[process.execPath,'--stack-size=4096','--max-old-space-size=4096',helper,input,target,...exports],start=performance.now();
  let r;try{r=spawnSync(command[0],command.slice(1),{env:{...process.env,BEND_UPSTREAM:upstream},stdio:['ignore',a,b],timeout:10000});}finally{fs.closeSync(a);fs.closeSync(b);}
  const row={name,command,timeoutMs:10000,exitCode:r.status,signal:r.signal,error:r.error?.message??null,wallMs:performance.now()-start,stdout:identity(stdout),stderr:identity(stderr),outputExists:fs.existsSync(target)};
  if(row.outputExists)row.output=identity(target);
  report.executions.push(row);save();return {...row,target,text:fs.readFileSync(stderr,'utf8')};
};
const check=(name,f)=>{try{f();report.checks.push({name,pass:true});}catch(error){report.checks.push({name,pass:false,error:error.stack});}save();};
try{
  const failed=run('frozen-attempt02',fresh,source,['j_program']);
  check('frozen constructor mistake fails promptly with exact definition and source',()=>{assert.equal(failed.error,null);assert.equal(failed.exitCode,1);assert.equal(failed.outputExists,false);assert.match(failed.text,/Location: j_nat_loop_region/);assert.match(failed.text,/an annotated term \(cannot infer\)/);assert.match(failed.text,/observed : KDef/);assert.match(failed.text,/fast = KDef/);});
  const fixture=path.join(out,'library.bend'),roots=['selected','packet_identity','list_identity','apply_nat','make_adder','add','wrap','countdown'];
  const before=run('successful-old',old,fixture,roots),after=run('successful-new',fresh,fixture,roots);
  check('successful emitted library is byte-identical',()=>{assert.equal(before.exitCode,0,before.text);assert.equal(after.exitCode,0,after.text);assert.equal(after.output.sha256,before.output.sha256);});
  if(after.exitCode===0){const {default:api}=await import(pathToFileURL(after.target));check('same emitted exports execute',()=>{assert.deepEqual(Object.keys(api),roots);assert.equal(api.selected(41n),42n);assert.equal(api.wrap(4294967295),0);assert.equal(api.countdown(10000n),0n);});}
  for(const [name,file,exports,pattern]of [
    ['parse-error','parse-error.bend',['broken'],/Error:.*bootstrap structural summary/s],
    ['type-error','invalid-private.bend',['selected'],/Location: invalid_private/],
    ['named-hole','hole.bend',['selected'],/observed : \?missing/],
    ['missing-export','library.bend',['absent_export'],/absent from the checked book/]
  ]){const result=run(name,fresh,path.join(out,file),exports);check(name+' fails without publishing',()=>{assert.equal(result.error,null);assert.equal(result.exitCode,1);assert.equal(result.outputExists,false);assert.match(result.text,pattern);assert.ok(result.text.length<4000);});}
  check('all consumed inputs remain unchanged',()=>{for(const item of inputs)assert.equal(hash(item.file),item.sha256);});
  report.complete=true;report.pass=report.checks.every(row=>row.pass);
}catch(error){report.error=error.stack;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,checks:report.checks.length,executions:report.executions.map(x=>({name:x.name,wallMs:x.wallMs,exitCode:x.exitCode,error:x.error}))}));
if(!report.pass)process.exitCode=1;
