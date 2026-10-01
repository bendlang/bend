// Independent selector values and observable public-boundary controls; no timing.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const names=['sx','sy','sz','sr','skr'],variants=['baseline','guarded','unprotected'];
const report={kind:'phase35-selector-controls',complete:false,pass:false,inputs:[import.meta.filename,path.join(base,'derive.json'),...variants.map(n=>path.join(base,n+'.mjs'))].map(identity),values:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const q=Math.fround,fl=(n,d)=>q(q(n)/q(d));
const tables={sx:[0,0,2,-2,1,-1,0,fl(35,10),q(-fl(35,10))],sy:[-10001,0,fl(5,10),fl(5,10),q(-fl(6,10)),q(-fl(6,10)),fl(16,10),fl(2,10),fl(2,10)],sz:[5,5,6,6,fl(35,10),fl(35,10),7,8,8],sr:[10000,1,1,1,fl(4,10),fl(4,10),fl(12,10),1,1],skr:[fl(3,10),fl(7,10),fl(4,10),fl(4,10),fl(9,10),fl(9,10),fl(1,10),fl(6,10),fl(6,10)]};
const view=new DataView(new ArrayBuffer(4));const bits=x=>{view.setFloat32(0,x,true);return view.getUint32(0,true);};
let serial=0;
const fresh=variant=>import(pathToFileURL(path.join(base,variant+'.mjs')).href+'?control='+serial++);
const normalize=x=>typeof x==='bigint'?String(x)+'n':Object.is(x,-0)?'-0':Number.isNaN(x)?'NaN':x;
async function boundary(name,action){
 const observations=[];
 for(const variant of ['baseline','guarded']){const m=await fresh(variant),events=[];let value,error;
  try{value=normalize(action(m,events));}catch(e){error={name:e.name,message:e.message};}
  observations.push({variant,value,error,events});
 }
 assert.deepEqual({...observations[1],variant:undefined},{...observations[0],variant:undefined},name);
 report.boundaries.push({name,observations});
}
try{
 for(const variant of variants){const m=await fresh(variant);
  for(const name of names)for(const n of [...Array(10).keys()].map(BigInt).concat([65536n,281474976710655n])){
   const result=m.default[name](n),expected=tables[name][Number(n<8n?n:8n)];assert.ok(Object.is(result,expected),`${variant}/${name}/${n}`);
   report.values.push({variant,name,input:String(n),result});
  }
 }
 for(const value of [undefined,null,-1n,281474976710656n,0,1,'0',{$:'Zero',a:[]}])await boundary('host-input:'+JSON.stringify(normalize(value)),m=>m.default.sx(value));
 for(const name of names){
  await boundary(name+':live-fl', (m,e)=>{m.G.fl.code=a=>{e.push(a.slice());return q(123.25);};return m.default[name](8n);});
  await boundary(name+':live-fl-error', (m,e)=>{m.G.fl.code=a=>{e.push(a.slice());throw Error('leaf sentinel');};return m.default[name](7n);});
  await boundary(name+':code-direct',m=>m.call({arity:0,code:()=>m.G[name].code([8n]),env:null,bound:[]},[]));
  await boundary(name+':code-call-hook',(m,e)=>{const code=m.G[name].code;code.call=function(env,a){e.push('call');return Reflect.apply(code,env,[a]);};return m.default[name](8n);});
 }
 for(const [label,prototype]of [['Object',Object.prototype],['Number',Number.prototype],['BigInt',BigInt.prototype],['Boolean',Boolean.prototype]])for(const key of ['request','bounce','build','code']){
  await boundary(label+'.'+key,(m,e)=>{const old=Object.getOwnPropertyDescriptor(prototype,key);try{Object.defineProperty(prototype,key,{configurable:true,get(){e.push(key);return false;}});return m.default.sx(8n);}finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key];}});
 }
 let expected=0;for(let k=0;k<4096;k++)for(const name of names)expected=(expected+bits(tables[name][k%9]))>>>0;
 report.point={exportName:'bench',args:[4096,0],expected};
 for(const variant of variants){const m=await fresh(variant);assert.equal(m.default.bench(...report.point.args),expected);}
 for(const item of report.inputs)assert.deepEqual(identity(item.path),item);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,values:report.values.length,boundaries:report.boundaries.length,point:report.point,error:report.error}));
