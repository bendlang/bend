// Version 2: preserve v1 observations; normalize only V8 callback text in the explicit nonconstructor test.
// Independent formula and paired public-stage observations. No timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2);assert(baseArg&&outArg,'usage: branch-controls-v2.mjs DERIVED_DIR NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifest=JSON.parse(fs.readFileSync(path.join(base,'derive.json')));
const variants=['baseline','branch'],files=variants.map(x=>path.join(base,x+'.mjs'));
const report={kind:'phase35-final-bool-loop-controls',complete:false,pass:false,node:process.version,inputs:[import.meta.filename,path.join(base,'derive.json'),...files].map(identity),oracle:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules=[];for(const f of files)modules.push(await import(pathToFileURL(f)));
const q=Math.fround,add=(a,b)=>q(a+b),sub=(a,b)=>q(a-b),mul=(a,b)=>q(a*b),div=(a,b)=>q(a/b),fl=(n,d)=>div(q(n),q(d));
const spheres=[
 [0,-10001,5,10000],[0,0,5,1],[2,fl(5,10),6,1],[-2,fl(5,10),6,1],
 [1,q(-fl(6,10)),fl(35,10),fl(4,10)],[-1,q(-fl(6,10)),fl(35,10),fl(4,10)],
 [0,fl(16,10),7,fl(12,10)],[fl(35,10),fl(2,10),8,1],[q(-fl(35,10)),fl(2,10),8,1]
];
function isect(index,ox,oy,oz,dx,dy,dz){const [cx,cy,cz,r]=spheres[index<8?index:8],px=sub(ox,cx),py=sub(oy,cy),pz=sub(oz,cz);
 const b=add(add(mul(px,dx),mul(py,dy)),mul(pz,dz)),d=sub(mul(b,b),sub(add(add(mul(px,px),mul(py,py)),mul(pz,pz)),mul(r,r)));
 if(d<0)return q(1000000000);const t=sub(sub(0,b),q(Math.sqrt(d)));return t<fl(1,1000)?q(1000000000):t;}
function oracle(n,ox,oy,oz,dx,dy,dz,pt,bt,flag){let best=flag?pt:bt;for(let i=Number(n)-1;i>=0;i--){const t=isect(i,ox,oy,oz,dx,dy,dz);best=t<best?t:best;}return best;}
function normalize(x,seen=new Set()){if(typeof x==='bigint')return String(x)+'n';if(typeof x==='function')return '[Function]';if(typeof x==='symbol')return String(x);
 if(x===undefined)return '[Undefined]';if(Object.is(x,-0))return '-0';if(typeof x==='number'&&!Number.isFinite(x))return String(x);
 if(x===null||typeof x!=='object')return x;if(seen.has(x))return '[Cycle]';seen.add(x);
 const r=Array.isArray(x)?x.map(v=>normalize(v,seen)):Object.fromEntries(Object.keys(x).sort().map(k=>[k,normalize(x[k],seen)]));seen.delete(x);return r;}
const args=[9n,0,0,0,0,0,1,1000000000,1000000000,false];
function snapshot(m){const rows=manifest.dependencies.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value,c=f.code,b=f.bound;
 return {name,gd,f,fd:Object.getOwnPropertyDescriptors(f),fp:Object.getPrototypeOf(f),c,cd:Object.getOwnPropertyDescriptors(c),cp:Object.getPrototypeOf(c),b,bd:Object.getOwnPropertyDescriptors(b)};});
 return()=>{for(const r of rows){for(const [v,d]of[[r.f,r.fd],[r.c,r.cd],[r.b,r.bd]]){for(const k of Reflect.ownKeys(v))if(!Object.hasOwn(d,k))delete v[k];Object.defineProperties(v,d);}
  Object.setPrototypeOf(r.f,r.fp);Object.setPrototypeOf(r.c,r.cp);Object.defineProperty(m.G,r.name,r.gd);}};}
function observe(m,action){const restore=snapshot(m),events=[];let value,error;try{value=action(m,events);}catch(e){error={name:e.name,message:e.message};}finally{restore();}
 return {value:normalize(value),error,events:normalize(events)};}
function boundary(name,action){const observations=modules.map(m=>observe(m,action));report.current={name,observations};
 // This case probes IsConstructor, not Function.prototype.toString. V8 includes
 // the changed callback source in its TypeError. Keep raw evidence and require
 // the same TypeError category, no result, and exactly the same semantic events.
 const compared=observations.map(o=>name==='final-entry:new'&&o.error?.name==='TypeError'&&o.error.message.endsWith(' is not a constructor')
   ? {...o,error:{name:o.error.name,message:'[callback] is not a constructor'}}:o);
 assert.deepEqual(compared[1],compared[0],name);
 report.boundaries.push({name,observations});delete report.current;}
const ordinary=m=>m.default['nearest.t'](...args);
const final=m=>m.call(m.G['nearest.t'],args.slice(0,9));
const force=(m,x)=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
function hook(object,key,value,action){const old=Object.getOwnPropertyDescriptor(object,key);try{Object.defineProperty(object,key,{configurable:true,...value});return action();}
 finally{if(old)Object.defineProperty(object,key,old);else delete object[key];}}
function changed(m,e,name,kind='wrap'){const d=m.G[name],old=d.code;if(kind==='binding')Object.defineProperty(m.G,name,{configurable:true,get(){e.push('G:'+name);return d;}});
 else if(kind==='getter')Object.defineProperty(d,'code',{configurable:true,get(){e.push('code:'+name);return old;}});
 else d.code=function(a){e.push('invoke:'+name);return Reflect.apply(old,this,[a]);};}
function point(a,label){const expected=oracle(...a),results=modules.map(m=>m.default['nearest.t'](...a));report.current={label,args:normalize(a),expected:normalize(expected),results:normalize(results)};
 for(const x of results)assert(Object.is(x,expected),label);report.oracle.push(report.current);delete report.current;}
try{
 assert(fs.readFileSync(files[1],'utf8').includes('/* private Bool loop prototype */'));
 for(const n of [0n,1n,2n,8n,9n,10n,32n])for(const flag of [false,true])for(const ox of [-3,-1,0,1,3])point([n,ox,0,0,0,0,1,7,1000000000,flag],`grid:${n}:${flag}:${ox}`);
 const specials=[0,-0,2**-149,-(2**-149),q(1+2**-23),q(3.4028234663852886e38),Infinity,-Infinity,NaN];
 for(let at=1;at<=8;at++)for(let i=0;i<specials.length;i++){const a=args.slice();a[0]=2n;a[at]=specials[i];point(a,`special:${at}:${i}`);}
 point([4096n,0,0,0,0,0,1,1000000000,1000000000,false],'deep-4096');
 for(const count of [0,1,2,8,9])boundary('prefix-shape:'+count,m=>{const p=m.call(m.G['nearest.t'],args.slice(0,count));return {arity:p.arity,bound:p.bound.length,codeName:p.code.name,codeLength:p.code.length,own:Reflect.ownKeys(p.code).map(String),constructible:Object.hasOwn(p.code,'prototype'),result:m.call(p,args.slice(count))};});
 for(const count of [0,1,2,8,9])for(const name of ['nearest.t','isect5','sx','fl'])boundary(`saved-prefix:${count}:${name}`,(m,e)=>{const p=m.call(m.G['nearest.t'],args.slice(0,count));changed(m,e,name);return m.call(p,args.slice(count));});
 for(const name of manifest.dependencies)for(const kind of ['wrap','getter','binding'])boundary(name+':'+kind,(m,e)=>{changed(m,e,name,kind);return ordinary(m);});
 for(const kind of ['raw','forged','own-call','new','slot-mutation','slot-throw','slot-reentry','oversaturated'])boundary('final-entry:'+kind,(m,e)=>{
  const p=final(m),code=p.code;const frame={length:1};let busy=false;
  frame[Symbol.iterator]=function*(){e.push('iterator');if(kind==='slot-mutation')changed(m,e,'isect5');if(kind==='slot-throw')throw Error('slot sentinel');
   if(kind==='slot-reentry'&&!busy){busy=true;e.push(['nested',m.call(final(m),[false])]);}yield false;};
  if(kind==='raw'||kind==='forged')return force(m,Reflect.apply(code,null,[frame,kind==='forged']));
  if(kind==='new')return Reflect.construct(code,[frame]);
  if(kind==='own-call'){code.call=function(env,a){e.push('call');return Reflect.apply(code,env,[a]);};return m.call(p,[false]);}
  if(kind==='oversaturated')return m.call(p,[false,99]);
  return m.call(p,{slice(){e.push('slice');return frame;}});
 });
 for(const key of ['iterator','next','return','concat','slice','every','species','spread'])boundary('array-protocol:'+key,(m,e)=>{
  let count=0;const event=()=>{count++;};let result;
  if(key==='iterator'){const old=Array.prototype[Symbol.iterator];result=hook(Array.prototype,Symbol.iterator,{value:function(){event();return Reflect.apply(old,this,[]);}},()=>ordinary(m));}
  else if(key==='next'||key==='return'){const p=Object.getPrototypeOf([][Symbol.iterator]()),old=p[key];result=hook(p,key,{value:function(...a){event();return old?Reflect.apply(old,this,a):{done:true};}},()=>ordinary(m));}
  else if(['concat','slice','every'].includes(key)){const old=Array.prototype[key];result=hook(Array.prototype,key,{value:function(...a){event();return Reflect.apply(old,this,a);}},()=>ordinary(m));}
  else if(key==='species')result=hook(Array,Symbol.species,{get(){event();return Array;}},()=>ordinary(m));
  else result=hook(Array.prototype,Symbol.isConcatSpreadable,{get(){event();return true;}},()=>ordinary(m));
  e.push(['events',count]);return result;
 });
 boundary('iterator-mutates-nearest',(m,e)=>{const p=final(m),old=Array.prototype[Symbol.iterator];let once=false;return hook(Array.prototype,Symbol.iterator,{value:function(){if(!once){once=true;changed(m,e,'nearest.t');}return Reflect.apply(old,this,[]);}},()=>m.call(p,[false]));});
 for(const key of ['fround','sqrt'])for(const kind of ['wrap','getter','mutation','throw'])boundary('Math:'+key+':'+kind,(m,e)=>{
  const old=Math[key];let count=0,once=false;const fn=function(...a){count++;if(kind==='throw')throw Error('Math sentinel');if(kind==='mutation'&&!once){once=true;changed(m,e,'nearest.t');}return Reflect.apply(old,Math,a);};
  let result;try{result=hook(Math,key,kind==='getter'?{get(){count++;return old;}}:{value:fn},()=>ordinary(m));}finally{e.push(['events',count]);}return result;
 });
 boundary('global-Math-getter',(m,e)=>{const original=Math;let count=0;const result=hook(globalThis,'Math',{get(){count++;return original;}},()=>ordinary(m));e.push(['events',count]);return result;});
 for(const [label,p]of [['Object',Object.prototype],['Number',Number.prototype],['Boolean',Boolean.prototype],['BigInt',BigInt.prototype]])for(const key of ['request','bounce','build','code'])boundary('marker:'+label+':'+key,(m,e)=>{
  let count=0;const result=hook(p,key,{get(){count++;return undefined;}},()=>ordinary(m));e.push(['events',count]);return result;
 });
 for(const at of [1,7,8,9])for(const value of [null,undefined,1.1,'0'])boundary('noncanonical:'+at+':'+String(value),m=>{const a=args.slice();a[0]=2n;a[at]=value;return m.default['nearest.t'](...a);});
 let expected=0;const bytes=new DataView(new ArrayBuffer(4));for(let k=0;k<1000;k++){bytes.setFloat32(0,oracle(9n,(k%5)-2,0,0,0,0,1,1000000000,1000000000,false),true);expected=(expected+bytes.getUint32(0,true))>>>0;}
 report.point={exportName:'bench',args:[1000,0],expected};for(const m of modules)assert.equal(m.default.bench(...report.point.args),expected);
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,point:report.point,error:report.error}));
