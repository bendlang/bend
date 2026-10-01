#!/usr/bin/env node
// Independent scalar oracle for old aliases and swapped loop-carried fields.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [cohortArg,outArg]=process.argv.slice(2),cohort=path.resolve(cohortArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=p=>({file:fs.realpathSync(p),sha256:createHash('sha256').update(fs.readFileSync(p)).digest('hex')});
const manifestFile=path.join(cohort,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
const variants=Object.keys(manifest.variants),files=variants.map(n=>manifest.variants[n].file||path.join(cohort,n+'.mjs'));
assert.equal(variants.at(-1),'typescript');
const report={kind:'phase35-loop-vector-alias-controls',complete:false,pass:false,
 inputs:[import.meta.filename,manifestFile,...files].map(identity),oracle:[],boundaries:[],negative:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const mask=0xffffffffn;
function oracle(n,seed,mutate=false) {
 let stamp=BigInt(seed),older=[(stamp+1n)&mask,stamp],st=[stamp,(stamp+1n)&mask];
 for(let i=0;i<n;i++){older=st;const next=[(st[1]+stamp)&mask,st[0]^stamp];st=next;stamp=(stamp+1n)&mask;if(mutate)older=st;}
 const score=p=>(p[0]*65599n+p[1])&mask;
 return Number(score(older)^((score(st)*17n)&mask));
}
try {
 const modules=[];for(const file of files)modules.push(await import(pathToFileURL(file)));
 for(const n of [0,1,2,3,7,32,257,4096])for(const seed of [0,1,17,4294967294,4294967295]){
  const expected=oracle(n,seed),results=modules.map(m=>m.default.bench(n,seed));
  results.forEach(r=>assert.equal(r,expected));report.oracle.push({n,seed,expected,results});
 }
 for(const name of ['bench','state.walk','state.step','state.score']){
  const observations=[];
  for(const m of modules.slice(0,-1)){
   const f=m.G[name],code=f.code,events=[];
   try{f.code=()=>{events.push(name);throw Error('mutation:'+name)};try{observations.push({value:m.default.bench(2,17),events})}catch(error){observations.push({error:error.message,events})}}
   finally{f.code=code;}
  }
  observations.slice(1).forEach(o=>assert.deepEqual(o,observations[0]));report.boundaries.push({name,observations});
 }
 for(const [n,seed]of [[1,17],[2,4294967295],[7,1]]){
  const correct=oracle(n,seed),wrong=oracle(n,seed,true);assert.notEqual(correct,wrong);
  report.negative.push({n,seed,correct,wrong,kind:'mutating-shared-output-buffer'});
 }
 report.structure=files.slice(0,-1).map((file,i)=>({variant:variants[i],virtualSlots:/let \$w0=/.test(fs.readFileSync(file,'utf8'))}));
 assert.ok(report.structure.some(x=>x.virtualSlots),'candidate must exercise scalarized loop fields');
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);
 report.complete=report.pass=true;
} catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({pass:report.pass,complete:report.complete,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
