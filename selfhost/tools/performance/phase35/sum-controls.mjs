// Independent numeric/structural oracle and paired public observations. No timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2);
assert(baseArg&&outArg,'usage: sum-controls.mjs DERIVED_DIR NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);assert(!fs.existsSync(out),'output must be new');
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifestFile=path.join(base,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
assert.equal(manifest.kind,'phase35-private-sum-prototype');assert.equal(manifest.complete,true);
const variants=['original','baseline','loop','sums'],files=variants.map(x=>path.join(base,x+'.mjs'));
for(let i=0;i<files.length;i++)assert.equal(identity(files[i]).sha256,manifest.modules.find(x=>x.variant===variants[i]).sha256);
fs.mkdirSync(out,{recursive:false});fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const report={kind:'phase35-private-sum-controls',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,manifestFile,...files].map(identity),variants,oracle:[],boundaries:[]};
const modules=[];for(const f of files)modules.push(await import(pathToFileURL(f)));
// The reference model uses opcode arrays, not generated {$,a} objects, and a
// postfix stack evaluator, not the candidate's recursive evaluator.
const wrap=x=>x>>>0,mul=(a,b)=>Math.imul(a,b)>>>0;
function random(x){x=wrap(x^(x<<13));x=wrap(x^(x>>>17));return wrap(x^(x<<5));}
function modelTree(depth,h){if(!depth)return ((h>>>8)&1)===0?[0]:[1,h&255];
 return [2+h%4,modelTree(depth-1,random(wrap(h^2654435761))),modelTree(depth-1,random(wrap(h+340573321)))];}
function postfix(tree,out=[]){if(tree[0]<2){out.push(tree);return out;}postfix(tree[1],out);postfix(tree[2],out);out.push([tree[0]]);return out;}
function modelEval(code,x){const stack=[];for(const op of code){if(op[0]===0)stack.push(x);else if(op[0]===1)stack.push(op[1]);else{
 const b=stack.pop(),a=stack.pop();stack.push(op[0]===2?wrap(a+b):op[0]===3?wrap(a-b):op[0]===4?mul(a,b):wrap(a^b));}}
 assert.equal(stack.length,1);return stack[0];}
function modelCandidate(seed,pts){const code=postfix(modelTree(5,random(seed)));let acc=0;
 for(let j=Number(pts)-1;j>=0;j--){const x=wrap(j),v=modelEval(code,x),target=wrap(mul(x,x)+wrap(mul(3,x)+7));
  acc=wrap(acc+(v<target?wrap(target-v):wrap(v-target)));}
 const fit=wrap(acc+mul(code.length,8));return [fit,seed,wrap(fit^mul(seed,2654435761))];}
function modelPick(a,b){return a[0]<b[0]?[a[0],a[1],wrap(a[2]+b[2])]:[b[0],b[1],wrap(a[2]+b[2])];}
function modelBatch(depth,seed,pts){if(depth===0)return modelCandidate(random(seed),pts);
 return modelPick(modelBatch(depth-1,wrap(mul(seed,1664525)+1),pts),modelBatch(depth-1,wrap(mul(seed,214013)+3),pts));}
function modelBench(depth,seed){const selected=modelBatch(depth,seed,16n);let bestSeed=selected[1],bestFit=selected[0];
 for(let r=31;r>=0;r--){const c=modelCandidate(random(wrap(bestSeed^mul(r+1,40503))),16n);if(c[0]<bestFit){bestFit=c[0];bestSeed=c[1];}}
 return wrap(wrap(bestFit^mul(bestSeed,2654435761))+selected[2]);}
function canonicalTree(x){assert(x&&typeof x==='object');assert(Array.isArray(x.a));
 const tag=['Var','Lit','Add','Sub','Mul','Xor'].indexOf(x.$);assert(tag>=0);
 assert.equal(x.a.length,tag===0?0:tag===1?1:2);
 return tag===0?[0]:tag===1?[1,x.a[0]]:[tag,canonicalTree(x.a[0]),canonicalTree(x.a[1])];}
function sel(x){assert.equal(x.$,'Sel');assert.equal(x.a.length,3);return x.a.slice();}
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
function changed(m,e,name,kind='wrap'){const d=m.G[name],old=d.code;if(kind==='binding')Object.defineProperty(m.G,name,{configurable:true,get(){e.push('G:'+name);return d;}});
 else if(kind==='getter')Object.defineProperty(d,'code',{configurable:true,get(){e.push('code:'+name);return old;}});
 else d.code=function(a){e.push('invoke:'+name);return Reflect.apply(old,this,[a]);};}
const args=[42,3n],ordinary=m=>m.default.cand(...args),force=(m,x)=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
try{
 for(const seed of [0,1,2,42,255,256,2147483648,4294967295]){
  for(const depth of [0,1,3,5]){const expected=modelTree(depth,seed),results=modules.map(m=>canonicalTree(m.default.gen(BigInt(depth),seed)));
   report.current={kind:'tree',depth,seed,expected,results};for(const r of results)assert.deepEqual(r,expected);report.oracle.push(report.current);delete report.current;}
  for(const pts of [0n,1n,2n,16n]){const expected=modelCandidate(seed,pts),results=modules.map(m=>sel(m.default.cand(seed,pts)));
   report.current={kind:'candidate',seed,pts:String(pts),expected,results};for(const r of results)assert.deepEqual(r,expected);report.oracle.push(report.current);delete report.current;}
 }
 for(const [depth,seed]of [[0,0],[2,42],[4,4294967295],[6,42]]){const expected=modelBench(depth,seed),results=modules.map(m=>m.default.bench(depth,seed));
  report.current={kind:'original-bench',depth,seed,expected,results};for(const r of results)assert.equal(r,expected);
  if(depth===6&&seed===42)assert.equal(expected,2490246820,'documented original result');report.oracle.push(report.current);delete report.current;}
 for(const count of [0,1,2])boundary('prefix:'+count,m=>{const p=m.call(m.G.cand,args.slice(0,count));if(count===2)return sel(p);
  return {arity:p.arity,bound:p.bound.length,name:p.code.name,length:p.code.length,own:Reflect.ownKeys(p.code).map(String),constructible:Object.hasOwn(p.code,'prototype'),result:sel(m.call(p,args.slice(count)))};});
 for(const count of [0,1])for(const name of ['cand','gen','eval','esize','floop','prng','adiff'])boundary(`saved-prefix:${count}:${name}`,(m,e)=>{const p=m.call(m.G.cand,args.slice(0,count));changed(m,e,name);return m.call(p,args.slice(count));});
 for(const name of manifest.dependencies)for(const kind of ['wrap','getter','binding'])boundary(name+':'+kind,(m,e)=>{changed(m,e,name,kind);return ordinary(m);});
 for(const kind of ['raw','forged','new','own-call','oversaturated','slot-getter','slot-mutation','slot-throw','slot-reentry'])boundary('entry:'+kind,(m,e)=>{
  const p=m.G.cand,code=p.code;let busy=false;const frame={length:2,1:3n};Object.defineProperty(frame,'0',{get(){e.push('slot:0');
   if(kind==='slot-mutation')changed(m,e,'gen');if(kind==='slot-throw')throw Error('slot sentinel');
   if(kind==='slot-reentry'&&!busy){busy=true;e.push(['nested',sel(force(m,Reflect.apply(code,null,[[7,1n]])))]);}return 42;}});
  if(kind==='raw'||kind==='forged')return force(m,Reflect.apply(code,null,[frame,kind==='forged']));
  if(kind==='new')return force(m,Reflect.construct(code,[frame]));
  if(kind==='own-call'){code.call=function(env,a){e.push('call');return Reflect.apply(code,env,[a]);};return ordinary(m);}
  if(kind==='oversaturated')return m.call(p,[...args,99]);return m.call(p,{slice(){e.push('slice');return frame;}});
 });
 for(const kind of ['alias','tag-getter','field-getter','array-getter','throw'])boundary('foreign-generator:'+kind,(m,e)=>{
  const leaf={$:'Lit',a:[17]},tree={$:'Add',a:[leaf,leaf]};
  if(kind==='tag-getter')Object.defineProperty(tree,'$',{get(){e.push('tag');return 'Add';}});
  if(kind==='field-getter'||kind==='throw')Object.defineProperty(tree.a,'0',{get(){e.push('field:0');if(kind==='throw')throw Error('field sentinel');return leaf;}});
  if(kind==='array-getter'){const fields=tree.a;Object.defineProperty(tree,'a',{get(){e.push('fields');return fields;}});}
  m.G.gen={arity:2,code(){e.push('foreign-gen');return tree;},env:null,bound:[]};return ordinary(m);
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
 for(const kind of ['wrap','getter','mutation','throw'])boundary('Math.imul:'+kind,(m,e)=>{const old=Math.imul;let count=0,once=false,result;
  const fn=function(...a){count++;if(kind==='throw')throw Error('Math sentinel');if(kind==='mutation'&&!once){once=true;changed(m,e,'eval');}return Reflect.apply(old,Math,a);};
  try{result=hook(Math,'imul',kind==='getter'?{get(){count++;return old;}}:{value:fn},()=>ordinary(m));}finally{e.push(['events',count]);}return result;
 });
 for(const key of ['Math','Number','BigInt','Array'])boundary('global:'+key,(m,e)=>{const old=globalThis[key];let count=0;
  const result=hook(globalThis,key,{get(){count++;return old;}},()=>ordinary(m));e.push(['events',count]);return result;});
 for(const [label,p]of [['Object',Object.prototype],['Array',Array.prototype],['Number',Number.prototype],['Boolean',Boolean.prototype],['BigInt',BigInt.prototype]])for(const key of ['request','bounce','build','code'])boundary('marker:'+label+':'+key,(m,e)=>{
  let count=0;const result=hook(p,key,{get(){count++;return undefined;}},()=>ordinary(m));e.push(['events',count]);return result;
 });
 for(const kind of ['object','proxy','mutation','throw'])boundary('coercion-seed:'+kind,(m,e)=>{
  let once=false;const object={valueOf(){e.push('valueOf');if(kind==='throw')throw Error('coercion sentinel');
   if(kind==='mutation'&&!once){once=true;changed(m,e,'eval');}return 42;}};
  const value=kind==='proxy'?new Proxy(object,{get(t,k,r){e.push('get:'+String(k));return Reflect.get(t,k,r);}}):object;
  return m.default.cand(value,1n);
 });
 boundary('coercion-count',(m,e)=>m.default.cand(42,{[Symbol.toPrimitive](hint){e.push('coerce:'+hint);return 1n;}}));
 for(const value of [-1,1.1,NaN,Infinity,null,undefined,'42'])boundary('noncanonical-seed:'+String(value),m=>m.default.cand(value,1n));
 for(const value of [null,undefined,1,'1'])boundary('noncanonical-count:'+String(value),m=>m.default.cand(42,value));
 for(const count of [0,1,8]){let expected=0;for(let i=0;i<count;i++){const r=modelCandidate(wrap(42+i),16n);expected=wrap(expected+r[0]+r[1]+r[2]);}
  const results=modules.slice(1).map(m=>m.sumCandidatePoint(count,42,16n));report.current={kind:'candidate-point',count,seed:42,expected,results};
  for(const r of results)assert.equal(r,expected);report.oracle.push(report.current);delete report.current;}
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
