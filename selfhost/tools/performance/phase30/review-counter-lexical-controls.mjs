// Counter-only checks; broader public ABI and entry checks use the frozen configs.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [directoryArgument,outArgument]=process.argv.slice(2);
assert.ok(directoryArgument&&outArgument);
const directory=path.resolve(directoryArgument),out=path.resolve(outArgument);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const names=['baseline','number'],files=names.map(name=>path.join(directory,name+'.mjs'));
const probes=names.map(name=>path.join(directory,name+'-diagnostic.mjs'));
const pointsFile=path.resolve(import.meta.dirname,'../phase29/fixture-points.json');
const report={kind:'phase30-lexical-counter-controls',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,path.join(directory,'derive.json'),pointsFile,...files,...probes].map(identity),
 points:[],boundaries:[],representabilityChecks:0,
 scope:'Same current runtime; independent scalar oracle plus counter-only entry diagnostics. No timing or compiler-wide claim.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const normalize=(key,value)=>typeof value==='bigint'?{$bigint:String(value)}:value;
function probe(m,counter,{raw=false,forged=false,mutate=false}={}){
 const f=m.default.mit(1n),args=[0,0,0,0,0,0],code=m.G.asr8.code;
 try{
  if(mutate)m.G.asr8.code=()=>123;
  f.bound[0]=counter;
  return raw?Reflect.apply(f.code,null,[[counter,...args],...(forged?[true]:[])]):m.call(f,args);
 }finally{m.G.asr8.code=code}
}
try{
 const modules=await Promise.all(files.map(file=>import(pathToFileURL(file))));
 const diagnostics=await Promise.all(probes.map(file=>import(pathToFileURL(file))));
 const points=[...JSON.parse(fs.readFileSync(pointsFile)).points,
  {exportName:'point',args:[50000,0,0,0,0,0,0],expected:50000}];
 for(const point of points){
  const values=modules.map(m=>m.default[point.exportName](...point.args));
  report.current={point,values};for(const value of values)assert.equal(value,point.expected);
  report.points.push({...point,values});delete report.current;
 }
 for(const n of [1n,2n,31n,128n,50000n]){
  const observations=modules.map(m=>{
   const f=m.default.mit(n),bound=[...f.bound],code=f.code;
   const values=[m.call(f,[0,0,0,0,0,0]),m.call(f,[0,0,0,0,0,0])];
   assert.deepEqual(f.bound,bound);assert.equal(f.code,code);
   assert.deepEqual(values,[Number(n),Number(n)]);return {values,bound};
  });
  assert.deepEqual(observations[1],observations[0]);
  report.boundaries.push({name:'saved-partial-'+n,observations});
 }
 const edges=[0n,1n,2n,4294967295n,4294967296n,281474976710654n,281474976710655n];
 let seed=123456789n;
 for(let i=0;i<10000;i++){seed=(seed*25214903917n+11n)&((1n<<48n)-1n);edges.push(seed)}
 for(const n of edges){assert.equal(BigInt(Number(n)),n);if(n)assert.equal(BigInt(Number(n)-1),n-1n);report.representabilityChecks++}
 for(const n of edges.slice(0,7)){
  const values=diagnostics.map(m=>probe(m,n)),admitted=n<281474976710655n;
  report.current={name:'diagnostic-'+n,values};
  for(let i=0;i<values.length;i++){
   const expected=admitted?{phase:'private',counterType:i===0?'bigint':'number',counter:String(n),zero:n===0n,next:String(n===0n?0n:n-1n)}:{phase:'fallback',counterType:'bigint'};
   assert.deepEqual(values[i],expected);
  }
  report.boundaries.push({name:'diagnostic-'+n,values});delete report.current;
 }
 const rejected=[-1n,281474976710656n,0,1,1.5,NaN,Infinity,'0',null,undefined,new Number(1),Object(1n),
  {valueOf(){throw Error('must not coerce in entry check')}}];
 for(let i=0;i<rejected.length;i++){
  const counter=rejected[i],values=diagnostics.map(m=>probe(m,counter));
  for(const value of values)assert.deepEqual(value,{phase:'fallback',counterType:typeof counter});
  report.boundaries.push({name:'rejected-representation-'+i,values});
 }
 for(const [name,options]of [['raw',{raw:true}],['forged-raw',{raw:true,forged:true}],['mutated-helper',{mutate:true}]]){
  const values=diagnostics.map(m=>probe(m,281474976710654n,options));
  for(const value of values)assert.deepEqual(value,{phase:'fallback',counterType:'bigint'});
  report.boundaries.push({name,values});
 }
 report.changedInputs=report.inputs.filter(item=>identity(item.file).sha256!==item.sha256);
 assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,normalize,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,points:report.points.length,
 boundaries:report.boundaries.length,representabilityChecks:report.representabilityChecks,error:report.error}));
