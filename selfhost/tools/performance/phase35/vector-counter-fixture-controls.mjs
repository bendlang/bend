#!/usr/bin/env node
// Compiler predicate controls with independent scalar/tuple countdown oracles.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [cohortArg,outArg]=process.argv.slice(2),cohort=path.resolve(cohortArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});const hash=s=>createHash('sha256').update(s).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const manifestFile=path.join(cohort,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile)),variants=Object.keys(manifest.variants),files=variants.map(v=>manifest.variants[v].file);
assert.deepEqual(variants,['baseline','candidate','typescript']);
const report={kind:'phase35-counter-predicate-fixture-controls',complete:false,pass:false,inputs:[import.meta.filename,manifestFile,...files].map(identity),oracle:[],structure:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function oracle(n,seed){const mask=0xffffffffn;let x=BigInt(seed),y=(x+1n)&mask,i=x,xx=x,yy=y,old=0n,acc=x;
 for(let left=n;left>0;left--){const q=BigInt(left-1),j=(i+q)&mask;[x,y]=[(y+i)&mask,x^i];[xx,yy]=[(yy+j)&mask,xx^j];acc=(acc+old)&mask;old=q;i=(i+1n)&mask;}
 const keep=Number((x*65599n+y)&mask),observe=Number((xx*65599n+yy)&mask),store=Number((old&mask)^acc),scalar=Number((BigInt(seed)+BigInt(n))&mask);
 return {benchKeep:keep,benchObserve:observe,benchStore:store,benchScalar:scalar,benchAlias:keep,bench:((keep^observe)^(store^scalar))>>>0};}
try{
 const modules=[];for(const file of files)modules.push(await import(pathToFileURL(file)));
 for(const n of [0,1,2,3,17,257,4096])for(const seed of [0,1,17,4294967294,4294967295]){
  const expected=oracle(n,seed),results=[];for(const m of modules){const row={};for(const name of Object.keys(expected)){row[name]=m.default[name](n,seed);assert.equal(row[name],expected[name],name);}results.push(row);}
  report.oracle.push({n,seed,expected,results});
 }
 const source=fs.readFileSync(files[1],'utf8'),parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'],p={exports:{}};
 new Function('module','exports',parserSource)(p,p.exports);assert.equal(p.exports.version,'8.16.0');
 const ast=p.exports.parse(source,{ecmaVersion:'latest',sourceType:'module'}),privateName=name=>'$R_'+Array.from(name,c=>c.codePointAt(0)).join('_'),bodies=new Map();
 function visit(n){if(!n||typeof n!=='object')return;if(n.type==='FunctionDeclaration'&&n.id?.name?.startsWith('$R_')){const list=bodies.get(n.id.name)||[];list.push(source.slice(n.start,n.end));bodies.set(n.id.name,list);}for(const v of Object.values(n)){if(Array.isArray(v))v.forEach(visit);else if(v&&typeof v==='object')visit(v);}}
 visit(ast);
 for(const name of ['count.keep','count.observe','count.store','count.scalar','count.alias']){
  const found=bodies.get(privateName(name))||[],number=found.filter(s=>s.includes('regionCounterNumber($p0)-1')).length,bigint=found.filter(s=>s.includes('let $s0=$p0-1n;')).length;
  if(name==='count.keep')assert(number>0,'unobservable counter optimized');
  else{assert.equal(number,0,name+' retained Nat representation');if(name==='count.observe'||name==='count.store')assert(bigint>0,name+' remains an admitted vector loop, testing occurrence rejection');}
  report.structure.push({name,privateCopies:found.length,number,bigint});
 }
 for(const [entry,helper] of [['benchKeep','count.keep'],['benchObserve','count.observe'],['benchStore','count.store'],['benchScalar','count.scalar'],['benchAlias','count.alias']]){
  const observations=[];for(const m of modules.slice(0,-1)){const f=m.G[helper],old=f.code,events=[];try{f.code=()=>{events.push(helper);throw Error('mutation:'+helper)};try{observations.push({value:m.default[entry](3,17),events});}catch(error){observations.push({error:error.message,events});}}finally{f.code=old;}}
  assert.deepEqual(observations[1],observations[0]);report.boundaries.push({entry,helper,observations});
 }
 for(const i of report.inputs)assert.deepEqual(identity(i.file),i);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,structure:report.structure,error:report.error}));
