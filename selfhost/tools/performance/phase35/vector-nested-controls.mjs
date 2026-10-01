#!/usr/bin/env node
// Two private loops with nested vectors and separately scoped field slots.
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
const report={kind:'phase35-nested-loop-vector-controls',complete:false,pass:false,
 inputs:[import.meta.filename,manifestFile,...files].map(identity),oracle:[],structure:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function oracle(n,seed) {
 const mask=0xffffffffn;let x=BigInt(seed),y=(x+1n)&mask,z=x^85n,stamp=x;
 for(let i=0;i<n;i++){
  const oldX=x,oldY=y;let index=stamp;
  for(let j=0;j<Number(stamp&3n);j++){[x,y]=[(y+index)&mask,x^index];index=(index+1n)&mask;}
  z=(z+(oldX^oldY))&mask;stamp=(stamp+1n)&mask;
 }
 return Number(((x*65599n+y)&mask)^((z*17n)&mask));
}
try {
 const modules=[];for(const file of files)modules.push(await import(pathToFileURL(file)));
 for(const n of [0,1,2,3,7,32,257,4096])for(const seed of [0,1,17,4294967294,4294967295]){
  const expected=oracle(n,seed),results=modules.map(m=>m.default.bench(n,seed));
  results.forEach(r=>assert.equal(r,expected));report.oracle.push({n,seed,expected,results});
 }
 for(const name of ['inner.walk','inner.step','outer.walk','outer.step','nested.score']){
  const observations=[];
  for(const m of modules.slice(0,-1)){
   const f=m.G[name],code=f.code,events=[];
   try{f.code=()=>{events.push(name);throw Error('mutation:'+name)};try{observations.push({value:m.default.bench(2,17),events})}catch(error){observations.push({error:error.message,events})}}
   finally{f.code=code;}
  }
  observations.slice(1).forEach(o=>assert.deepEqual(o,observations[0]));report.boundaries.push({name,observations});
 }
 const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'],p={exports:{}};
 new Function('module','exports',parserSource)(p,p.exports);assert.equal(p.exports.version,'8.16.0');
 const privateName=n=>'$R_'+Array.from(n,c=>c.codePointAt(0)).join('_');
 for(let i=0;i<files.length-1;i++) {
  const source=fs.readFileSync(files[i],'utf8'),tree=p.exports.parse(source,{ecmaVersion:'latest',sourceType:'module'}),loops=[];
  function walk(n){if(!n||typeof n!=='object')return;if(n.type==='FunctionDeclaration'&&['inner.walk','outer.walk'].some(x=>n.id?.name===privateName(x)))loops.push({name:n.id.name,virtualSlots:/let \$w0=/.test(source.slice(n.start,n.end))});for(const v of Object.values(n)){if(Array.isArray(v))v.forEach(walk);else if(v&&typeof v==='object')walk(v);}}
  walk(tree);report.structure.push({variant:variants[i],loops});
 }
 assert.ok(report.structure.some(r=>['inner.walk','outer.walk'].every(name=>r.loops.some(l=>l.name===privateName(name)&&l.virtualSlots))), 'candidate scalarizes both separately scoped private loops');
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);
 report.complete=report.pass=true;
} catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({pass:report.pass,complete:report.complete,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
