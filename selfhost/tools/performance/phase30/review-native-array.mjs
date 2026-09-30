// Independent call-order and reentrant native metadata controls for the
// explicitly non-tail generated-JavaScript Array.get prototype.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [rootArgument,outArgument]=process.argv.slice(2);assert.ok(rootArgument&&outArgument);
const root=path.resolve(rootArgument),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-independent-native-array-controls',complete:false,pass:false,node:process.version,
 scope:'Generated-JavaScript prototype only; four non-tail Array.get sites. Standard host intrinsics unchanged. Explicitly no direct tail-call promotion.',inputs:[identity(import.meta.filename)],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-native-array.mjs'));
function snapshot(m){const gd=Object.getOwnPropertyDescriptor(m.G,'Array.get'),f=gd.value,fd=Object.getOwnPropertyDescriptors(f),code=f.code,cd=Object.getOwnPropertyDescriptors(code),bound=f.bound;
 return()=>{bound.length=0;for(const k of Object.getOwnPropertyNames(f))if(!(k in fd))delete f[k];Object.defineProperties(f,fd);for(const k of Object.getOwnPropertyNames(code))if(!(k in cd))delete code[k];Object.defineProperties(code,cd);Object.defineProperty(m.G,'Array.get',gd)};}
function scenario(m,optimized,mode){
 const restore=snapshot(m),events=[],storage=[3,5,7,11],original=m.G['Array.get'],code=original.code;
 let a={array:storage},index=2;
 const replacement={arity:3,code:x=>{events.push('replacement');return [x[1],79]},env:null,bound:[]};
 const nested=()=>m.call(original,[null,{array:[13,17]},1])[1];
 if(mode==='G-accessor')Object.defineProperty(m.G,'Array.get',{configurable:true,get(){events.push('G');return original}});
 if(mode==='code-accessor-mutates-arity')Object.defineProperty(original,'code',{configurable:true,get(){events.push('code');original.arity=3;return code}});
 if(mode==='arity-accessor-mutates-code')Object.defineProperty(original,'arity',{configurable:true,get(){events.push('arity');original.code=replacement.code;return 3}});
 if(mode==='env-accessor-reentrant')Object.defineProperty(original,'env',{configurable:true,get(){events.push('env');return null}});
 if(mode==='bound-accessor-replaces-binding')Object.defineProperty(original,'bound',{configurable:true,get(){events.push('bound');m.G['Array.get']=replacement;return []}});
 if(mode==='code-call-getter')Object.defineProperty(code,'call',{configurable:true,get(){events.push('code.call');return function(env,args){return Reflect.apply(code,env,[args])}}});
 if(mode==='backing-accessor-reentrant')a={get array(){events.push(['nested',nested()]);return storage}};
 if(mode==='backing-accessor-mutates-code')a={get array(){events.push('array');original.code=replacement.code;return storage}};
 if(mode==='backing-proxy-mutates-binding')a={array:new Proxy(storage,{get(t,k,r){events.push('backing:'+String(k));if(k==='length')m.G['Array.get']=replacement;return Reflect.get(t,k,r)}})};
 if(mode==='index-coercion-mutates-code')index={[Symbol.toPrimitive](hint){events.push('index:'+hint);original.code=replacement.code;return 2}};
 if(mode==='index-coercion-reentrant')index={[Symbol.toPrimitive](hint){events.push(['index:'+hint,nested()]);return 2}};
 if(mode==='index-coercion-throws')index={[Symbol.toPrimitive](hint){events.push('index:'+hint);throw Error('index sentinel')}};
 const readTarget=()=>{const f=m.G['Array.get'];return f?.code&&f.arity===0?m.call(f,[]):f};
 const readIndex=()=>{events.push('argument');if(mode==='argument-replaces-binding')m.G['Array.get']=replacement;if(mode==='argument-mutates-code')original.code=replacement.code;return index};
 const call=(f,t,a,i)=>optimized?m.A_get(f,t,a,i):m.call(f,[t,a,i]);
 try{
  const result=call(readTarget(),null,a,readIndex());
  const after=call(readTarget(),null,{array:[19,23]},1);
  return {events,value:result[1],sameArray:result[0]===a,next:after[1],storage:[...storage]};
 }catch(error){return {events,error:{name:error.name,message:error.message},storage:[...storage]}}finally{restore()}
}
try{
 const modes=['G-accessor','code-accessor-mutates-arity','arity-accessor-mutates-code','env-accessor-reentrant','bound-accessor-replaces-binding','code-call-getter','argument-replaces-binding','argument-mutates-code','backing-accessor-reentrant','backing-accessor-mutates-code','backing-proxy-mutates-binding','index-coercion-mutates-code','index-coercion-reentrant','index-coercion-throws'];
 for(const prefix of ['unchanged','private']){
  const files=[path.join(root,prefix+'.mjs'),path.join(root,prefix+'-array-guarded.mjs')];
  report.inputs.push(...files.map(identity));const [baseline,candidate]=await Promise.all(files.map(x=>import(pathToFileURL(x))));
  for(const mode of modes){const a=scenario(baseline,false,mode),b=scenario(candidate,true,mode);report.currentComparison={prefix,mode,baseline:a,candidate:b};assert.deepEqual(b,a,prefix+':'+mode);report.observations.push({prefix,mode,transcript:a});delete report.currentComparison}
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
