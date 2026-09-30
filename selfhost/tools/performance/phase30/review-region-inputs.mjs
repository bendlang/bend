// Independent host-value and prototype-boundary controls for scalar region.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseline,candidate,outArgument]=process.argv.slice(2);assert.ok(baseline&&candidate&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const report={kind:'phase30-independent-region-input-controls',complete:false,pass:false,node:process.version,
 inputs:[identity(baseline),identity(candidate),identity(import.meta.filename)],observations:[],excludedWitnesses:[],
 scope:'Disposable closed scalar region. Boxed/coercible input fallback, public partial state, stack. Prototype monkeypatch witness is explicitly outside assumed standard prototype behavior.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-region-inputs.mjs'));
let nonce=0;
const load=file=>import(pathToFileURL(path.resolve(file)).href+'?independent-region='+nonce++);
try{
 const observe=async(file,position,mode)=>{
  const m=await load(file),events=[],args=[3,5,7,11,0,13];
  const coerce=hint=>{events.push(['coerce',hint]);if(mode==='mutate')m.G.b2u.code=()=>{events.push('mutated-helper');return 1};if(mode==='throw')throw Error('coercion sentinel');return 7};
  if(mode==='boxed')args[position]=new Number(7);
  if(mode==='symbol'||mode==='mutate'||mode==='throw')args[position]={[Symbol.toPrimitive]:coerce};
  if(mode==='proxy')args[position]=new Proxy({[Symbol.toPrimitive]:coerce},{get(t,k,r){events.push(['get',String(k)]);return Reflect.get(t,k,r)}});
  if(mode==='proxy-boxed')args[position]=new Proxy(new Number(7),{get(t,k,r){events.push(['get',String(k)]);return Reflect.get(t,k,r)}});
  try{return {events,result:m.default.mit(3n,...args)}}catch(error){return {events,error:{name:error.name,message:error.message}}}
 };
 for(let p=0;p<6;p++)for(const mode of ['boxed','symbol','mutate','throw','proxy','proxy-boxed']){
  const a=await observe(baseline,p,mode),b=await observe(candidate,p,mode);
  report.currentComparison={position:p,mode,baseline:a,candidate:b};assert.deepEqual(b,a,'position '+p+' '+mode);
  report.observations.push({position:p,mode,transcript:a});delete report.currentComparison;
 }
 {
  const results={};for(const [side,file]of [['baseline',baseline],['candidate',candidate]]){
   const m=await load(file),p=m.default.mit(50000n);const before=[...p.bound],result=m.call(p,[0,0,0,0,0,0]);
   assert.equal(result,50000);assert.deepEqual(p.bound,before);results[side]={result,before,after:[...p.bound],arity:p.arity};
  }
  assert.deepEqual(results.candidate,results.baseline);report.observations.push({name:'50000-and-saved-partial',transcript:results.candidate});
 }
 // Do not silently widen the candidate's declared standard-prototype scope.
 {
  const results={};
  for(const [side,file]of [['baseline',baseline],['candidate',candidate]]){
   const m=await load(file),events=[],old=Object.getOwnPropertyDescriptor(Boolean.prototype,'request');
   try{
    Object.defineProperty(Boolean.prototype,'request',{configurable:true,get(){events.push('Boolean.request');return false}});
    results[side]={result:m.default.mit(2n,0,0,0,0,0,0),events};
   }finally{if(old)Object.defineProperty(Boolean.prototype,'request',old);else delete Boolean.prototype.request;}
  }
  assert.equal(results.candidate.result,results.baseline.result);
  assert.notDeepEqual(results.candidate.events,results.baseline.events);
  report.excludedWitnesses.push({name:'Boolean.prototype.request-hook',...results,classification:'Expected difference outside frozen standard-prototype assumption; no production conformance claim.'});
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),json(report),{flag:'wx'});
console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,excludedWitnesses:report.excludedWitnesses.length,error:report.error}));
