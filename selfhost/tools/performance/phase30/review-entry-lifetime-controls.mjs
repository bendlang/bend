// Private implementation lifetime changes must preserve fresh public callbacks.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [directoryArgument,outArgument]=process.argv.slice(2),directory=path.resolve(directoryArgument),out=path.resolve(outArgument);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const variants=['baseline','hoisted','fused'],files=variants.map(name=>path.join(directory,name+'.mjs'));
const pointsFile=path.resolve(import.meta.dirname,'../phase29/fixture-points.json');
const report={kind:'phase30-independent-worker-lifetime-controls',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,path.join(directory,'derive.json'),pointsFile,...files].map(identity),points:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const norm=x=>typeof x==='bigint'?{$bigint:String(x)}:x;
const describe=code=>({name:code.name,length:code.length,prototype:Object.getPrototypeOf(code)===Function.prototype,
 own:Reflect.ownKeys(code).map(key=>{const d=Object.getOwnPropertyDescriptor(code,key);return {key:String(key),enumerable:d.enumerable,configurable:d.configurable,writable:d.writable,
  value:key==='prototype'?{own:Reflect.ownKeys(d.value).map(String),constructorSelf:d.value.constructor===code}:d.value}}),
 constructible:(()=>{try{Reflect.construct(String,[],code);return true}catch{return false}})()});
function observe(m,kind){
 const events=[],first=m.default.mit(2n),second=m.default.mit(2n),args=[255,384,0,0,0,0];
 assert.notEqual(first.code,second.code,'saved public callbacks must remain independently mutable');
 const shape=describe(first.code),pcode=first.code,qcode=second.code;
 if(kind==='shape')return {shape,distinct:true};
 if(kind==='independent-call-hook'){
  pcode.call=function(env,a){events.push('first.call');const result=Reflect.apply(pcode,env,[a]);events.push(['first.raw-bounce',result?.bounce===true]);return result};
  const secondBefore=m.call(second,args),firstValue=m.call(first,args),secondAfter=m.call(second,args);
  assert.equal(Object.hasOwn(qcode,'call'),false);assert.deepEqual(events,['first.call',['first.raw-bounce',true]]);
  return {events,secondBefore,firstValue,secondAfter,firstCodeStill:first.code===pcode,secondCodeStill:second.code===qcode};
 }
 if(kind==='independent-call-getter'){
  Object.defineProperty(pcode,'call',{get(){events.push('first.call.get');return function(env,a){return Reflect.apply(pcode,env,[a])}}});
  Object.defineProperty(qcode,'call',{get(){events.push('second.call.get');return function(env,a){return Reflect.apply(qcode,env,[a])}}});
  return {first:m.call(first,args),second:m.call(second,args),events};
 }
 if(kind==='forged-raw-permission'){
  const raw=pcode.call(null,[1n,...args],true),bounce=raw?.bounce===true;
  assert.equal(bounce,true);return {bounce,value:m.call({arity:0,code:()=>raw,env:null,bound:[]},[])};
 }
 if(kind==='constructor-raw-entry'){
  const raw=new pcode([1n,...args]),bounce=raw?.bounce===true;
  assert.equal(bounce,true);return {bounce,value:m.call({arity:0,code:()=>raw,env:null,bound:[]},[])};
 }
 throw Error('unknown boundary');
}
try{
 const modules=await Promise.all(files.map(file=>import(pathToFileURL(file))));
 const points=[...JSON.parse(fs.readFileSync(pointsFile)).points,{exportName:'point',args:[50000,0,0,0,0,0,0],expected:50000}];
 for(const point of points){const values=modules.map(m=>m.default[point.exportName](...point.args));
  report.current={point,values};for(const value of values)assert.equal(value,point.expected);report.points.push({...point,values});delete report.current;}
 for(const kind of ['shape','independent-call-hook','independent-call-getter','forged-raw-permission','constructor-raw-entry']){
  const observations=modules.map(m=>observe(m,kind));report.current={kind,observations};
  for(const row of observations.slice(1))assert.deepEqual(row,observations[0]);
  report.boundaries.push({kind,observations});delete report.current;
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,(_,x)=>norm(x),2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,points:report.points.length,boundaries:report.boundaries.length,error:report.error}));
