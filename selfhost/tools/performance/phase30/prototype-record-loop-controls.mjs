// Ordered ABI probes for the disposable opaque record loop; no timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,outArg,candidateName='row-loop',bindingMode='fixed']=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);
assert.ok(['fixed','guarded'].includes(bindingMode));
fs.mkdirSync(out,{recursive:false});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const save=(name,x)=>fs.writeFileSync(path.join(out,name),json(x),{flag:'wx'});
const ident=file=>({file,sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-opaque-record-loop-controls',complete:false,pass:false,inputs:[ident(import.meta.filename)],observations:[],counterexamples:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const host=(arity,code,bound=[])=>({arity,code,env:null,bound});
const modules={};
for(const name of ['unchanged',candidateName,'row-loop-eager-rejected']){
  const file=path.join(base,name+'.mjs');report.inputs.push(ident(file));modules[name]=await import(pathToFileURL(file));
}
const norm=value=>value?.code?{descriptor:true,arity:value.arity,bound:value.bound}:value;
const key=k=>typeof k==='symbol'?k.toString():String(k);
const modes={
 plain:()=>({a:['A','B','P','C']}),
 frozen:()=>({a:Object.freeze(['A','B','P','C'])}),
 getter:e=>({get a(){e.push('record.a');return ['A','B','P','C']}}),
 proxy:e=>({a:new Proxy(['A','B','P','C'],{get(t,k,r){e.push(['fields.get',key(k)]);return Reflect.get(t,k,r)},has(t,k){e.push(['fields.has',key(k)]);return Reflect.has(t,k)}})}),
 throwing:e=>({get a(){e.push('record.a');throw Error('record sentinel')}}),
 'empty-fields':e=>({a:{get length(){e.push('fields.length');return 0},get slice(){throw Error('unexpected slice')}}}),
 'short-fields':e=>({a:{get length(){e.push('fields.length');return 4},slice(){e.push('fields.slice');return ['A','B']}}}),
 'copied-lengths':e=>({a:{length:4,slice(){e.push('fields.slice');return new Proxy(['A','B','P','C'],{get(t,k,r){e.push(['copied.get',key(k)]);return Reflect.get(t,k,r)}});}}}),
};
function run(mod,options={}){
 const events=[],saved={row:mod.G.row,cell:mod.G.cell};let count=0;
 const state=(modes[options.mode??'plain'])(events);
 const replacement=host(1,([n])=>host(3,([j,ai,st])=>{events.push(['replacement-row',String(n),j,ai]);return st}));
 function body(label,j,ai,st){
   events.push([label,j,ai]);count++;
   if(options.throwAt===count)throw Error('cell '+count+' sentinel');
   if(options.replaceCellAt===count)mod.G.cell=host(2,([j,ai])=>host(1,([st])=>body('new-cell',j,ai,st)));
   if(options.replaceRowAt===count)mod.G.row=replacement;
   return st;
 }
 mod.G.cell=host(2,([j,ai])=>host(1,([st])=>body('cell',j,ai,st)));
 try{
   const n=BigInt(options.n??3);
   if(options.partial){
     const f=mod.call(mod.G.row,[n]),g=mod.call(f,[0]),h=mod.call(g,[1]);
     const descriptors=[f,g,h].map(x=>({arity:x.arity,bound:[...x.bound]}));
     return {events,descriptors,result:norm(mod.call(h,[state]))};
   }
   if(options.raw||options.rawPredecessor){
     const f=mod.call(mod.G.row,[n]),h=mod.call(f,[0,1]);
     const args=[...h.bound,state];
     if(options.rawPredecessor)args[0]={[Symbol.toPrimitive](hint){events.push(['predecessor.coerce',hint]);return n-1n}};
     const raw=h.code.call(h.env,args);
     const before=[...events],bounce=raw?.bounce===true;
     const result=mod.call(host(0,()=>raw),[]);
     return {events,before,bounce,result:norm(result)};
   }
   if(options.oversaturated){
     const f=mod.call(mod.G.row,[n]);
     f.bound={length:f.bound.length,concat(args){
       events.push('bound.concat');
       return new Proxy([n-1n,...args],{get(t,k,r){events.push(['arguments.get',key(k)]);return Reflect.get(t,k,r)},has(t,k){events.push(['arguments.has',key(k)]);return Reflect.has(t,k)}});
     }};
     return {events,result:norm(mod.call(f,[0,1,state,99]))};
   }
   const result=mod.default.row(n,0,1,state);
   return {events,result:norm(result),sameArrays:result?.a?.length===4?[result.a[0]===state.a?.[0],result.a[1]===state.a?.[1],result.a[2]===state.a?.[3],result.a[3]===state.a?.[2]]:undefined};
 }catch(error){return {events,error:{name:error.name,message:error.message}}}
 finally{mod.G.row=saved.row;mod.G.cell=saved.cell}
}
try{
 const cases=[];
 for(const mode of Object.keys(modes))for(const n of [0,1,3])cases.push({mode,n});
 for(const throwAt of [1,2,3])cases.push({throwAt});
 for(const replaceCellAt of [1,2])cases.push({replaceCellAt});
 cases.push({partial:true},{raw:true},{oversaturated:true},{rawPredecessor:true});
 if(bindingMode==='guarded')for(const replaceRowAt of [1,2,3])cases.push({replaceRowAt,n:4});
 for(const options of cases){
   const old=run(modules.unchanged,options),next=run(modules[candidateName],options);
   report.current={options,baseline:old,candidate:next};assert.deepEqual(next,old,JSON.stringify(options));
   report.observations.push({options,transcript:old});delete report.current;
 }
 for(const [name,variant,options]of [
   ['eager-later-iterations-before-copied-length','row-loop-eager-rejected',{oversaturated:true}],
   ['eager-raw-bounce-deferral','row-loop-eager-rejected',{raw:true}],
   ...(bindingMode==='fixed'?[['mutable-recursive-global-outside-scope',candidateName,{replaceRowAt:1,n:4}]]:[]),
 ]){
   const old=run(modules.unchanged,options),next=run(modules[variant],options);assert.notDeepEqual(next,old,name);
   report.counterexamples.push({name,variant,options,baseline:old,candidate:next});
 }
 for(const x of report.inputs)assert.deepEqual(ident(x.file),x);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
save('report.json',report);console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,counterexamples:report.counterexamples.length,error:report.error}));
