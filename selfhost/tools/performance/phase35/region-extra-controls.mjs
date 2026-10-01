// Checked-source terminal-record and residual-call tests. No timing.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [baseArg,outArg]=process.argv.slice(2);assert(baseArg&&outArg,'usage: region-extra-controls.mjs ACQUISITION_DIR NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase35-checked-extra-region-controls',complete:false,pass:false,inputs:[import.meta.filename,path.join(base,'derive.json')].map(identity),oracle:[],boundaries:[],structure:{}};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const roles=['baseline','candidate','typescript'],groups={};
function norm(x){if(typeof x==='bigint')return x+'n';if(typeof x==='function')return '[Function]';if(x===undefined)return '[Undefined]';
 if(Object.is(x,-0))return '-0';if(typeof x==='number'&&!Number.isFinite(x))return String(x);
 if(x===null||typeof x!=='object')return x;if(Array.isArray(x))return x.map(norm);return Object.fromEntries(Object.keys(x).sort().map(k=>[k,norm(x[k])]));}
function hit(x){assert.equal(x.$,'HitProbe');return x.a??[x.miss,x.distance,x.index];}
const wrap=x=>Number(BigInt.asUintN(32,BigInt(x)));
function hitOracle(n,d,i,f){for(let k=0;k<Number(n);k++){if(f){d=Math.fround(d-.25);f=false;}else{d=Math.fround(d+.5);i=wrap(BigInt(i)+1n);f=true;}}
 return [f?d<=0:i===9,d,i];}
function treeOracle(depth,seed,limit){let total=0n;for(let offset=0;offset<2**Number(depth);offset++){
 const x=wrap(BigInt(seed)+BigInt(offset));if(x<limit)total+=x<10?BigInt(x)+1n:BigInt(x)*2n;
 }return wrap(total);}
function hook(obj,key,descriptor,action){const old=Object.getOwnPropertyDescriptor(obj,key);try{Object.defineProperty(obj,key,{configurable:true,...descriptor});return action();}
 finally{if(old)Object.defineProperty(obj,key,old);else delete obj[key];}}
function snapshot(m,names){const rows=names.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value,c=f.code,b=f.bound;
 return {name,gd,f,fd:Object.getOwnPropertyDescriptors(f),c,cd:Object.getOwnPropertyDescriptors(c),b,bd:Object.getOwnPropertyDescriptors(b)};});
 return()=>{for(const r of rows){for(const [o,ds]of[[r.f,r.fd],[r.c,r.cd],[r.b,r.bd]]){for(const k of Reflect.ownKeys(o))if(!Object.hasOwn(ds,k))delete o[k];Object.defineProperties(o,ds);}Object.defineProperty(m.G,r.name,r.gd);}};}
function boundary(group,name,action){const pair=groups[group].slice(0,2),names=group==='hit-fields'?['hit.scan']:['traverse','choose','choose.go','opaque','make','consume'];
 const observations=pair.map(m=>{const restore=snapshot(m,names),events=[];let value,error;try{value=action(m,events);}catch(e){error={name:e.name,message:e.message};}finally{restore();}return{value:norm(value),error,events:norm(events)};});
 report.current={group,name,observations};assert.deepEqual(observations[1],observations[0],group+':'+name);report.boundaries.push(report.current);delete report.current;}
function changed(m,e,name,kind){const d=m.G[name],old=d.code;if(kind==='binding')Object.defineProperty(m.G,name,{configurable:true,get(){e.push('get:'+name);return d;}});
 else if(kind==='getter')Object.defineProperty(d,'code',{configurable:true,get(){e.push('code:'+name);return old;}});
 else d.code=function(a){e.push('call:'+name);return Reflect.apply(old,this,[a]);};}
try{
 assert.equal(JSON.parse(fs.readFileSync(path.join(base,'derive.json'))).complete,true);
 for(const name of ['hit-fields','partial-tree']){const file=path.join(base,name,'derive.json'),meta=JSON.parse(fs.readFileSync(file));assert.equal(meta.complete,true);report.inputs.push(identity(file));groups[name]=[];
  for(const role of roles){const row=meta.variants[role],source=row.file;assert.equal(identity(source).sha256,row.sha256);report.inputs.push(identity(source));let use=source;
   if(role==='candidate'){let text=fs.readFileSync(source,'utf8');const target=name==='hit-fields'?'hit.scan':'traverse',lines=text.split('\n'),at=lines.findIndex(l=>l.startsWith('G["'+target+'"]='));assert(at>=0);
    const marker=name==='hit-fields'?'/* private final Bool loop */':'/* private scalar tree */';assert(lines[at].includes(marker),target+' optimized shape');
    if(name==='partial-tree'){assert.equal(lines[at].split(marker).length,2);lines[at]=lines[at].replace(marker,marker+'$regionEntries++;');}
    text=lines.join('\n')+'\nlet $regionEntries=0;export function regionEntryCount(){return $regionEntries;}\n';use=path.join(out,name+'-diagnostic.mjs');fs.writeFileSync(use,text,{flag:'wx'});
    report.structure[name]={marker,parent:identity(source),diagnostic:identity(use),modification:name==='partial-tree'?'one counter in admitted tree branch plus diagnostic export':'diagnostic export only'};
   }groups[name].push(await import(pathToFileURL(use)));
  }
 }
 for(const n of [0n,1n,2n,7n,32n])for(const d of [0,Math.fround(.1),-1,NaN])for(const i of [0,9,4294967295])for(const flag of [false,true]){
  const a=[n,d,i,flag],expected=hitOracle(...a),results=groups['hit-fields'].map((m,k)=>hit(m.default['hit.scan'](...(k===2?[Number(n),d,i,flag]:a))));
  report.current={group:'hit-fields',args:norm(a),expected:norm(expected),results:norm(results)};for(const r of results)assert.deepEqual(norm(r),norm(expected));report.oracle.push(report.current);delete report.current;
 }
 for(const n of [0n,1n,2n,5n,8n])for(const seed of [0,3,4294967295])for(const limit of [0,1,80,4294967295]){
  const a=[n,seed,limit],expected=treeOracle(...a),results=groups['partial-tree'].map((m,k)=>m.default.traverse(...(k===2?[Number(n),seed,limit]:a)));
  report.current={group:'partial-tree',args:norm(a),expected,results};for(const r of results)assert.equal(r,expected);report.oracle.push(report.current);delete report.current;
 }
 const candidate=groups['partial-tree'][1],before=candidate.regionEntryCount();candidate.default.traverse(2n,0,0);const inactive=candidate.regionEntryCount();candidate.default.traverse(2n,0,80);const active=candidate.regionEntryCount();
 assert.equal(inactive,before+1);assert.equal(active,inactive+1);report.admission={before,inactive,active};
 for(const group of ['hit-fields','partial-tree']){const target=group==='hit-fields'?'hit.scan':'traverse',args=group==='hit-fields'?[4n,Math.fround(.1),7,false]:[4n,3,80],names=group==='hit-fields'?['hit.scan']:['traverse','choose','choose.go','opaque','make','consume'];
  const ordinary=m=>m.default[target](...args);
  for(const n of [0,1,args.length-1])boundary(group,'prefix:'+n,m=>{const p=m.call(m.G[target],args.slice(0,n));return{arity:p.arity,bound:p.bound.length,name:p.code.name,length:p.code.length,keys:Reflect.ownKeys(p.code).map(String),value:m.call(p,args.slice(n)),reuse:m.call(p,args.slice(n))};});
  for(const name of names)for(const kind of ['wrapper','getter','binding'])boundary(group,name+':'+kind,(m,e)=>{changed(m,e,name,kind);return ordinary(m);});
  for(const key of ['fround','imul'])for(const kind of ['wrapper','getter','mutation','throw'])boundary(group,'Math:'+key+':'+kind,(m,e)=>{const old=Math[key];let count=0,once=false,result;
   const fn=function(...a){count++;if(kind==='throw')throw Error('Math sentinel');if(kind==='mutation'&&!once){once=true;changed(m,e,names.at(-1),'wrapper');}return Reflect.apply(old,Math,a);};
   try{result=hook(Math,key,kind==='getter'?{get(){count++;return old;}}:{value:fn},()=>ordinary(m));}finally{e.push(['events',count]);}return result;});
  for(const [label,proto]of[['Object',Object.prototype],['Array',Array.prototype]])for(const key of ['0','8'])boundary(group,'numeric-prototype:'+label+':'+key,(m,e)=>{
   let reads=0,writes=0,once=false,result;const victim=m.G[names.at(-1)],oldCode=victim.code;
   try{result=hook(proto,key,{get(){reads++;return undefined;},set(value){writes++;if(!once){once=true;victim.code=function(a){return Reflect.apply(oldCode,this,[a]);};}
     Object.defineProperty(this,key,{value,writable:true,enumerable:true,configurable:true});}},()=>ordinary(m));}
   finally{e.push(['numeric-events',reads,writes]);}return result;
  });
  for(const [label,proto]of[['Object',Object.prototype],['Array',Array.prototype],['Number',Number.prototype],['BigInt',BigInt.prototype]])for(const key of ['request','bounce','build','code'])boundary(group,'marker:'+label+':'+key,(m,e)=>{
   let count=0,result;try{result=hook(proto,key,{get(){count++;return undefined;}},()=>ordinary(m));}finally{e.push(['events',count]);}return result;});
  for(const value of [null,undefined,1.1,'0'])boundary(group,'noncanonical:'+String(value),m=>{const a=args.slice();a[1]=value;return m.default[target](...a);});
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,admission:report.admission,error:report.error}));
