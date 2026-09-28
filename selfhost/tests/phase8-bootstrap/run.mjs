#!/usr/bin/env node
// Real checked stage0 boundaries for the new upstream API; no generated-code edits.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const project=path.resolve(import.meta.dirname,'../..');
const upstream=fs.realpathSync(process.env.BEND_UPSTREAM||path.join(project,'.bootstrap/upstream-phase8'));
if(!process.argv[2])throw Error('Usage: run.mjs NEW_OUTPUT_DIRECTORY');
const output=path.resolve(process.argv[2]);fs.mkdirSync(output,{recursive:false});
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const inputs=[];
const copy=(source,target)=>{fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(source,target);inputs.push({source,target,sha256:sha(source)});assert.equal(sha(target),sha(source));};
for(const name of ['stage0-library.mjs','stage0.mjs'])copy(path.join(project,'tools',name),path.join(output,'tools',name));
for(const name of fs.readdirSync(path.join(import.meta.dirname,'fixtures')))copy(path.join(import.meta.dirname,'fixtures',name),path.join(output,'fixtures',name));
copy(import.meta.filename,path.join(output,'run.mjs'));
for(const name of ['bend.ts','comp.ts','base.bend'])inputs.push({source:path.join(upstream,'bend2',name),sha256:sha(path.join(upstream,'bend2',name))});
const report={kind:'phase8-new-upstream-bootstrap-controls',started:new Date().toISOString(),upstream,node:{file:process.execPath,version:process.version,execArgv:process.execArgv},cpuAllowed:fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(.+)$/m)?.[1]??null,inputs,rows:[],executions:[],complete:false,pass:false};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,(_k,v)=>typeof v==='bigint'?v.toString()+'n':v,2)+'\n');
const record=(name,f)=>{try{f();report.rows.push({name,pass:true});}catch(e){report.rows.push({name,pass:false,error:String(e.stack??e)});}save();};
const execute=(name,script,args)=>{
  const stdout=path.join(output,name+'.stdout'),stderr=path.join(output,name+'.stderr');
  const a=fs.openSync(stdout,'wx'),b=fs.openSync(stderr,'wx');let result;const start=performance.now();
  try{result=spawnSync(process.execPath,['--stack-size=4096','--max-old-space-size=1024',script,...args],{cwd:output,env:{...process.env,BEND_UPSTREAM:upstream},stdio:['ignore',a,b],timeout:30000});}finally{fs.closeSync(a);fs.closeSync(b);}
  const row={name,command:[process.execPath,'--stack-size=4096','--max-old-space-size=1024',script,...args],exitCode:result.status,signal:result.signal,error:result.error?.message??null,seconds:(performance.now()-start)/1000,stdout:fs.readFileSync(stdout,'utf8'),stderr:fs.readFileSync(stderr,'utf8')};report.executions.push(row);save();return row;
};
const roots=['selected','packet_identity','list_identity','apply_nat','make_adder','add','wrap','countdown'];
const lib=path.join(output,'tools/stage0-library.mjs'),stage0=path.join(output,'tools/stage0.mjs');
const fixture=name=>path.join(output,'fixtures',name+'.bend');
const generated=path.join(output,'selected.mjs');
const built=execute('selected-build',lib,[fixture('library'),generated,...roots]);
record('complete checked library builds',()=>{assert.equal(built.error,null);assert.equal(built.exitCode,0,built.stderr);assert.ok(fs.existsSync(generated));});
if(built.exitCode===0){
 const {default: api}=await import(pathToFileURL(generated));
 record('exact selected export set',()=>assert.deepEqual(Object.keys(api),roots));
 record('private dependency executes without being exported',()=>{assert.equal(api.selected(41n),42n);assert.equal(api.private_step,undefined);});
 record('Nat remains BigInt at host boundary',()=>{assert.equal(typeof api.add(1n,2n),'bigint');assert.equal(api.add(1n,2n),3n);assert.equal(api.add(281474976710654n,1n),281474976710655n);});
 record('Nat overflow rejects at runtime',()=>assert.throws(()=>api.add(281474976710655n,1n)));
 record('Nat invalid host input rejects when demanded',()=>assert.throws(()=>api.add('invalid',1n)));
 const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
 record('nested Nat record/list and input immutability',()=>{const value={$:'Packet',size:4n,items:list([1n,2n,3n])},before=structuredClone(value);assert.deepEqual(api.packet_identity(value),before);assert.deepEqual(value,before);});
 record('callback Nat argument and result remain BigInt',()=>{let seen;assert.equal(api.apply_nat(x=>{seen=x;return x+2n;},40n),42n);assert.equal(seen,40n);});
 record('returned function marshals Nat',()=>{const f=api.make_adder(40n);assert.equal(typeof f,'function');assert.equal(f(2n),42n);});
 record('partial application keeps host ABI',()=>assert.equal(api.add(40n)(2n),42n));
 record('U32 retains wrapping number representation',()=>{assert.equal(api.wrap(4294967295),0);assert.equal(typeof api.wrap(0),'number');});
 record('deep native Nat tail recursion executes',()=>assert.equal(api.countdown(100000n),0n));
 record('deep Nat list host conversion and input immutability',()=>{let xs={$:'Nil'};for(let i=0;i<20000;i++)xs={$:'Con',head:BigInt(i),tail:xs};const out=api.list_identity(xs);let a=xs,b=out,count=0;while(a.$==='Con'){assert.equal(typeof a.head,'bigint');assert.equal(b.head,a.head);a=a.tail;b=b.tail;count++;}assert.equal(count,20000);assert.equal(b.$,'Nil');});
}
for(const [name,requested,pattern] of [
 ['missing',['not_present'],/absent from the checked book/],['base',['Nat.add'],/not a filled/],['constructor',['Packet'],/not a filled/],['io',['io_root'],/not a filled/],['template',['template_root'],/not a filled/],['foreign',['foreign_root'],/not a filled/],['duplicate',['selected','selected'],/Duplicate requested/]
]){
 const target=path.join(output,name+'.mjs'),run=execute('reject-'+name,lib,[fixture('library'),target,...requested]);
 record('reject requested '+name+' before publishing',()=>{assert.notEqual(run.exitCode,0);assert.equal(run.error,null);assert.match(run.stderr,pattern);assert.equal(fs.existsSync(target),false);});
}
for(const name of ['unfilled','hole','todo','invalid-private'])for(const [kind,script,extra] of [['library',lib,['selected']],['program',stage0,[]]]){
 const target=path.join(output,name+'-'+kind+'.mjs'),run=execute('reject-'+name+'-'+kind,script,[fixture(name),target,...extra]);
 record(kind+' rejects '+name+' before publishing',()=>{assert.notEqual(run.exitCode,0);assert.equal(run.error,null);assert.equal(fs.existsSync(target),false);if(name==='unfilled'||name==='todo')assert.match(run.stderr,/Unresolved/);if(name==='hole')assert.match(run.stderr,/observed : \?missing/);if(name==='invalid-private')assert.match(run.stderr,/Location: invalid_private/);});
}
const all=path.join(output,'all.mjs'),allBuild=execute('default-build',lib,[fixture('library'),all]);
record('default builds every eligible export',()=>{assert.equal(allBuild.exitCode,0,allBuild.stderr);});
if(allBuild.exitCode===0){const {default: api}=await import(pathToFileURL(all));record('default export selection excludes non-host-callable definitions',()=>assert.deepEqual(Object.keys(api),['private_step',...roots]));}
const program=path.join(output,'program.cjs'),programBuild=execute('program-build',stage0,[fixture('program'),program]);
record('whole program stage0 builds',()=>assert.equal(programBuild.exitCode,0,programBuild.stderr));
if(programBuild.exitCode===0){const ran=execute('program-run',program,[]);record('actual emitted program executes',()=>{assert.equal(ran.exitCode,0,ran.stderr);assert.equal(ran.stdout,'2n\n');});}
record('all consumed inputs unchanged',()=>{for(const item of inputs){assert.equal(sha(item.source),item.sha256);if(item.target)assert.equal(sha(item.target),item.sha256);}});
report.complete=true;report.pass=report.rows.every(row=>row.pass);report.finished=new Date().toISOString();save();
console.log(JSON.stringify({output,total:report.rows.length,passed:report.rows.filter(row=>row.pass).length,pass:report.pass}));
if(!report.pass)process.exitCode=1;
