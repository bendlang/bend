// Diagnostic call counts for private helper initialization/forward references.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [helperArg,wholeArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const embedded=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'],module={exports:{}};new Function('exports','module',embedded)(module.exports,module);assert.equal(module.exports.version,'8.16.0');
const privateName=n=>/^\$R(?:_\d+)+$/.test(n),parse=text=>module.exports.parse(text,{ecmaVersion:'latest',sourceType:'module'});
function children(n){return Object.entries(n).flatMap(([key,value])=>value&&typeof value.type==='string'?[value]:Array.isArray(value)?value.filter(x=>x&&typeof x.type==='string'):[])}
function walk(n,visit,parent=null,ancestors=[]){visit(n,parent,ancestors);for(const c of children(n))walk(c,visit,n,[...ancestors,n])}
function instrument(text){
 assert.ok(!text.includes('$hoistReviewCounts'));const ast=parse(text),defs=[],parents=new Map();
 walk(ast,(n,parent)=>{if(n.type==='FunctionDeclaration'&&privateName(n.id.name)){defs.push(n);parents.set(n,parent)}});
 const edits=defs.map((d,i)=>({start:d.body.start+1,end:d.body.start+1,text:'$hoistReviewCounts.entries['+i+']++;'})),edges=[];
 walk(ast,(n,parent,ancestors)=>{
  if(n.type!=='CallExpression'||n.callee.type!=='Identifier'||!privateName(n.callee.name))return;
  const owner=ancestors.find(a=>defs.includes(a));if(!owner)return;
  const target=defs.find(d=>d.id.name===n.callee.name&&parents.get(d)===parents.get(owner));assert.ok(target);
  if(target.start>owner.end){const i=edges.length;edges.push({caller:owner.id.name,callee:target.id.name});edits.push({start:n.callee.start,end:n.callee.end,text:'($hoistReviewCounts.forward['+i+']++,'+n.callee.name+')'})}
 });
 assert.ok(edges.length);for(const e of edits.sort((a,b)=>b.start-a.start))text=text.slice(0,e.start)+e.text+text.slice(e.end);
 const names=defs.map(d=>d.id.name);
 text='const $hoistReviewCounts={entries:Array('+defs.length+').fill(0),forward:Array('+edges.length+').fill(0)};\n'+text+'\nexport function hoistReviewCounts(){return structuredClone($hoistReviewCounts);}\n';
 return {text,names,edges};
}
const report={kind:'phase30-hoist-initialization-counters',complete:false,pass:false,inputs:[identity(import.meta.filename)],rows:[],scope:'Instrumented copies only; all private entries and forward edges, no timing.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try{
 for(const [kind,dir,args,expected]of [['helper',path.resolve(helperArg),[128,524800],128],['whole',path.resolve(wholeArg),[2,0],887240761]]){
  let baselineCounts;
  for(const variant of ['baseline','hoisted']){
   const source=path.join(dir,variant+'.mjs');report.inputs.push(identity(source),identity(path.join(dir,'derive.json')));
   const {text,names,edges}=instrument(fs.readFileSync(source,'utf8')),target=path.join(out,kind+'-'+variant+'.mjs');fs.writeFileSync(target,text,{flag:'wx'});
   const m=await import(pathToFileURL(target)),initial=m.hoistReviewCounts();assert.ok(initial.entries.every(x=>x===0)&&initial.forward.every(x=>x===0));
   const value=m.default.bench(...args),counts=m.hoistReviewCounts();assert.equal(value,expected);assert.ok(counts.forward.some(x=>x>0));
   const totals={};for(let i=0;i<names.length;i++)totals[names[i]]=(totals[names[i]]??0)+counts.entries[i];
   if(variant==='baseline')baselineCounts=totals;else assert.deepEqual(totals,baselineCounts);
   report.rows.push({kind,variant,source:identity(source),diagnostic:identity(target),value,initial,counts,names,edges,totals});
  }
 }
 for(const item of report.inputs)assert.deepEqual(identity(item.file),item);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
