// Live-binding/effect-order checks, independently compared fresh module instances.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const ident=file=>({file,sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-live-record-loop-guard-controls',complete:false,pass:false,inputs:[ident(import.meta.filename)],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const files=['unchanged','row-loop-guarded'].map(name=>path.join(base,name+'.mjs'));
for(const file of files)report.inputs.push(ident(file));
const host=(arity,code,bound=[])=>({arity,code,env:null,bound});let nonce=0;
function normalize(value){
 if(value?.code)return {descriptor:true,arity:value.arity,bound:value.bound};
 return value;
}
async function run(file,mutation,when){
 const m=await import(pathToFileURL(file).href+'?record-guard-control='+(nonce++));
 const events=[],original=m.G.row,state={a:['A','B','P','C']};let cells=0,installed=false,rawIndex;
 const replacement=host(1,([n])=>{events.push(['replacement-prefix',String(n)]);return host(3,([j,ai,st])=>{events.push(['replacement-body',j,ai]);return st})});
 const originalCode=original.code;
 const install=()=>{
  if(installed)return;installed=true;events.push(['install',mutation]);
  switch(mutation){
   case 'replace':m.G.row=replacement;break;
   case 'zero-initializer':m.G.row=host(0,()=>{events.push('initializer');return replacement});break;
   case 'G-getter':Object.defineProperty(m.G,'row',{configurable:true,get(){events.push('G.row');return replacement}});break;
   case 'G-getter-original':Object.defineProperty(m.G,'row',{configurable:true,get(){events.push('G.row');return original}});break;
   case 'code':original.code=replacement.code;break;
   case 'code-getter':Object.defineProperty(original,'code',{configurable:true,get(){events.push('code');return replacement.code}});break;
   case 'arity-zero':original.arity=0;break;
   case 'arity-two':original.arity=2;break;
   case 'arity-getter':Object.defineProperty(original,'arity',{configurable:true,get(){events.push('arity');return 1}});break;
   case 'env':original.env={marker:'changed-env'};break;
   case 'env-getter':Object.defineProperty(original,'env',{configurable:true,get(){events.push('env');return null}});break;
   case 'bound-replace':original.bound=[0n];break;
   case 'bound-push':original.bound.push(0n);break;
   case 'bound-getter':Object.defineProperty(original,'bound',{configurable:true,get(){events.push('bound');return []}});break;
   case 'io-getter':Object.defineProperty(original,'io',{configurable:true,get(){events.push('io');return false}});break;
   case 'type-getter':Object.defineProperty(original,'typeName',{configurable:true,get(){events.push('typeName');return false}});break;
   case 'code-call':originalCode.call=function(env,args){events.push(['code.call',env]);return Reflect.apply(originalCode,env,[args])};break;
   case 'prototype':Object.setPrototypeOf(original,{get io(){events.push('prototype.io');return false},get typeName(){events.push('prototype.typeName');return false}});break;
   default:throw Error('unknown mutation '+mutation);
  }
 };
 m.G.cell=host(2,([j,ai])=>host(1,([st])=>{
  events.push(['cell',j!==null&&typeof j==='object'?{rawIndexSame:j===rawIndex}:j,ai]);cells++;
  if(cells>8)throw Error('bounded cell sentinel');
  if(when==='cell'+cells)install();
  return st;
 }));
 try{
  const partial=m.call(m.call(m.G.row,[4n]),[0,1]);
  if(when==='raw-entry')install();
  let result;
  if(when==='outer-length'){
   let lengthReads=0;
   partial.bound={length:3,concat(args){return new Proxy([3n,0,1,...args],{get(t,k,r){
    if(k==='length'){lengthReads++;events.push(['outer.length',lengthReads]);if(lengthReads===4)install();}
    return Reflect.get(t,k,r);
   }})}};
   result=m.call(partial,[state,99]);
  }else if(when==='index-coercion'){
   const j={[Symbol.toPrimitive](hint){events.push(['index.coerce',hint]);install();return 0}};
   rawIndex=j;
   const raw=partial.code.call(partial.env,[3n,j,1,state]);
   result=m.call(host(0,()=>raw),[]);
  }else result=m.call(partial,[state]);
  return {events,result:normalize(result)};
 }catch(error){return {events,error:{name:error.name,message:error.message}}}
}
try{
 const mutations=['replace','zero-initializer','G-getter','G-getter-original','code','code-getter','arity-zero','arity-two','arity-getter','env','env-getter','bound-replace','bound-push','bound-getter','io-getter','type-getter','code-call','prototype'];
 for(const mutation of mutations)for(const when of ['raw-entry','cell1','cell2']){
  const old=await run(files[0],mutation,when),next=await run(files[1],mutation,when);
  report.current={mutation,when,baseline:old,candidate:next};assert.deepEqual(next,old,mutation+' '+when);
  report.observations.push({mutation,when,transcript:old});delete report.current;
 }
 for(const mutation of ['replace','code','G-getter'])for(const when of ['outer-length','index-coercion']){
  const old=await run(files[0],mutation,when),next=await run(files[1],mutation,when);
  report.current={mutation,when,baseline:old,candidate:next};assert.deepEqual(next,old,mutation+' '+when);
  report.observations.push({mutation,when,transcript:old});delete report.current;
 }
 for(const x of report.inputs)assert.deepEqual(ident(x.file),x);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),json(report),{flag:'wx'});
console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
