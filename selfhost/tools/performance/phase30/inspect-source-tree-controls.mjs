// Checked source pipeline controls with independent scalar recurrences.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,(_,x)=>typeof x==='bigint'?{$bigint:String(x)}:x,2)+'\n');
const sides=['typescript','previous','candidate'],files=sides.map(x=>path.join(dir,x+'.mjs'));
const report={kind:'phase30-checked-source-tree-controls',complete:false,pass:false,
  inputs:[import.meta.filename,path.join(dir,'plan.json'),...files,...files.map(x=>x+'.json')].map(identity),
  scope:'Checked source to JS. Independent scalar recurrences and actual11/12 ordered live-owner fallback; no timing.',
  admission:[],oracle:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));save();
const add=(a,b)=>(a+b)>>>0,sub=(a,b)=>(a-b)>>>0,mul=(a,b)=>Math.imul(a,b)>>>0;
function reference(name,n,state){
  const bool=name==='bool_tree'||name==='native_bool_tree';
  if(!n){if(bool)return (state&7)<3;if(name==='nat_tree')return BigInt(state);return state;}
  if(name==='nat_state_tree'){const left=reference(name,n-1,state),right=reference(name,n-1,0n);return (right&0xffffffffn)===0n?left:0n;}
  if(name==='float_tree')return Math.fround(reference(name,n-1,Math.fround(state+0.5))-reference(name,n-1,Math.fround(state*3)));
  const left=reference(name,n-1,add(state,1));
  if(name==='one_child')return add(left,left);
  const right=reference(name,name==='changed_predecessor'?0:n-1,mul(state,3));
  if(bool)return left&&!right;
  if(name==='nat_tree')return BigInt(sub(Number(left),Number(right)));
  if(name==='parent_capture')return add(sub(left,right),state);
  if(name==='three_children')return sub(add(left,reference(name,n-1,(state^85)>>>0)),right);
  return sub(left,right);
}
function assignment(code,name){return code.split('\n').find(x=>x.startsWith('G['+JSON.stringify(name)+']='))??'';}
try{
 const modules=await Promise.all(files.map(x=>import(pathToFileURL(x))));
 const positive=['bool_tree','nat_tree','nat_state_tree'];
 const negative=['parent_capture','one_child','three_children','changed_predecessor','float_tree','record_tree','sequential_tree','native_bool_tree'];
 for(const name of [...positive,...negative]){
  const expected=positive.includes(name),old=assignment(fs.readFileSync(files[1],'utf8'),name),current=assignment(fs.readFileSync(files[2],'utf8'),name);
  assert.ok(old&&current,name+' emitted assignment');
  const admitted=current.includes('/* private scalar tree */');
  assert.equal(old.includes('/* private scalar tree */'),false,name+' previous');assert.equal(admitted,expected,name+' candidate');
  report.admission.push({name,expected,admitted});
 }
 for(const name of [...positive,...negative.filter(x=>x!=='record_tree'),'record_value']){
  const states=name==='nat_state_tree'?[0n,1n,4294967296n,281474976710655n]:name==='float_tree'?[0,-0,0.5,-2.25,Math.fround(1e20)]:[0,1,2,17,0xffffffff];
  for(const depth of [0,1,2,3,5])for(const state of states){
   const expected=reference(name,depth,state),values=modules.map(m=>m.default[name](BigInt(depth),state));
   report.current={name,depth,state,expected,values};
   for(const value of values)assert.ok(Object.is(value,expected),name+' independent scalar value');
   report.oracle.push({name,depth,state,expected});delete report.current;
  }
 }
 for(const name of positive)for(const saved of [false,true]){
  const observations=modules.slice(1).map(m=>{
   const original=m.G[name],code=original.code,events=[],seed=name==='nat_state_tree'?281474976710655n:17;
   const partial=saved?m.default[name](3n):null;
   try{original.code=function(args){events.push(args.map(x=>typeof x==='bigint'?String(x)+'n':x));return Reflect.apply(code,this,[args]);};
    return {value:saved?m.call(partial,[seed]):m.default[name](3n,seed),events};
   }finally{original.code=code;}
  });
  report.current={name,saved,observations};assert.deepEqual(observations[1],observations[0],name+' live-owner order');
  assert.ok(observations[0].events.length>0);report.boundaries.push({name,saved,observations});delete report.current;
 }
 for(const x of report.inputs)assert.deepEqual(identity(x.file),x);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,admission:report.admission.length,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
