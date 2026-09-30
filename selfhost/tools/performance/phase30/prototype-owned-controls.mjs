// Independent complete-state, alias and ordered public-boundary controls.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const variants=['baseline','private_cell','private_scalar','private_row'];
const names=['row.probe','prng','gen','init','row','cell','cell.f1','cell.f2','cell.f3','cell.f4','umin','umin.go','b2u','Array.new','Array.get','Array.set'];
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const files=[...variants,'typescript'].map(v=>path.join(dir,v+'.mjs'));
const modules=await Promise.all(files.map(file=>import(pathToFileURL(file))));
const report={kind:'phase30-closed-owned-row-controls',complete:false,pass:false,node:process.version,
 scope:'Complete four-array oracles, local handle sharing and public fallback order. No timing.',
 inputs:[import.meta.filename,path.join(dir,'derive.json'),path.join(dir,'points.json'),...files].map(identity),oracle:[],aliases:[],boundaries:[],admission:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const host=(arity,code,bound=[])=>({arity,code,env:null,bound});
const force=(m,x)=>m.call(host(0,()=>x),[]);
function snapshot(m){
 const rows=names.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value,code=f.code;
  return {name,gd,f,fd:Object.getOwnPropertyDescriptors(f),fp:Object.getPrototypeOf(f),code,
   cd:Object.getOwnPropertyDescriptors(code),cp:Object.getPrototypeOf(code),bound:f.bound,bd:Object.getOwnPropertyDescriptors(f.bound)};});
 return()=>{for(const r of rows){
  for(const k of Reflect.ownKeys(r.f))if(!Object.hasOwn(r.fd,k))delete r.f[k];
  for(const k of Reflect.ownKeys(r.code))if(!Object.hasOwn(r.cd,k))delete r.code[k];
  for(const k of Reflect.ownKeys(r.bound))if(!Object.hasOwn(r.bd,k))delete r.bound[k];
  Object.defineProperties(r.bound,r.bd);Object.setPrototypeOf(r.code,r.cp);Object.defineProperties(r.code,r.cd);
  Object.setPrototypeOf(r.f,r.fp);Object.defineProperties(r.f,r.fd);Object.defineProperty(m.G,r.name,r.gd);
 }};
}
function normalize(x,seen=new Set()){
 if(typeof x==='bigint')return {$bigint:String(x)};
 if(typeof x==='function')return '[Function]';if(typeof x==='symbol')return String(x);
 if(x===undefined)return '[Undefined]';if(Object.is(x,-0))return '-0';
 if(typeof x==='number'&&!Number.isFinite(x))return String(x);
 if(x===null||typeof x!=='object')return x;
 if(seen.has(x))return '[Cycle]';seen.add(x);
 const result=Array.isArray(x)?x.map(v=>normalize(v,seen)):Object.fromEntries(Object.keys(x).sort().map(k=>[k,normalize(x[k],seen)]));
 seen.delete(x);return result;
}
function observe(m,action){const restore=snapshot(m),events=[];
 try{return {value:normalize(action(m,events)),events};}
 catch(error){return {error:{name:error.name,message:error.message},events};}
 finally{restore();}}
function boundary(name,action,contexts=modules.slice(0,4)){
 const observations=contexts.map(m=>observe(m,action));report.current={name,observations};
 for(let i=1;i<observations.length;i++)assert.deepEqual(observations[i],observations[0],name+' '+variants[i]);
 report.boundaries.push({name,observations});delete report.current;
}
function install(m,e,name,kind){const f=m.G[name],code=f.code,bound=f.bound,arity=f.arity;
 switch(kind){
 case 'binding-getter':Object.defineProperty(m.G,name,{configurable:true,get(){e.push(name+':G');return f}});break;
 case 'binding-replaced':m.G[name]={...f,code:function(a){e.push(name+':replacement');return Reflect.apply(code,this,[a])}};break;
 case 'code-getter':Object.defineProperty(f,'code',{configurable:true,get(){e.push(name+':code');return code}});break;
 case 'code-wrapper':f.code=function(a){e.push(name+':invoke');return Reflect.apply(code,this,[a])};break;
 case 'call-getter':Object.defineProperty(code,'call',{configurable:true,get(){e.push(name+':call');return Function.prototype.call}});break;
 case 'arity-getter':Object.defineProperty(f,'arity',{configurable:true,get(){e.push(name+':arity');return arity}});break;
 case 'env-getter':Object.defineProperty(f,'env',{configurable:true,get(){e.push(name+':env');return null}});break;
 case 'bound-getter':Object.defineProperty(f,'bound',{configurable:true,get(){e.push(name+':bound');return bound}});break;
 case 'env-replaced':f.env={};break;
 case 'bound-replaced':f.bound=[];break;
 case 'bound-push':f.bound.push(0);break;
 case 'io':f.io=false;break;
 case 'typeName':f.typeName=false;break;
 default:throw Error('Unknown mutation '+kind);
 }}
const ordinary=m=>m.default.bench(2,17);
try{
 for(const point of JSON.parse(fs.readFileSync(path.join(dir,'points.json')))){
  for(let i=0;i<modules.length;i++)assert.equal(modules[i].default.bench(...point.args),point.expected,'oracle '+i);
  report.oracle.push(point);
 }
 for(let i=0;i<4;i++)for(const n of [0,1,7,32]){
  const m=modules[i],a=m.default['row.probe'](n,17),before=JSON.stringify(a.a.map(x=>x.array));
  assert.equal(new Set(a.a).size,4);assert.equal(new Set(a.a.map(x=>x.array)).size,4);
  const b=m.default['row.probe'](n,17);
  for(const x of a.a)for(const y of b.a){assert.notEqual(x,y);assert.notEqual(x.array,y.array)}
  assert.equal(JSON.stringify(a.a.map(x=>x.array)),before);
  const saved=[...a.a],zero=m.default.row(0n,0,0,a);
  assert.deepEqual(zero.a.map(x=>saved.indexOf(x)),[0,1,3,2]);
  const next=m.default.row(1n,0,1,zero);
  assert.deepEqual(next.a.map(x=>saved.indexOf(x)),[0,1,2,3]);
  const same=m.call(m.G['Array.set'],[null,saved[2],0,4294967295]);assert.equal(same,saved[2]);
  assert.equal(a.a[2].array[0],4294967295);assert.equal(zero.a[3].array[0],4294967295);assert.equal(next.a[2].array[0],4294967295);
  report.aliases.push({variant:variants[i],n,distinctHandles:4,freshCall:true,zeroRoles:[0,1,3,2],nextRoles:[0,1,2,3],sharedWrite:4294967295});
 }
 for(const name of names)for(const kind of ['binding-getter','binding-replaced','code-getter','code-wrapper','call-getter','arity-getter','env-getter','bound-getter','env-replaced','bound-replaced','bound-push','io','typeName'])
  boundary(name+':'+kind,(m,e)=>{install(m,e,name,kind);return ordinary(m)});
 for(const name of names)boundary('saved-partial:'+name,(m,e)=>{const f=m.default['row.probe'](2);install(m,e,name,'code-wrapper');const st=m.call(f,[17]);return JSON.stringify(st.a.map(x=>x.array))});
 for(const mode of ['raw','forged','exact','slot-mutation','slot-throw','reentry','new','env-reentry'])
  boundary('entry:'+mode,(m,e)=>{
   const f=m.G['row.probe'],code=f.code;let active=false;const frame={length:2};
   for(let i=0;i<2;i++)Object.defineProperty(frame,i,{get(){e.push('slot:'+i);
    if(i===0&&mode==='reentry'&&!active){active=true;const raw=Reflect.apply(code,null,[[0,1]]);e.push(['raw-reentry',raw?.bounce===true]);}
    if(i===1&&mode==='slot-mutation')install(m,e,'Array.set','code-wrapper');
    if(i===1&&mode==='slot-throw')throw Error('slot sentinel');return [2,17][i];}});
   if(mode==='raw'||mode==='forged'){const raw=Reflect.apply(code,null,[frame,mode==='forged']);e.push(['deferred',raw?.bounce===true]);return force(m,raw)}
   if(mode==='new'){const raw=Reflect.construct(code,[frame]);e.push(['deferred',raw?.bounce===true],['instance',raw instanceof code]);return force(m,raw)}
   const chosen={...f};if(mode==='env-reentry')Object.defineProperty(chosen,'env',{get(){e.push('env');const raw=Reflect.apply(code,null,[[0,1]]);e.push(['raw-env',raw?.bounce===true]);return null}});
   return m.call(chosen,{slice(){e.push('slice');return frame}});
  });
 for(const read of [2,3,4,5])for(const mode of ['mutation','throw'])boundary('outer-length:'+read+':'+mode,(m,e)=>{
  let count=0;const frame=new Proxy([2,17,99],{get(t,k,r){if(k==='length'){e.push(['length',++count]);if(count===read){if(mode==='throw')throw Error('length sentinel');install(m,e,'Array.set','code-wrapper')}}return Reflect.get(t,k,r)}});
  return m.call(m.G['row.probe'],{slice(){e.push('slice');return frame}});
 });
 for(const [label,prototype]of [['Number',Number.prototype],['BigInt',BigInt.prototype],['Boolean',Boolean.prototype]])
  for(const key of ['request','bounce','build','code'])boundary(label+':'+key,(m,e)=>{
   const old=Object.getOwnPropertyDescriptor(prototype,key);try{
    Object.defineProperty(prototype,key,{configurable:true,get(){e.push(label+':'+key);return false}});return ordinary(m);
   }finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key]}
  });
 for(const name of ['Array.new','Array.get','Array.set']){
  const fresh=await Promise.all(files.slice(0,4).map(file=>import(pathToFileURL(file).href+'?first='+encodeURIComponent(name))));
  boundary('before-first-call:'+name,(m,e)=>{install(m,e,name,'code-wrapper');return ordinary(m)},fresh);
 }
 boundary('foreign-public-row',(m,e)=>{
  const source=[{array:[1,2,3,4]},{array:[0,1,2,3]},{array:[0,1,2,3]},{array:[0,0,0,0]}];
  const fields=new Proxy(source,{get(t,k,r){e.push('field:'+String(k));return Reflect.get(t,k,r)}});
  return m.default.row(2n,0,1,{$:'Dp',a:fields});
 });
 boundary('public-probe-descriptor',m=>{const f=m.G['row.probe'];return {arity:f.arity,bound:f.bound,env:f.env,length:f.code.length,name:f.code.name,constructible:Object.hasOwn(f.code,'prototype')}});
 // Post-guard sentinels establish the domain without retiming or touching the
 // guarded artifacts. The body marker contains no nested statements.
 for(const variant of variants.slice(1)){
  const original=fs.readFileSync(path.join(dir,variant+'.mjs'),'utf8');
  const fast=/\/\* owned row entry \*\/return force\([^;]*\);/g;
  const generic=/\/\* owned row generic \*\/return [^;]*;/g;
  assert.equal([...original.matchAll(fast)].length,1);assert.equal([...original.matchAll(generic)].length,1);
  const source=original.replace(fast,'/* owned row entry */return "fast";').replace(generic,'/* owned row generic */return "generic";');
  const file=path.join(out,variant+'-sentinel.mjs');fs.writeFileSync(file,source,{flag:'wx'});const m=await import(pathToFileURL(file));
  for(const [n,seed,expected]of [[0,0,'fast'],[64,4294967295,'fast'],[65,17,'generic'],[Object(1),17,'generic'],[1,Object(17),'generic']]){
   assert.equal(m.default['row.probe'](n,seed),expected);report.admission.push({variant,n:normalize(n),seed:normalize(seed),expected});
  }
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,aliases:report.aliases.length,boundaries:report.boundaries.length,admission:report.admission.length,error:report.error}));
