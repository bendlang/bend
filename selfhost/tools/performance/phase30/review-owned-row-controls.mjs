// Independent deferred-demand and alias controls for the closed-row prototype.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const variants=['baseline','private_cell','private_scalar','private_row'];
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const files=variants.map(v=>path.join(dir,v+'.mjs')),modules=await Promise.all(files.map(p=>import(pathToFileURL(p))));
const report={kind:'phase30-independent-owned-row-controls',complete:false,pass:false,node:process.version,
 scope:'Deferred generic callback results, later mutations and explicitly aliased public arrays; standard host intrinsics. No timing.',
 inputs:[import.meta.filename,path.join(dir,'derive.json'),...files].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const force=(m,x)=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
const names=['row.probe','Array.get','Array.set','cell'];
function snapshot(m){const rows=names.map(n=>[n,Object.getOwnPropertyDescriptor(m.G,n),Object.getOwnPropertyDescriptors(m.G[n])]);
 return()=>{for(const [n,gd,props]of rows){const f=gd.value;for(const key of Reflect.ownKeys(f))if(!Object.hasOwn(props,key))delete f[key];Object.defineProperties(f,props);Object.defineProperty(m.G,n,gd)}}}
function data(st){return st.a.map(handle=>Array.from(handle.array))}
function observe(m,action){const restore=snapshot(m),events=[];try{return {value:action(m,events),events}}catch(error){return {error:{name:error.name,message:error.message},events}}finally{restore()}}
function check(name,action){const observations=modules.map(m=>observe(m,action));report.current={name,observations};
 for(let i=1;i<observations.length;i++)assert.deepEqual(observations[i],observations[0],name+' '+variants[i]);
 report.observations.push({name,observations});delete report.current}
function replace(m,events,name){const f=m.G[name],code=f.code;m.G[name]={...f,code:function(a){events.push(name);return Reflect.apply(code,this,[a])}}}
try{
 for(const mode of ['raw','forged','new'])for(const name of ['Array.get','Array.set','cell'])
  check('deferred-'+mode+'-'+name,(m,events)=>{
   const code=m.G['row.probe'].code,raw=mode==='new'?Reflect.construct(code,[[2,17]]):Reflect.apply(code,null,[[2,17],mode==='forged']);
   assert.equal(raw.bounce,true);events.push('saved');replace(m,events,name);const st=force(m,raw);
   assert.ok(events.includes(name),'deferred changed helper must run');return data(st);
  });
 for(const mode of ['raw','new'])check('saved-bounce-reused-'+mode,(m,events)=>{
  const code=m.G['row.probe'].code,raw=mode==='new'?Reflect.construct(code,[[2,17]]):Reflect.apply(code,null,[[2,17]]);
  const first=force(m,raw),before=data(first),later=m.default.row(1n,0,3,first),after=data(first);
  replace(m,events,'Array.set');const second=force(m,raw);
  return {before,after,first:data(first),later:data(later),second:data(second),same:second.a.map(x=>first.a.indexOf(x))};
 });
 for(const mode of ['same-handle','same-storage','proxy-storage','array-getter'])for(const depth of [0n,1n,2n])
  check('public-alias-'+mode+'-'+depth,(m,events)=>{
   const backing=[0,1,2,3],store=mode==='proxy-storage'?new Proxy(backing,{get(t,k,r){events.push('get:'+String(k));return Reflect.get(t,k,r)},set(t,k,v,r){events.push('set:'+String(k)+':'+v);return Reflect.set(t,k,v,r)}}):backing;
   const a={array:store},b=mode==='same-handle'?a:mode==='array-getter'?Object.defineProperty({},'array',{get(){events.push('array');return store}}):{array:store};
   const handles=[a,b,a,b],state={$:'Dp',a:handles},first=m.default.row(depth,0,3,state),second=m.default.row(1n,1,2,first);
   return {input:data(state),first:data(first),second:data(second),roles:first.a.map(x=>handles.indexOf(x)),laterRoles:second.a.map(x=>handles.indexOf(x))};
  });
 for(const key of ['request','bounce','build','code'])check('Object.prototype.'+key,(m,events)=>{
  const old=Object.getOwnPropertyDescriptor(Object.prototype,key);try{
   Object.defineProperty(Object.prototype,key,{configurable:true,get(){events.push(key);return false}});
   return data(m.default['row.probe'](2,17));
  }finally{if(old)Object.defineProperty(Object.prototype,key,old);else delete Object.prototype[key]}
 });
 for(const p of report.inputs)assert.deepEqual(identity(p.file),p);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
