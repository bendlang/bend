// Instrumented reflection-order diagnostic; these copies are never timed.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const design=path.resolve(import.meta.dirname,'../../../../design/phase30/scalar-guard-reflection-review.md');
const derivation=JSON.parse(fs.readFileSync(path.join(dir,'derive.json')));assert.equal(derivation.complete,true);
const report={kind:'phase30-independent-scalar-guard-reflection',complete:false,pass:false,
 scope:'Diagnostic reflection wrappers delegate unchanged; not a production promise under arbitrary replaced intrinsics. No timing.',
 inputs:[import.meta.filename,design,path.join(dir,'derive.json')].map(identity),observations:[]};
for(const side of ['baseline','candidate']){
 const file=path.join(dir,'core-'+side+'.mjs');assert.deepEqual(identity(file),derivation.directGuardCores[side]);report.inputs.push(identity(file));
 fs.writeFileSync(path.join(out,side+'.mjs'),fs.readFileSync(file,'utf8')+'\nexport {G,fn,scalarCapture,scalarGuard};\n',{flag:'wx'});
}
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const getOwn=Object.getOwnPropertyDescriptor,getProto=Object.getPrototypeOf,hasOwn=Object.hasOwn;
const cases=[{name:'valid',expect:true},{name:'empty',expect:true,names:[]},{name:'repeated',expect:true,names:['a','b','a']},{name:'missing',expect:false,names:['a','missing']}];
for(const target of ['a','b'])for(const mutation of ['G-getter','G-replacement','G-proxy','arity-getter','code-getter','env-getter','bound-getter','arity-delete','code-delete','env-delete','bound-delete','arity-value','code-value','env-value','bound-value','bound-length','code-call-getter','f-prototype','code-prototype','f-io','f-typeName'])cases.push({name:target+':'+mutation,target,mutation,expect:false});
for(const prototype of ['Object','Boolean','Number','BigInt'])for(const key of ['request','bounce','build','code'])cases.push({name:prototype+':'+key,prototype,key,expect:false});
for(const prototype of ['Boolean','Number','BigInt'])cases.push({name:prototype+':parent',prototype,key:'parent',expect:false});
cases.push({name:'Object:io',prototype:'Object',key:'io',expect:false},{name:'Object:typeName',prototype:'Object',key:'typeName',expect:false});
let nonce=0;
async function observe(side,row){
 const m=await import(pathToFileURL(path.join(out,side+'.mjs')).href+'?reflection='+(nonce++)),events=[],hooks=[],restore=[];
 const labels=new WeakMap([[Object.prototype,'Object.prototype'],[Function.prototype,'Function.prototype'],[Boolean.prototype,'Boolean.prototype'],[Number.prototype,'Number.prototype'],[BigInt.prototype,'BigInt.prototype'],[m.G,'G']]);
 const descriptors={};
 for(const name of ['a','b']){const f=m.fn(2,function(a){return a[0]});descriptors[name]=f;labels.set(f,name);labels.set(f.code,name+'.code');labels.set(f.bound,name+'.bound');m.G[name]=m.scalarCapture(name,f)}
 const label=o=>(o!==null&&(typeof o==='object'||typeof o==='function'))?(labels.get(o)??'<unlabelled>'):String(o);
 const define=(object,key,descriptor)=>{const old=getOwn(object,key);restore.push(()=>old?Object.defineProperty(object,key,old):delete object[key]);Object.defineProperty(object,key,{configurable:true,...descriptor})};
 const parent=(object,value)=>{const old=getProto(object);restore.push(()=>Object.setPrototypeOf(object,old));Object.setPrototypeOf(object,value)};
 const mark=(name,value)=>({get(){hooks.push(name);return value}});
 if(row.target){const f=descriptors[row.target],key=row.mutation.split('-')[0];
  switch(row.mutation){
   case 'G-getter':define(m.G,row.target,mark('G',f));break;
   case 'G-replacement':m.G[row.target]={...f};break;
   case 'G-proxy':m.G[row.target]=new Proxy(f,{get(...a){hooks.push('Proxy.get');return Reflect.get(...a)},getOwnPropertyDescriptor(...a){hooks.push('Proxy.descriptor');return Reflect.getOwnPropertyDescriptor(...a)},getPrototypeOf(...a){hooks.push('Proxy.prototype');return Reflect.getPrototypeOf(...a)}});break;
   case 'arity-getter':case 'code-getter':case 'env-getter':case 'bound-getter':define(f,key,mark(key,f[key]));break;
   case 'arity-delete':case 'code-delete':case 'env-delete':case 'bound-delete':delete f[key];break;
   case 'arity-value':f.arity=3;break;
   case 'code-value':f.code=()=>17;break;
   case 'env-value':f.env={};break;
   case 'bound-value':f.bound=[];break;
   case 'bound-length':f.bound.push(7);break;
   case 'code-call-getter':define(f.code,'call',mark('call',Function.prototype.call));break;
   case 'f-prototype':parent(f,null);break;
   case 'code-prototype':parent(f.code,null);break;
   case 'f-io':define(f,'io',mark('io',false));break;
   case 'f-typeName':define(f,'typeName',mark('typeName',false));break;
   default:throw Error(row.mutation);
  }
 }
 if(row.prototype){const p={Object:Object.prototype,Boolean:Boolean.prototype,Number:Number.prototype,BigInt:BigInt.prototype}[row.prototype];if(row.key==='parent')parent(p,null);else define(p,row.key,mark(row.prototype+'.'+row.key,false))}
 let accepted;
 try{
  Object.getOwnPropertyDescriptor=function(object,key){const tag=label(object);events.push(['descriptor',tag,String(key)]);const d=getOwn(object,key);if(d)labels.set(d,'descriptor('+tag+','+String(key)+')');return d};
  Object.getPrototypeOf=function(object){events.push(['prototype',label(object)]);return getProto(object)};
  Object.hasOwn=function(object,key){events.push(['hasOwn',label(object),String(key)]);return hasOwn(object,key)};
  accepted=m.scalarGuard(row.names??['a','b']);
 }finally{
  Object.getOwnPropertyDescriptor=getOwn;Object.getPrototypeOf=getProto;Object.hasOwn=hasOwn;
  for(const cleanup of restore.reverse())cleanup();
 }
 assert.equal(accepted,row.expect,row.name+' '+side);assert.deepEqual(hooks,[],row.name+' getters must not run');
 return {accepted,events,hooks};
}
try{
 for(const row of cases){const baseline=await observe('baseline',row),candidate=await observe('candidate',row);report.current={name:row.name,baseline,candidate};assert.deepEqual(candidate,baseline,row.name);report.observations.push(report.current);delete report.current}
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
