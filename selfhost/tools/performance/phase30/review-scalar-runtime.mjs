// Snapshot/guard controls on the production core.mjs source itself.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [coreArgument,outArgument]=process.argv.slice(2);assert.ok(coreArgument&&outArgument);
const core=path.resolve(coreArgument),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const report={kind:'phase30-independent-scalar-runtime-guards',complete:false,pass:false,node:process.version,
 inputs:[identity(core),identity(import.meta.filename)],observations:[],scope:'Production runtime capture/guard, trusted fresh compiler fn captures and compiler-owned name arrays. No emitted compiler rule or timing claim.'};
const save=(name,x)=>fs.writeFileSync(path.join(out,name),JSON.stringify(x,null,2)+'\n',{flag:'wx'});
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-scalar-runtime.mjs'));
try{
 const file=path.join(out,'core.mjs');fs.writeFileSync(file,fs.readFileSync(core,'utf8')+'\nexport {fn,call,G,scalarCapture,scalarGuard};\n',{flag:'wx'});
 report.diagnostic={...identity(file),appendOnly:true,originalPrefixSha256:identity(core).sha256};
 const {fn,call,G,scalarCapture,scalarGuard}=await import(pathToFileURL(file));
 let at=0;
 const fresh=()=>{const name='review'+at++,f=fn(2,a=>a[0]+a[1]);const before=Object.getOwnPropertyDescriptors(f);assert.equal(scalarCapture(name,f),f);assert.deepEqual(Object.getOwnPropertyDescriptors(f),before);G[name]=f;assert.equal(scalarGuard([name]),true);return {name,f}};
 const note=(name,value)=>report.observations.push({name,value});
 {
  const name='forward',f=fn(1,a=>a[0]);scalarCapture(name,f);assert.equal(scalarGuard([name]),false);G[name]=f;assert.equal(scalarGuard([name]),true);
  assert.equal(scalarGuard([name,'later']),false);G.later=scalarCapture('later',fn(1,a=>a[0]));assert.equal(scalarGuard([name,'later']),true);note('capture-before-assignment-and-forward',[false,true,false,true]);
 }
 {
  const name='beforeFirst',f=fn(1,a=>a[0]);G[name]=scalarCapture(name,f);f.code=()=>71;assert.equal(scalarGuard([name]),false);note('mutation-before-first-use',false);
 }
 {
  const name='__proto__',f=fn(1,a=>a[0]);G[name]=scalarCapture(name,f);assert.equal(scalarGuard([name]),true);note('null-prototype-name',true);
 }
 for(const key of ['arity','code','env','bound','io','typeName']){
  const {name,f}=fresh();let hits=0;Object.defineProperty(f,key,{configurable:true,get(){hits++;throw Error(key+' getter')}});
  assert.equal(scalarGuard([name]),false);assert.equal(hits,0);note('metadata-getter-'+key,{accepted:false,hits});
 }
 for(const mutation of ['arity','code','env','bound-replace','bound-push','own-io','own-typeName','prototype','code-call','code-prototype']){
  const {name,f}=fresh();
  if(mutation==='arity')f.arity=3;if(mutation==='code')f.code=()=>7;if(mutation==='env')f.env={};
  if(mutation==='bound-replace')f.bound=[];if(mutation==='bound-push')f.bound.push(1);
  if(mutation==='own-io')f.io=false;if(mutation==='own-typeName')f.typeName='T';
  if(mutation==='prototype')Object.setPrototypeOf(f,null);
  if(mutation==='code-call')f.code.call=()=>7;if(mutation==='code-prototype')Object.setPrototypeOf(f.code,null);
  assert.equal(scalarGuard([name]),false);note('mutation-'+mutation,false);
 }
 {
  const {name,f}=fresh();let hits=0;Object.defineProperty(f.code,'call',{get(){hits++;throw Error('call getter')}});assert.equal(scalarGuard([name]),false);assert.equal(hits,0);note('code-call-getter',{accepted:false,hits});
 }
 {
  const {name}=fresh();let hits=0;G[name]=new Proxy({}, {get(){hits++;throw Error('get trap')},getOwnPropertyDescriptor(){hits++;throw Error('descriptor trap')},getPrototypeOf(){hits++;throw Error('prototype trap')}});
  assert.equal(scalarGuard([name]),false);assert.equal(hits,0);note('replacement-proxy',{accepted:false,hits});
 }
 {
  const {name,f}=fresh();let hits=0;Object.defineProperty(G,name,{configurable:true,get(){hits++;return f}});assert.equal(scalarGuard([name]),false);assert.equal(hits,0);note('G-entry-getter',{accepted:false,hits});
 }
 {
  const {name,f}=fresh();Object.freeze(f);assert.equal(scalarGuard([name]),true);note('frozen-original',call(f,[11,13]));
 }
 const protoRows=[['Object',Object.prototype],['Boolean',Boolean.prototype],['Number',Number.prototype],['BigInt',BigInt.prototype]];
 for(const [label,prototype]of protoRows)for(const key of ['request','bounce','build','code']){
  const {name}=fresh();const old=Object.getOwnPropertyDescriptor(prototype,key);let hits=0,accepted;
  try{Object.defineProperty(prototype,key,{configurable:true,get(){hits++;throw Error('prototype getter')}});accepted=scalarGuard([name]);}
  finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key];}
  assert.equal(accepted,false);assert.equal(hits,0);note('prototype-'+label+'-'+key,{accepted,hits});
 }
 for(const key of ['io','typeName']){
  const {name}=fresh();const old=Object.getOwnPropertyDescriptor(Object.prototype,key);let hits=0,accepted;
  try{Object.defineProperty(Object.prototype,key,{configurable:true,get(){hits++;throw Error('inherited getter')}});accepted=scalarGuard([name]);}
  finally{if(old)Object.defineProperty(Object.prototype,key,old);else delete Object.prototype[key];}
  assert.equal(accepted,false);assert.equal(hits,0);note('inherited-'+key,{accepted,hits});
 }
 for(const [label,prototype]of protoRows.slice(1)){
  const {name}=fresh();const old=Object.getPrototypeOf(prototype);let hits=0,accepted;
  try{Object.setPrototypeOf(prototype,new Proxy({}, {get(){hits++;throw Error('prototype chain get')},getOwnPropertyDescriptor(){hits++;throw Error('prototype chain descriptor')}}));accepted=scalarGuard([name]);}
  finally{Object.setPrototypeOf(prototype,old);}
  assert.equal(accepted,false);assert.equal(hits,0);note('changed-'+label+'-prototype-link',{accepted,hits});
 }
 {
  const {name}=fresh(),old=Object.getOwnPropertyDescriptor(Function.prototype,'call');let hits=0,accepted;
  try{Object.defineProperty(Function.prototype,'call',{configurable:true,get(){hits++;throw Error('Function.call getter')}});accepted=scalarGuard([name]);}
  finally{Object.defineProperty(Function.prototype,'call',old);}
  assert.equal(accepted,false);assert.equal(hits,0);note('Function-call-getter',{accepted,hits});
 }
 // Example guarded region: reject the formerly excluded primitive hook and
 // run its original forcing path, preserving observable prototype reads.
 {
  const {name,f}=fresh(),old=Object.getOwnPropertyDescriptor(Number.prototype,'bounce');let reads=0;
  try{
   Object.defineProperty(Number.prototype,'bounce',{configurable:true,get(){reads++;return false}});
   const result=scalarGuard([name])?11+13:call(f,[11,13]);assert.equal(result,24);assert.equal(reads,1);
  }finally{if(old)Object.defineProperty(Number.prototype,'bounce',old);else delete Number.prototype.bounce;}
  note('prototype-hook-fallback-forcing',{result:24,reads});
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save('report.json',report);console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
