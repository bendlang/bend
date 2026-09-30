// Independent actual-emitter scalar-region controls. Modules share checked
// fixture-mandelbrot.bend; config: {baseline: path, candidate: path}.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [configArgument,outArgument]=process.argv.slice(2);assert.ok(configArgument&&outArgument);
const config=JSON.parse(fs.readFileSync(configArgument)),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const norm=x=>typeof x==='bigint'?{$bigint:String(x)}:typeof x==='function'?'[Function]':typeof x==='symbol'?String(x):x===undefined?'[Undefined]':Object.is(x,-0)?'-0':typeof x==='number'&&!Number.isFinite(x)?String(x):Array.isArray(x)?x.map(norm):x&&typeof x==='object'?Object.fromEntries(Object.keys(x).sort().map(k=>[k,norm(x[k])])):x;
const report={kind:'phase30-independent-scalar-compiler-execution',complete:false,pass:false,node:process.version,
 inputs:[identity(configArgument),identity(import.meta.filename),identity(config.baseline),identity(config.candidate)],observations:[],scalarObservations:[],
 scope:'Same checked Mandelbrot fixture through actual emitted modules. Public ABI, original binding snapshots and native scalar fallback. Prototype hooks run unless explicitly split into their own three-way diagnostic. No timing claim.',prototypeControlsSkipped:config.skipPrototypeControls===true};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-scalar-compiler-run.mjs'));
// The scheduling amendment also snapshots the recursive owner. Earlier raw
// evidence contains the consumed four-helper version of this tool.
const names=['asr8','sel','sel.go','b2u','mit'];
function snapshot(m){
 const rows=names.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value,code=f.code;return{name,gd,f,fd:Object.getOwnPropertyDescriptors(f),fp:Object.getPrototypeOf(f),code,cd:Object.getOwnPropertyDescriptors(code),cp:Object.getPrototypeOf(code),bound:f.bound}});
 return()=>{for(const r of rows){for(const k of Object.getOwnPropertyNames(r.f))if(!(k in r.fd))delete r.f[k];for(const k of Object.getOwnPropertyNames(r.code))if(!(k in r.cd))delete r.code[k];r.bound.length=0;Object.setPrototypeOf(r.code,r.cp);Object.defineProperties(r.code,r.cd);Object.setPrototypeOf(r.f,r.fp);Object.defineProperties(r.f,r.fd);Object.defineProperty(m.G,r.name,r.gd)}};
}
function observe(m,action){const restore=snapshot(m),events=[];try{return {value:norm(action(m,events)),events}}catch(e){return {error:{name:e.name,message:e.message},events}}finally{restore()}}
function oracle(n,cr,ci,zr,zi,esc,it){for(let i=0;i<n;i++){const r2=(Math.imul(zr,zr)>>8)>>>0,i2=(Math.imul(zi,zi)>>8)>>>0,e2=(esc|Number(((r2+i2)>>>0)>1024))>>>0,nzr=(r2-i2+cr)>>>0,nzi=(((Math.imul(2,Math.imul(zr,zi))>>8)>>>0)+ci)>>>0;zr=e2===0?nzr:zr;zi=e2===0?nzi:zi;esc=e2;it=(it+Number(e2===0))>>>0}return it}
try{
 const modules={};for(const [side,file]of [['baseline',config.baseline],['candidate',config.candidate]])modules[side]=await import(pathToFileURL(path.resolve(file)));
 const candidateText=fs.readFileSync(config.candidate,'utf8');assert.ok(candidateText.includes('/* private scalar region */'),'candidate must actually select a region');
 for(const name of names)assert.ok(candidateText.includes('scalarCapture('+JSON.stringify(name)+','),'capture original '+name);
 const test=(name,action)=>{const a=observe(modules.baseline,action),b=observe(modules.candidate,action);report.currentComparison={name,baseline:a,candidate:b};assert.deepEqual(b,a,name);report.observations.push({name,transcript:a});delete report.currentComparison};
 // This is deliberately the first call after module import.
 test('mutation-before-first-call',(m,e)=>{const f=m.G.asr8,code=f.code;f.code=function(a){e.push('first mutation');return code.call(this,a)};return m.default.mit(3n,255,384,0,0,0,0)});
 for(const name of names)for(const mode of ['G-getter','code-getter','code-wrapper','proxy','own-call','own-call-getter','arity-getter','bound-getter','env-getter','io-getter','typeName-getter'])test(name+'-'+mode,(m,e)=>{
  const f=m.G[name],code=f.code;
  if(mode==='G-getter')Object.defineProperty(m.G,name,{configurable:true,get(){e.push('G');return f}});
  if(mode==='code-getter')Object.defineProperty(f,'code',{configurable:true,get(){e.push('code');return code}});
  if(mode==='code-wrapper')f.code=function(a){e.push('wrapper');return code.call(this,a)};
  if(mode==='proxy')m.G[name]=new Proxy(f,{get(t,k,r){e.push('proxy:'+String(k));return Reflect.get(t,k,r)}});
  if(mode==='own-call')code.call=function(env,a){e.push('call');return Reflect.apply(code,env,a===undefined?[]:[a])};
  if(mode==='own-call-getter')Object.defineProperty(code,'call',{configurable:true,get(){e.push('call-getter');return function(env,a){return Reflect.apply(code,env,[a])}}});
  for(const key of ['arity','bound','env'])if(mode===key+'-getter'){const value=f[key];Object.defineProperty(f,key,{configurable:true,get(){e.push(key);return value}})}
  for(const key of ['io','typeName'])if(mode===key+'-getter')Object.defineProperty(f,key,{configurable:true,get(){e.push(key);return undefined}});
  return m.default.mit(3n,255,384,0,0,0,0);
 });
 for(const name of names)for(const mode of ['bound-push','arity','env','code-replace','typeName'])test(name+'-mutate-'+mode,(m,e)=>{
  const f=m.G[name];if(mode==='bound-push')f.bound.push(71);if(mode==='arity')f.arity++;if(mode==='env')f.env={changed:true};if(mode==='code-replace')f.code=()=>7;if(mode==='typeName')f.typeName='Changed';
  return m.default.mit(2n,255,384,0,0,0,0);
 });
 const choices=[['boxed',()=>new Number(7)],['proxy-boxed',e=>new Proxy(new Number(7),{get(t,k,r){e.push('get:'+String(k));return Reflect.get(t,k,r)}})],['coercible',e=>({[Symbol.toPrimitive](hint){e.push(hint);return 7}})],['coercion-mutation',(e,m)=>({[Symbol.toPrimitive](hint){e.push(hint);m.G.b2u.code=()=>{e.push('changed');return 1};return 7}})],['throws',e=>({valueOf(){e.push('valueOf');throw Error('coercion sentinel')}})],['nan',()=>NaN],['infinity',()=>Infinity],['negative',()=>-1],['fraction',()=>1.5],['negative-zero',()=>-0],['overflow',()=>4294967296],['symbol',()=>Symbol('scalar')]];
 for(const [label,make]of choices)for(const index of [1,3,6])test(label+'-'+index,(m,e)=>{const args=[2n,255,384,0,0,0,0];args[index]=make(e,m);return m.default.mit(...args)});
 for(const mode of ['object','proxy','mutation','call-hook','reentrant','reentrant-mutation'])test('frame-'+mode,(m,e)=>{
  const partial=m.default.mit(2n),values=[1n,255,384,0,0,0,0];let frame={};
  for(let i=0;i<7;i++)Object.defineProperty(frame,String(i),{get(){e.push('slot:'+i);
   if(i===2&&mode.startsWith('reentrant')){e.push(['nested',m.default.mit(1n,0,0,0,0,0,0)])}
   if(i===2&&(mode==='mutation'||mode==='reentrant-mutation')){const code=m.G.b2u.code;m.G.b2u.code=function(a){e.push('mutated:b2u');return code.call(this,a)}}
   if(i===2&&mode==='call-hook'){const code=m.G.asr8.code;code.call=function(env,a){e.push('mutated:call');return Reflect.apply(code,env,[a])}}
   return values[i]}});
  if(mode==='proxy')frame=new Proxy(frame,{get(t,k,r){e.push('proxy:'+String(k));return Reflect.get(t,k,r)}});
  return partial.code.call(null,frame);
 });
 for(const n of [0,'0',null,undefined])test('frame-counter-'+String(n),(m,e)=>{const p=m.default.mit(2n);return p.code.call(null,[n,255,384,0,0,0,0])});
 if(!config.skipPrototypeControls)for(const [label,prototype]of [['Object',Object.prototype],['Boolean',Boolean.prototype],['Number',Number.prototype],['BigInt',BigInt.prototype]])for(const key of ['request','bounce','build','code'])test(label+'-prototype-'+key,(m,e)=>{
  const old=Object.getOwnPropertyDescriptor(prototype,key);try{Object.defineProperty(prototype,key,{configurable:true,get(){e.push(label+'.'+key);return false}});return m.default.mit(2n,255,384,0,0,0,0)}finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key]}
 });
 for(const n of [0,1,3])test('public-partial-'+n,(m,e)=>{const p=m.default.mit(BigInt(n)),before=[...p.bound],result=m.call(p,[0,0,0,0,0,0]);return {keys:Object.keys(p),arity:p.arity,env:p.env,before,after:[...p.bound],result}});
 const states=[[0,0,0,0,0,0],[255,384,0,0,0,17],[0xffffffff,0,1,2,0,0xffffffff],[17,31,127,255,1,7],[0x80000000,0x7fffffff,17,31,0,0]];
 for(const n of [0,1,2,3,7,31,128,50000])for(const state of states){
  if(n===50000&&state!==states[0])continue;
  const expected=oracle(n,...state);for(const [side,m]of Object.entries(modules)){const actual=m.default.mit(BigInt(n),...state);assert.equal(actual,expected,side+' scalar '+n);report.scalarObservations.push({side,n,state,expected,actual})}
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,scalarObservations:report.scalarObservations.length,error:report.error}));
