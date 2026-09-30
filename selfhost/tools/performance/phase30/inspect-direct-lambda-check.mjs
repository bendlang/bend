import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';

const dir=path.resolve(process.argv[2]);
const out=path.resolve(process.argv[3]);
const hash=p=>({file:p,sha256:crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex'),bytes:fs.statSync(p).size});
const paths=['baseline','guarded','upstream'].map(n=>path.join(dir,n+'.mjs'));
const mods=await Promise.all(paths.map(p=>import(pathToFileURL(p))));
const normalize=x=>typeof x==='bigint'?{bigint:String(x)}:typeof x==='function'?'[Function]':x===undefined?'[Undefined]':typeof x==='number'&&!Number.isFinite(x)?String(x):Object.is(x,-0)?'-0':Array.isArray(x)?x.map(normalize):x&&typeof x==='object'?Object.fromEntries(Object.keys(x).sort().map(k=>[k,normalize(x[k])])):x;
const same=(a,b)=>JSON.stringify(normalize(a))===JSON.stringify(normalize(b));
const records=[];
let complete=true;
function observe(id,args,expected){
  const values=mods.map(m=>m.default.mit(...args));
  const okay=same(values[0],values[1])&&same(values[0],values[2])&&(expected===undefined||same(values[0],expected));
  records.push({id,args:normalize(args),values:normalize(values),expected:normalize(expected),okay});complete&&=okay;
}
for(const n of [0n,1n,2n,7n,31n])for(const cr of [0,255,384,2147483648,4294967295])for(const ci of [0,256,4294967295])observe(`grid-${n}-${cr}-${ci}`,[n,cr,ci,0,0,0,0]);
for(const args of [[128n,0,0,0,0,0,0],[128n,4294967295,384,255,4294967295,0,4294967295],[50000n,0,0,0,0,0,0]])observe('boundary-'+args[0],args,args[0]===50000n?50000:undefined);
for(const size of [0,1,2]){
  const values=mods.map(m=>m.default.bench(size,0));const okay=same(values[0],values[1])&&same(values[0],values[2])&&(size!==2||values[0]===887240761);
  records.push({id:'bench-'+size,values,okay});complete&&=okay;
}
for(const args of [[0n],[1n],[7n,0],[7n,0,0,0]]){
  const values=mods.slice(0,2).map(m=>m.default.mit(...args));const okay=same(values[0],values[1]);records.push({id:'partial',args:normalize(args),values:normalize(values),okay});complete&&=okay;
}

const mutations={
  'code-own-call':(m,f,t)=>{f.code.call=function(env,args){t.push(['own.call',...args]);return args[0]>>>8;};},
  'code-own-call-getter':(m,f,t)=>{Object.defineProperty(f.code,'call',{configurable:true,get(){t.push('code.call.get');return Function.prototype.call;}});},
  'code-prototype-call':(m,f,t)=>{Object.setPrototypeOf(f.code,Object.create(Function.prototype,{call:{get(){t.push('code.prototype.call');return Function.prototype.call;}}}));},
  'g-replacement':(m,f,t)=>{m.G.asr8={arity:1,code:a=>{t.push(['replacement',...a]);return a[0]>>>8;},env:null,bound:[]};},
  'g-proxy':(m,f,t)=>{m.G.asr8=new Proxy(f,{get(target,key,receiver){t.push('get:'+String(key));return Reflect.get(target,key,receiver);}});},
  'g-getter':(m,f,t)=>{Object.defineProperty(m.G,'asr8',{configurable:true,get(){t.push('G.asr8');return f;}});},
  'code-replacement':(m,f,t)=>{f.code=a=>{t.push(['code',...a]);return a[0]>>>8;};},
  'code-getter':(m,f,t)=>{const code=f.code;Object.defineProperty(f,'code',{configurable:true,get(){t.push('code.get');return code;}});},
  'arity-change':(m,f,t)=>{f.arity=2;},
  'arity-getter':(m,f,t)=>{Object.defineProperty(f,'arity',{configurable:true,get(){t.push('arity.get');return 1;}});},
  'bound-change':(m,f,t)=>{f.bound=[0];},
  'bound-original-mutation':(m,f,t)=>{f.bound.push(0);},
  'bound-getter':(m,f,t)=>{const bound=f.bound;Object.defineProperty(f,'bound',{configurable:true,get(){t.push('bound.get');return bound;}});},
  'bound-proxy':(m,f,t)=>{f.bound=new Proxy([],{get(target,key,receiver){t.push('bound:'+String(key));return Reflect.get(target,key,receiver);}});},
  'env-change':(m,f,t)=>{f.env={shift:8};f.code=function(a){t.push(['env',this.shift,...a]);return a[0]>>>this.shift;};},
  'env-getter':(m,f,t)=>{Object.defineProperty(f,'env',{configurable:true,get(){t.push('env.get');return null;}});},
  'io-own-getter':(m,f,t)=>{Object.defineProperty(f,'io',{configurable:true,get(){t.push('io.get');return false;}});},
  'typeName-own':(m,f,t)=>{f.typeName='Synthetic';},
  'prototype-io-getter':(m,f,t)=>{Object.setPrototypeOf(f,Object.create(Object.prototype,{io:{get(){t.push('inherited.io');return false;}}}));},
  'sel-code-getter':(m,f,t)=>{const s=m.G.sel,c=s.code;Object.defineProperty(s,'code',{configurable:true,get(){t.push('sel.code.get');return c;}});},
  'sel-partial-replacement':(m,f,t)=>{m.G.sel={arity:4,code:a=>{t.push(['sel',...a]);return a[1]===0?a[2]:a[3];},env:null,bound:[99]};},
};
function mutationRun(m,change){
 const gs=Object.getOwnPropertyDescriptors(m.G), f=m.G.asr8, s=m.G.sel;
 const fd=Object.getOwnPropertyDescriptors(f),sd=Object.getOwnPropertyDescriptors(s),fp=Object.getPrototypeOf(f),sp=Object.getPrototypeOf(s),bound=f.bound;
 const codes=[f.code,s.code].map(code=>({code,descriptors:Object.getOwnPropertyDescriptors(code),prototype:Object.getPrototypeOf(code)}));
 const transcript=[];let result;
 try{change(m,f,transcript);result={returned:normalize(m.default.mit(2n,255,384,0,0,0,0)),transcript};}
 catch(error){result={thrown:{name:error.name,message:error.message},transcript};}
 finally{
  for(const k of Object.getOwnPropertyNames(f))if(!(k in fd))delete f[k];
  for(const k of Object.getOwnPropertyNames(s))if(!(k in sd))delete s[k];
  for(const {code,descriptors,prototype}of codes){for(const k of Object.getOwnPropertyNames(code))if(!(k in descriptors))delete code[k];Object.setPrototypeOf(code,prototype);Object.defineProperties(code,descriptors);}
  bound.length=0;Object.setPrototypeOf(f,fp);Object.setPrototypeOf(s,sp);Object.defineProperties(f,fd);Object.defineProperties(s,sd);Object.defineProperties(m.G,gs);
 }
 return result;
}
for(const [name,change]of Object.entries(mutations)){
 const values=mods.slice(0,2).map(m=>mutationRun(m,change));const okay=same(values[0],values[1]);records.push({id:name,values,okay});complete&&=okay;
}
const report={kind:'phase30-guarded-leading-lambda-correctness',complete,scope:'Selected pure outputs,public partial ABI and exact mutation/error transcripts; not full backend conformance.',inputs:[...paths.map(hash),hash(process.argv[1]),hash(path.join(dir,'derive.json'))],observations:records.length,records};
fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete,observations:records.length,failures:records.filter(r=>!r.okay).map(r=>r.id),out}));if(!complete)process.exitCode=1;
