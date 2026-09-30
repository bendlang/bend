// Live callee replacement/order controls for the fixed edit-distance chain.
// MODE is replacement (record in-place limits) or full (require them to match).
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [oldFile,newFile,outArgument,mode='replacement']=process.argv.slice(2);
assert.ok(oldFile&&newFile&&outArgument);assert.ok(['replacement','full'].includes(mode));
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const report={kind:'phase30-independent-global-guard-controls',complete:false,pass:false,mode,node:process.version,
  inputs:[identity(oldFile),identity(newFile),identity(import.meta.filename)],observations:[],inPlace:[],
  scope:'Fixed edit-row private prototype. Live G replacement/getters and placement of callee lookup vs argument effects. No timing or compiler-admission claim.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-global-guards.mjs'));
let nonce=0;
const host=(arity,code)=>({arity,code,env:null,bound:[]});
const names=['cell','cell.f1','cell.f2','cell.f3','cell.f4'];
const invoke=async(file,target,mutation)=>{
  const module=await import(pathToFileURL(path.resolve(file)).href+'?review-global='+(nonce++));
  const events=[],original=module.G[target],n=original.arity;
  const sentinel=()=>module.ctor('Dp',['RA','RB','RP','RC'].map(label=>({array:[label]})));
  const replacement=host(n,args=>{events.push(['replacement-prefix',target,args.length]);return host(1,([x])=>{events.push(['replacement-match',target]);return sentinel()})});
  const oldRead=module.G['Array.get'],oldBool=module.G.b2u;
  module.G['Array.get']=host(3,args=>{events.push(['array-read',args[2]]);return module.call(oldRead,args)});
  module.G.b2u=host(1,args=>{events.push('b2u');return module.call(oldBool,args)});
  if(mutation==='replace')module.G[target]=replacement;
  if(mutation==='zero-initializer')module.G[target]=host(0,()=>{events.push('initializer');return replacement});
  if(mutation==='entry-getter')Object.defineProperty(module.G,target,{configurable:true,get(){events.push('entry-getter');return replacement}});
  if(mutation==='replace-before-next'){
    const read=module.G['Array.get'];module.G['Array.get']=host(3,args=>{events.push('install-next');module.G[target]=replacement;return module.call(read,args)});
  }
  if(mutation==='mutate-code')original.code=replacement.code;
  if(mutation==='code-getter')Object.defineProperty(original,'code',{configurable:true,get(){events.push('code-getter');return replacement.code}});
  if(mutation==='bound-mutation')original.bound.push(71);
  if(mutation==='arity-mutation')original.arity=0;
  if(mutation==='own-typeName')original.typeName='ReviewType';
  if(mutation==='own-io')original.io=()=>17;
  const st=module.ctor('Dp',[[1,2],[2,1],[0,1],[0,0]].map(array=>({array})));
  try{return {events,result:module.default.row(1n,0,1,st)}}catch(error){return {events,error:{name:error.name,message:error.message}}}
};
try{
  for(const name of names)for(const mutation of ['replace','zero-initializer','entry-getter','replace-before-next']){
    const a=await invoke(oldFile,name,mutation),b=await invoke(newFile,name,mutation);
    report.currentComparison={name,mutation,baseline:a,candidate:b};assert.deepEqual(b,a,name+' '+mutation);
    report.observations.push({name,mutation,transcript:a});delete report.currentComparison;
  }
  for(const name of ['cell','cell.f2'])for(const mutation of ['mutate-code','code-getter','bound-mutation','arity-mutation','own-typeName','own-io']){
    const a=await invoke(oldFile,name,mutation),b=await invoke(newFile,name,mutation),equal=json(a)===json(b);
    report.inPlace.push({name,mutation,equal,baseline:a,candidate:b});
    if(mode==='full')assert.deepEqual(b,a,name+' '+mutation);
  }
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),json(report),{flag:'wx'});
console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,inPlace:report.inPlace.map(({name,mutation,equal})=>({name,mutation,equal})),error:report.error}));
