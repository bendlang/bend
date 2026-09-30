// Complete real pair outputs, state, native schedule and public refusal controls.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const variants=Object.keys(JSON.parse(fs.readFileSync(path.join(dir,'derive.json'))).variants);assert.equal(variants.at(-1),'typescript');const runtimeCount=variants.length-1;
const files=variants.map(n=>path.join(dir,n+'.mjs'));
const report={kind:'phase31-full-pair-controls',complete:false,pass:false,inputs:[import.meta.filename,path.join(dir,'derive.json'),path.join(dir,'points.json'),...files].map(identity),oracle:[],state:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function oracle(index){
 const mask=0xffffffffn,seed=((BigInt(index)+1n)*2654435761n)&mask;
 const trace=createHash('sha256');let calls=0;const event=x=>{trace.update(JSON.stringify(x)+'\n');calls++};
 function alloc(n){event(['new',++alloc.id,n,0]);return Array(n).fill(0)}alloc.id=0;
 function write(id,a,i,v){a[i%a.length]=v;event(['set',id,i,v])}
 function read(id,a,i){const v=a[i%a.length];event(['get',id,i,v]);return v}
 function draw(s,id){const a=alloc(256);for(let i=0;i<256;i++){s=(s^((s<<13n)&mask))&mask;s=(s^(s>>17n))&mask;s=(s^((s<<5n)&mask))&mask;write(id,a,i,Number(s&3n))}return a}
 const a=draw(seed,1),b=draw((seed*340573321n)&mask,2);let prev=alloc(512),cur;
 for(let i=0;i<257;i++)write(3,prev,i,i);cur=alloc(512);let prevId=3,curId=4;
 for(let i=0;i<256;i++){
  const ai=read(1,a,i);write(curId,cur,0,i+1);
  for(let j=0;j<256;j++){const bj=read(2,b,j),diag=read(prevId,prev,j),up=read(prevId,prev,j+1),left=read(curId,cur,j);write(curId,cur,j+1,Math.min(up+1,left+1,diag+(ai===bj?0:1)))}
  [prev,cur]=[cur,prev];[prevId,curId]=[curId,prevId];
 }
 const distance=read(prevId,prev,256),value=Number(((BigInt(distance)*2654435761n)&mask)^((BigInt(index)+1n)&mask));
 return{value,arrays:[a,b,prev,cur],schedule:{calls,sha256:trace.digest('hex')}};
}
function instrument(text){
 function edit(a,b){assert.equal(text.split(a).length-1,1,a);text=text.replace(a,b)}
 const intro='let $Pair_arrays=[],$Pair_ids=new WeakMap(),$Pair_next=0,$Pair_events=[];function $Pair_event(x){$Pair_events.push(x)}\n';
 edit("return {array:Array(size).fill(v)}}","const a={array:Array(size).fill(v)};$Pair_ids.set(a,++$Pair_next);$Pair_arrays.push(a);$Pair_event(['new',$Pair_next,size,v]);return a}");
 edit('function arrayget(a,i){const xs=arraydata(a);return [a,xs[Number(i)%xs.length]]}',"function arrayget(a,i){const xs=arraydata(a),v=xs[Number(i)%xs.length];$Pair_event(['get',$Pair_ids.get(a),Number(i),v]);return [a,v]}");
 edit('function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;return a}',"function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;$Pair_event(['set',$Pair_ids.get(a),Number(i),v]);return a}");
 return intro+text+'\nexport function pairDiagnostic(){return {arrays:$Pair_arrays.map(x=>x.array),events:$Pair_events};}\n';
}
function normalize(v){if(v===undefined)return'[undefined]';if(typeof v==='bigint')return String(v)+'n';return v}
try{
 const modules=await Promise.all(files.map(p=>import(pathToFileURL(p))));
 for(const point of JSON.parse(fs.readFileSync(path.join(dir,'points.json')))){
  const expected=oracle(point.args[0]);assert.equal(expected.value,point.expected);
  const results=modules.map(m=>m.default.bench(...point.args));for(const r of results)assert.equal(r,expected.value);
  report.oracle.push({point,results,oracle:expected.value});
 }
 assert.equal(report.oracle.slice(0,4).reduce((a,r)=>(a+r.oracle)>>>0,0),2065873279);
 for(let i=0;i<runtimeCount;i++){
  const p=path.join(out,variants[i]+'-instrumented.mjs');fs.writeFileSync(p,instrument(fs.readFileSync(files[i],'utf8')),{flag:'wx'});const m=await import(pathToFileURL(p));const value=m.default.bench(0),d=m.pairDiagnostic(),expected=oracle(0),h=createHash('sha256');
  for(const event of d.events)h.update(JSON.stringify(event)+'\n');const observed={calls:d.events.length,sha256:h.digest('hex')};
  assert.equal(value,expected.value);assert.deepEqual(d.arrays,expected.arrays);assert.deepEqual(observed,expected.schedule);
  report.state.push({variant:variants[i],value,arrays:d.arrays,schedule:observed,instrumented:identity(p)});
 }
 for(const name of ['pair','gen','init','row','cell','dp','dp.row','dp.f1','dist','dist.fin','Array.new','Array.get','Array.set']){
  const observations=[];
  for(let i=0;i<runtimeCount;i++){
   const m=modules[i],f=m.G[name],code=f.code,events=[];
   try{f.code=function(){events.push(name);throw Error('mutation:'+name)};try{observations.push({value:normalize(m.default.bench(0)),events})}catch(e){observations.push({error:e.message,events})}}finally{f.code=code}
  }
  for(const o of observations.slice(1))assert.deepEqual(o,observations[0]);report.boundaries.push({name,observations});
 }
 for(const mode of ['raw','forged','constructed','saved-partial']){
  const observations=[];
  for(let i=0;i<runtimeCount;i++){
   const m=modules[i],f=m.G.pair,code=f.code;
   let x;if(mode==='constructed')x=Reflect.construct(code,[[0]]);else if(mode==='saved-partial')x=m.call(m.default.pair(),[0]);else x=Reflect.apply(code,null,[[0],mode==='forged']);
   const value=m.call({arity:0,code:()=>x,env:null,bound:[]},[]);observations.push(mode==='constructed'?{ownKeys:Reflect.ownKeys(value),instance:value instanceof code}:value);
  }
  const expected=mode==='constructed'?{ownKeys:[],instance:true}:oracle(0).value;assert.deepEqual(observations,Array(runtimeCount).fill(expected));report.boundaries.push({mode,observations});
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,state:report.state.length,boundaries:report.boundaries.length,error:report.error}));
