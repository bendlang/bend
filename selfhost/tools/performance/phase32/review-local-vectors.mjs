// Prepared independent actual-output controls. Run only in a root-granted slot.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [outArg,...files]=process.argv.slice(2);
assert.ok(outArg&&files.length>=2,'usage: controls OUT BASELINE_MODULE CANDIDATE_MODULE ...');
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase32-independent-record-vector-controls',complete:false,pass:false,inputs:[import.meta.filename,...files,...files.map(f=>f+'.json')].map(identity),oracles:[],publicResults:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function box(x,y){return {$:'PairBox',a:[x,y]}}
try{
 const modules=[];
 for(const file of files){
  const receipt=JSON.parse(fs.readFileSync(file+'.json'));
  assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);
  assert.equal(identity(file).sha256,receipt.output.sha256);
  const text=fs.readFileSync(file,'utf8');
  assert.ok(text.includes('function $R_115_99_111_114_101_95_110_101_115_116('),'score_nest is actually a private helper');
  const root=text.split('\n').find(line=>line.startsWith('G["terminal"]=') );
  assert.ok(root?.includes('localGuard($guards)'),'terminal public record worker is exercised');
  modules.push(await import(pathToFileURL(fs.realpathSync(file))));
 }
 const receipts=files.map(f=>JSON.parse(fs.readFileSync(f+'.json')));
 for(const r of receipts.slice(1))assert.equal(r.input.sha256,receipts[0].input.sha256,'same checked source');
 for(const n of [0,1,2,3,7,16,32,129])for(const seed of [0,1,5,17,4294967295]){
  const expected=Number((BigInt(seed)+22n*BigInt(n))&0xffffffffn),actual=modules.map(m=>m.default.bench(n,seed));
  for(const value of actual)assert.equal(value,expected);report.oracles.push({n,seed,expected,actual});
  const fields=[Number((BigInt(seed)+BigInt(n))&0xffffffffn),7],observations=modules.map(m=>m.default.terminal(BigInt(n),seed));
  for(const value of observations){assert.equal(Array.isArray(value),false);assert.deepEqual(value,box(...fields));}
  report.publicResults.push({n,seed,fields,observations});
 }
 for(const m of modules){
  assert.deepEqual(m.default.pair_box(10,20),box(10,20));
  assert.deepEqual(m.default.nest(7,10),{$:'Nest',a:[box(10,7),7]});
 }
 for(const name of ['bench','walk','nest','pair_box','score_nest','score_box'])for(const mode of ['replace','getter']){
  const observations=[];
  for(const m of modules){const old=Object.getOwnPropertyDescriptor(m.G,name),f=m.G[name],events=[];
   try{
    if(mode==='replace')m.G[name]={...f,code:function(a){events.push('call:'+name);return Reflect.apply(f.code,this,[a])}};
    else Object.defineProperty(m.G,name,{configurable:true,get(){events.push('get:'+name);return f}});
    observations.push({value:m.default.bench(2,5),events});
   }finally{Object.defineProperty(m.G,name,old)}
  }
  for(const o of observations.slice(1))assert.deepEqual(o,observations[0]);assert.ok(observations[0].events.length);
  report.boundaries.push({name,mode,observations});
 }
 for(const mode of ['array-getter','field-proxy']){
  const observations=modules.map(m=>{const events=[],fields=[box(10,20),7];
   const item=mode==='array-getter'?Object.defineProperty({$:'Nest'},'a',{get(){events.push('outer fields');return fields}}):{$:'Nest',a:new Proxy(fields,{get(t,k,r){events.push('field:'+String(k));return Reflect.get(t,k,r)}})};
   return {value:m.default.score_nest(3,5,item),events};
  });
  for(const o of observations.slice(1))assert.deepEqual(o,observations[0]);assert.equal(observations[0].value,45);
  report.boundaries.push({mode,observations});
 }
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracles:report.oracles.length,publicResults:report.publicResults.length,boundaries:report.boundaries.length,error:report.error}));
