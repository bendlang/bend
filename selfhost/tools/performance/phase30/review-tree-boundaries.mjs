// Independent supplemental tree observations, parameterized for later actual output.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [configArgument,outArgument]=process.argv.slice(2);assert.ok(configArgument&&outArgument);
const config=JSON.parse(fs.readFileSync(configArgument)),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const entries=Object.entries(config.variants);assert.ok(entries.length>=2&&entries[0][0]==='baseline');
const modules=await Promise.all(entries.map(async([name,file])=>({name,m:await import(pathToFileURL(path.resolve(file)))})));
const report={kind:'phase30-independent-tree-supplemental-boundaries',complete:false,pass:false,node:process.version,
 inputs:[configArgument,import.meta.filename,...(config.inputs??[]),...entries.map(([,file])=>file)].map(identity),observations:[],
 scope:'Full paired errors, values and ordered runtime-marker/descriptor/copy observations. Standard host intrinsics including private Array operations; no timing.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const names=['rcol','rpix','pix','bkt','mit','asr8','sel','sel.go','b2u'],colors=[1,3,7,17,31,63,127,255];
function normalize(x,seen=new Set()){
 if(typeof x==='bigint')return {$bigint:String(x)};if(typeof x==='function')return '[Function]';
 if(typeof x==='symbol')return String(x);if(x===undefined)return '[Undefined]';
 if(Object.is(x,-0))return '-0';if(typeof x==='number'&&!Number.isFinite(x))return String(x);
 if(x===null||typeof x!=='object')return x;if(seen.has(x))return '[Cycle]';seen.add(x);
 const value=Array.isArray(x)?x.map(y=>normalize(y,seen)):Object.fromEntries(Object.keys(x).sort().map(k=>[k,normalize(x[k],seen)]));
 seen.delete(x);return value;
}
function snapshot(m){
 const rows=names.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value,code=f.code,bound=f.bound;
  return {name,gd,f,fd:Object.getOwnPropertyDescriptors(f),fp:Object.getPrototypeOf(f),code,cd:Object.getOwnPropertyDescriptors(code),cp:Object.getPrototypeOf(code),bound,bd:Object.getOwnPropertyDescriptors(bound)};});
 return()=>{for(const r of rows){
  for(const key of Reflect.ownKeys(r.f))if(!Object.hasOwn(r.fd,key))delete r.f[key];
  for(const key of Reflect.ownKeys(r.code))if(!Object.hasOwn(r.cd,key))delete r.code[key];
  for(const key of Reflect.ownKeys(r.bound))if(!Object.hasOwn(r.bd,key))delete r.bound[key];
  Object.defineProperties(r.bound,r.bd);Object.setPrototypeOf(r.code,r.cp);Object.defineProperties(r.code,r.cd);
  Object.setPrototypeOf(r.f,r.fp);Object.defineProperties(r.f,r.fd);Object.defineProperty(m.G,r.name,r.gd);
 }};
}
function observe(m,action){const restore=snapshot(m),events=[];try{return {value:normalize(action(m,events)),events}}
 catch(e){return {error:{name:e.name,message:e.message},events}}finally{restore()}}
function check(name,action){const observations=modules.map(({name:variant,m})=>({variant,...observe(m,action)}));
 report.current={name,observations};for(const row of observations.slice(1)){
  const {variant,...actual}=row,{variant:ignored,...expected}=observations[0];assert.deepEqual(actual,expected,name+' '+variant);
 }report.observations.push({name,observations});delete report.current;}
const ordinary=m=>m.default.rcol(2n,4095,2n,...colors);
try{
 for(const [label,prototype]of [['Number',Number.prototype],['BigInt',BigInt.prototype],['Boolean',Boolean.prototype],['Object',Object.prototype]])
  for(const key of ['request','bounce','build','code'])check('prototype-'+label+'-'+key,(m,events)=>{
   const old=Object.getOwnPropertyDescriptor(prototype,key);
   Object.defineProperty(prototype,key,{configurable:true,get(){events.push(label+'.'+key);return false}});
   try{return ordinary(m)}finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key]}
  });
 for(const name of names)for(const mode of ['io-getter','typeName-getter','typeName-value','env-identity','bound-identity','bound-content','call-getter'])
  check('descriptor-'+name+'-'+mode,(m,events)=>{
   const f=m.G[name],code=f.code;
   if(mode==='io-getter'||mode==='typeName-getter'){
    const key=mode.split('-')[0];Object.defineProperty(f,key,{configurable:true,get(){events.push(name+'.'+key);return undefined}});
   }
   if(mode==='typeName-value')f.typeName='ReviewChanged';
   if(mode==='env-identity')f.env={review:true};
   if(mode==='bound-identity')f.bound=[];
   if(mode==='bound-content')f.bound.push(23);
   if(mode==='call-getter')Object.defineProperty(code,'call',{configurable:true,get(){events.push(name+'.call.get');return function(env,args){events.push(name+'.call');return Reflect.apply(code,env,[args])}}});
   return ordinary(m);
  });
 for(const trigger of [2,3,5])for(const action of ['throw','replace-helper'])check('copied-length-'+trigger+'-'+action,(m,events)=>{
  const partial=m.default.rcol(3n),values=[2n,4095,2n,...colors,99];let reads=0;
  const copied=new Proxy(values,{get(target,key,receiver){
   if(key==='length'){
    events.push('length:'+ ++reads);
    if(reads===trigger){if(action==='throw')throw Error('review copied length '+trigger);
     const old=m.G.rpix,code=old.code;m.G.rpix={...old,code:function(args){events.push('replacement rpix');return Reflect.apply(code,this,[args])}};
    }
   }return Reflect.get(target,key,receiver);
  }});
  return m.call({...partial,bound:[]},{slice(){events.push('argument.slice');return copied}});
 });
 for(const item of report.inputs)assert.deepEqual(identity(item.file),item);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
