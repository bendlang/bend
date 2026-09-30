// Differential host-array and native-descriptor controls; no timing.
import fs from 'node:fs';import assert from 'node:assert/strict';import crypto from 'node:crypto';import {pathToFileURL} from 'node:url';
const [root,out]=process.argv.slice(2);fs.mkdirSync(out);
const ident=file=>({file,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-native-array-semantic-controls',complete:false,pass:false,scope:'Original non-tail native calls versus guarded existing-helper calls. Standard builtin prototypes stable. Actual row getter/replacement cases plus helper-level metadata/forcing/partial cases; no timing.',inputs:[ident(import.meta.filename)],observations:[]};
const host=(arity,code,env=null,bound=[])=>({arity,code,env,bound});
const norm=(x,seen=new Set())=>{if(typeof x==='bigint')return String(x)+'n';if(x===null||typeof x!=='object')return typeof x==='function'?'function':x;if(seen.has(x))return 'cycle';seen.add(x);if(x.code)return {arity:x.arity,bound:x.bound.map(y=>norm(y,new Set(seen)))};if(Array.isArray(x))return x.map(y=>norm(y,new Set(seen)));return Object.fromEntries(Object.keys(x).filter(k=>!['bounce','build','f','args','fields','array'].includes(k)).map(k=>[k,norm(x[k],new Set(seen))]));};
try{
 const mods={};for(const side of ['unchanged','unchanged-array-guarded','private','private-array-guarded']){const path=root+'/'+side+'.mjs';report.inputs.push(ident(path));mods[side]=await import(pathToFileURL(path));}
 const invoke=(m,optimized,method,erased,array,index,value)=>optimized?m['A_'+method](m.G['Array.'+method],erased,array,index,value):m.call(m.G['Array.'+method],method==='get'?[erased,array,index]:[erased,array,index,value]);
 const scenario=(m,optimized,kind)=>{
  const events=[],storage=[3,5,7,11];let array={array:storage},index=5,erased=null,method='get',cleanup=()=>{};
  const key=k=>typeof k==='symbol'?String(k):k;
  if(kind==='array-getter')array={get array(){events.push('array');return storage}};
  if(kind==='backing-proxy')array={array:new Proxy(storage,{get(t,k,r){events.push(['get',key(k)]);return Reflect.get(t,k,r)},set(t,k,v,r){events.push(['set',key(k),v]);return Reflect.set(t,k,v,r)}})};
  if(kind==='array-throws')array={get array(){events.push('array');throw Error('array sentinel')}};
  if(kind==='invalid-array')array={};
  if(kind==='coerced-index')index={valueOf(){events.push('index');return 6}};
  if(kind==='index-throws')index={valueOf(){events.push('index');throw Error('index sentinel')}};
  if(kind==='erased-slot')erased={tag:'ignored'};
  if(kind.startsWith('set-')){method='set';array={get array(){events.push('array');return storage},get bounce(){events.push('bounce');return kind==='set-bounce'},get build(){events.push('build');return kind==='set-build'}};
   if(kind==='set-bounce'){array.f=host(0,()=>{events.push('continued');return 47});array.args=[];}
   if(kind==='set-build'){array.name='Dp';array.fields=[()=>{events.push('field');return 53}];}
  }
  const native=m.G['Array.'+method],original=Object.getOwnPropertyDescriptors(native),bound=native.bound,code=native.code,proto=Object.getPrototypeOf(code);
  if(kind==='replacement'){m.G['Array.get']=host(3,([t,a,i])=>{events.push(['replacement',i]);return [a,59]});cleanup=()=>m.G['Array.get']=native;}
  if(kind==='code-mutation')native.code=([t,a,i])=>{events.push(['code',i]);return [a,61]};
  if(kind==='arity-mutation')native.arity=2;
  if(kind==='environment-getter')Object.defineProperty(native,'env',{configurable:true,get(){events.push('env');return null}});
  if(kind==='bound-mutation')bound.push(null);
  if(kind==='bound-getter')Object.defineProperty(native,'bound',{configurable:true,get(){events.push('bound');return bound}});
  if(kind==='code-getter')Object.defineProperty(native,'code',{configurable:true,get(){events.push('code-get');return code}});
  if(kind==='code-call')Object.defineProperty(code,'call',{configurable:true,value:function(receiver,args){events.push('code.call');return Reflect.apply(code,receiver,[args])}});
  if(kind==='code-prototype')Object.setPrototypeOf(code,{call(receiver,args){events.push('prototype.call');return Reflect.apply(code,receiver,[args])}});
  let result,error;
  try{result=invoke(m,optimized,method,erased,array,index,43)}catch(e){error={name:e.name,message:e.message}}
  const answer={events,storage:[...storage],result:error?undefined:result===array?'same-array':Array.isArray(result)?['same-array',result[1]]:norm(result),error};
  cleanup();bound.length=0;Object.defineProperties(native,original);delete code.call;Object.setPrototypeOf(code,proto);
  return answer;
 };
 const cases=['regular','array-getter','backing-proxy','array-throws','invalid-array','coerced-index','index-throws','erased-slot','set-force','set-bounce','set-build','replacement','code-mutation','arity-mutation','environment-getter','bound-mutation','bound-getter','code-getter','code-call','code-prototype'];
 for(const [old,newSide]of [['unchanged','unchanged-array-guarded'],['private','private-array-guarded']])for(const name of cases){const expected=scenario(mods[old],false,name),actual=scenario(mods[newSide],true,name);assert.deepEqual(actual,expected,old+':'+name);report.observations.push({context:old,name,value:actual});}
 for(const [old,newSide]of [['unchanged','unchanged-array-guarded'],['private','private-array-guarded']]){
  const row=m=>{const events=[],a={array:[1,2,3,4]},b={get array(){events.push('B.array');return [3,2,1,0]}},prev={array:[0,1,2,3,4,5,6,7]},cur={array:[1,0,0,0,0,0,0,0]};const state=m.default.row(4n,0,1,m.ctor('Dp',[a,b,prev,cur]));return {events,arrays:state.a.map(x=>x.array)}};
  assert.deepEqual(row(mods[newSide]),row(mods[old]),old+':actual-row-getters');report.observations.push({context:old,name:'actual-row-getters'});
  const partial=m=>{const array={array:[67,71]};const f=m.default['Array.get'](null,array);return {arity:f.arity,boundLength:f.bound.length,result:m.call(f,[1])[1]}};
  assert.deepEqual(partial(mods[newSide]),partial(mods[old]),old+':public-partial');report.observations.push({context:old,name:'public-partial'});
 }
 for(const p of report.inputs)assert.deepEqual(ident(p.file),p);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
fs.copyFileSync(import.meta.filename,out+'/consumed-tool.mjs');fs.writeFileSync(out+'/report.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
