// Independent traversal model and paired public observations; no timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2);
assert(baseArg&&outArg,'usage: region-colf-controls.mjs DERIVED_DIR NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);assert(!fs.existsSync(out));
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifestFile=path.join(base,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
assert.equal(manifest.kind,'phase35-private-partial-colf-prototype');assert.equal(manifest.complete,true);
const variants=['original','baseline','partial'],files=variants.map(v=>path.join(base,v+'.mjs'));
for(let i=0;i<files.length;i++)assert.equal(identity(files[i]).sha256,manifest.modules.find(r=>r.variant===variants[i]).sha256);
fs.mkdirSync(out,{recursive:false});fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const report={kind:'phase35-private-partial-colf-controls',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,manifestFile,...files].map(identity),oracle:[],boundaries:[]};
const modules=[];for(const file of files)modules.push(await import(pathToFileURL(file)));
const modulus=1n<<32n,word=x=>Number((x%modulus+modulus)%modulus);
// Independent worklist traversal and BigInt U32 arithmetic. Active leaves call
// the unchanged ORIGINAL pixel; this oracle isolates traversal, not ray optics.
function model(depth,x,y,w,hw,hh){const pending=[[BigInt(depth),BigInt(x)]],order=[];let result=0;
 while(pending.length){const [n,xx]=pending.pop();if(n===0n){const px=Number((xx*2654435761n)&16383n);
   if(px<w){order.push(px);result=word(BigInt(result)+BigInt(modules[0].default.pixel(px,y,hw,hh)));}continue;}
  const p=n-1n,shift=p>=32n?0n:(1n<<p)&0xffffffffn;
  pending.push([p,BigInt(word(xx+shift))]);pending.push([p,xx]);
 }return {result,order};
}
function normalize(x,seen=new Set()){if(typeof x==='bigint')return String(x)+'n';if(typeof x==='function')return '[Function]';if(typeof x==='symbol')return String(x);
 if(x===undefined)return '[Undefined]';if(Object.is(x,-0))return '-0';if(typeof x==='number'&&!Number.isFinite(x))return String(x);
 if(x===null||typeof x!=='object')return x;if(seen.has(x))return '[Cycle]';seen.add(x);
 const r=Array.isArray(x)?x.map(v=>normalize(v,seen)):Object.fromEntries(Object.keys(x).sort().map(k=>[k,normalize(x[k],seen)]));seen.delete(x);return r;}
function snapshot(m){const rows=manifest.dependencies.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value,c=f.code,b=f.bound;
 return {name,gd,f,fd:Object.getOwnPropertyDescriptors(f),fp:Object.getPrototypeOf(f),c,cd:Object.getOwnPropertyDescriptors(c),cp:Object.getPrototypeOf(c),b,bd:Object.getOwnPropertyDescriptors(b)};});
 return()=>{for(const r of rows){for(const [v,d]of[[r.f,r.fd],[r.c,r.cd],[r.b,r.bd]]){for(const k of Reflect.ownKeys(v))if(!Object.hasOwn(d,k))delete v[k];Object.defineProperties(v,d);}
  Object.setPrototypeOf(r.f,r.fp);Object.setPrototypeOf(r.c,r.cp);Object.defineProperty(m.G,r.name,r.gd);}};}
function observe(m,action){const restore=snapshot(m),events=[];let value,error;try{value=action(m,events);}catch(e){error={name:e.name,message:e.message};}finally{restore();}
 return {value:normalize(value),error,events:normalize(events)};}
function boundary(name,action){const observations=modules.map(m=>observe(m,action));report.current={name,observations};
 for(let i=1;i<observations.length;i++)assert.deepEqual(observations[i],observations[0],name+':'+variants[i]);
 report.boundaries.push(report.current);delete report.current;}
function hook(object,key,value,action){const old=Object.getOwnPropertyDescriptor(object,key);try{Object.defineProperty(object,key,{configurable:true,...value});return action();}
 finally{if(old)Object.defineProperty(object,key,old);else delete object[key];}}
function changed(m,e,name,kind='wrap'){const d=m.G[name],old=d.code;
 if(kind==='binding')Object.defineProperty(m.G,name,{configurable:true,get(){e.push('G:'+name);return d;}});
 else if(kind==='getter')Object.defineProperty(d,'code',{configurable:true,get(){e.push('code:'+name);return old;}});
 else d.code=function(a){e.push('invoke:'+name);return Reflect.apply(old,this,[a]);};}
const args=[2n,0,0,16384,40,32],ordinary=m=>m.default.colf(...args);
const force=(m,x)=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
try{
 assert(fs.readFileSync(files[2],'utf8').includes('/* private partial colf prototype */'));
 const before=modules[2].colfEntryCount();
 modules[2].default.colf(2n,0,0,0,40,32);
 const inactive=modules[2].colfEntryCount();assert.equal(inactive,before+1,'inactive traversal entered exactly once');
 modules[2].default.colf(1n,0,0,16384,40,32);
 const active=modules[2].colfEntryCount();assert.equal(active,inactive+1,'active traversal entered exactly once');
 report.admission={before,inactive,active};
 for(const n of [0,1,2,4,8,14])for(const x of [0,1,4294967295]){
  const a=[BigInt(n),x,0,0,40,32],expected=model(...a),results=modules.map(m=>m.default.colf(...a));
  report.current={kind:'inactive',args:normalize(a),expected,results};for(const r of results)assert.equal(r,expected.result);report.oracle.push(report.current);delete report.current;
 }
 for(const n of [0,1,2])for(const x of [0,1,4294967295])for(const width of [1,80,16384]){
  const a=[BigInt(n),x,0,width,40,32],expected=model(...a),results=modules.map(m=>m.default.colf(...a));
  report.current={kind:'active',args:normalize(a),expected,results};for(const r of results)assert.equal(r,expected.result);report.oracle.push(report.current);delete report.current;
 }
 for(const value of [0,-0,Math.fround(.1),Infinity,-Infinity,NaN])for(const at of [4,5]){
  const a=[2n,0,0,0,40,32];a[at]=value;const results=modules.map(m=>m.default.colf(...a));
  report.current={kind:'float-input',args:normalize(a),expected:0,results};for(const r of results)assert.equal(r,0);report.oracle.push(report.current);delete report.current;
 }
 for(const count of [0,1,2,5])boundary('prefix:'+count,m=>{const p=m.call(m.G.colf,args.slice(0,count));
  return {arity:p.arity,bound:p.bound.length,name:p.code.name,length:p.code.length,own:Reflect.ownKeys(p.code).map(String),constructible:Object.hasOwn(p.code,'prototype'),first:m.call(p,args.slice(count)),reuse:m.call(p,args.slice(count))};});
 for(const count of [0,1,2,5])for(const name of ['colf','colf.px','colf.px.go','pixel','nearest','F32.to_u32'])boundary(`saved-prefix:${count}:${name}`,(m,e)=>{
  const p=m.call(m.G.colf,args.slice(0,count));changed(m,e,name);return m.call(p,args.slice(count));});
 for(const name of manifest.dependencies)for(const kind of ['wrap','getter','binding'])boundary(name+':'+kind,(m,e)=>{changed(m,e,name,kind);return ordinary(m);});
 for(const zero of [false,true])for(const kind of ['raw','forged','new','own-call','oversaturated','slot-getter','slot-mutation','slot-throw','slot-reentry'])boundary(`entry:${zero}:${kind}`,(m,e)=>{
  const p=m.call(m.G.colf,[zero?0n:2n]),code=p.code,values=[0,0,16384,40,32],frame={length:5,...values};let busy=false;
  Object.defineProperty(frame,'0',{get(){e.push('slot:0');if(kind==='slot-mutation')changed(m,e,'pixel');if(kind==='slot-throw')throw Error('slot sentinel');
   if(kind==='slot-reentry'&&!busy){busy=true;e.push(['nested',m.default.colf(1n,0,0,0,40,32)]);}return 0;}});
  // A successor prefix already owns its predecessor in bound; public apply
  // adds it before invoking fn6. Raw calls provide that frame explicitly.
  const raw=zero?frame:[1n,...values];
  if(kind==='raw'||kind==='forged')return force(m,Reflect.apply(code,null,[raw,kind==='forged']));
  if(kind==='new')return force(m,Reflect.construct(code,[raw]));
  if(kind==='own-call'){code.call=function(env,a){e.push('call');return Reflect.apply(code,env,[a]);};return m.call(p,values);}
  if(kind==='oversaturated')return m.call(p,[...values,99]);
  if(zero)return m.call(p,{slice(){e.push('slice');return frame;}});
  const full=[1n,...values];Object.defineProperty(full,'1',Object.getOwnPropertyDescriptor(frame,'0'));
  const unbound={...p,bound:[]};return m.call(unbound,{slice(){e.push('slice');return full;}});
 });
 for(const key of ['iterator','next','return','push','pop','concat','slice','every','species','spread'])boundary('array:'+key,(m,e)=>{
  let count=0,result;const action=()=>ordinary(m);
  if(key==='iterator'){const old=Array.prototype[Symbol.iterator];result=hook(Array.prototype,Symbol.iterator,{value:function(){count++;return Reflect.apply(old,this,[]);}},action);}
  else if(key==='next'||key==='return'){const p=Object.getPrototypeOf([][Symbol.iterator]()),old=p[key];result=hook(p,key,{value:function(...a){count++;return old?Reflect.apply(old,this,a):{done:true};}},action);}
  else if(key==='species')result=hook(Array,Symbol.species,{get(){count++;return Array;}},action);
  else if(key==='spread')result=hook(Array.prototype,Symbol.isConcatSpreadable,{get(){count++;return true;}},action);
  else{const old=Array.prototype[key];result=hook(Array.prototype,key,{value:function(...a){count++;return Reflect.apply(old,this,a);}},action);}
  e.push(['events',count]);return result;
 });
 for(const key of ['imul','fround','sqrt','trunc'])for(const kind of ['wrap','getter','mutation','throw'])boundary(`Math:${key}:${kind}`,(m,e)=>{
  const old=Math[key];let count=0,once=false,result;const fn=function(...a){count++;if(kind==='throw')throw Error('Math sentinel');
   if(kind==='mutation'&&!once){once=true;changed(m,e,'colf.px');}return Reflect.apply(old,Math,a);};
  try{result=hook(Math,key,kind==='getter'?{get(){count++;return old;}}:{value:fn},()=>ordinary(m));}finally{e.push(['events',count]);}return result;
 });
 for(const key of ['Math','Number','BigInt','Array'])boundary('global:'+key,(m,e)=>{const old=globalThis[key];let count=0;
  const result=hook(globalThis,key,{get(){count++;return old;}},()=>ordinary(m));e.push(['events',count]);return result;});
 for(const [label,p]of [['Object',Object.prototype],['Array',Array.prototype],['Number',Number.prototype],['Boolean',Boolean.prototype],['BigInt',BigInt.prototype]])for(const key of ['request','bounce','build','code'])boundary('marker:'+label+':'+key,(m,e)=>{
  let count=0;const result=hook(p,key,{get(){count++;return undefined;}},()=>ordinary(m));e.push(['events',count]);return result;
 });
 for(const at of [1,2,3,4,5])for(const value of [null,undefined,1.1,'0'])boundary(`noncanonical:${at}:${String(value)}`,m=>{const a=[1n,0,0,0,40,32];a[at]=value;return m.default.colf(...a);});
 for(const at of [1,3,4])boundary('boxed-coercion:'+at,(m,e)=>{const a=[1n,0,0,0,40,32];a[at]={valueOf(){e.push('valueOf');return 0;}};return m.default.colf(...a);});
 report.points=[{exportName:'colfCandidatePoint',args:[14,0,0],expected:0}];
 for(const m of modules.slice(1))assert.equal(m.colfCandidatePoint(14,0,0),0);
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,points:report.points,error:report.error}));
