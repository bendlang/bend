// Isolated private-frame lifetime counters; diagnostic copies are never timed.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const derived=JSON.parse(fs.readFileSync(path.join(dir,'derive.json'))),variants=['baseline','reuse'];
const report={kind:'phase30-tree-frame-reuse-counters',complete:false,pass:false,node:process.version,
 scope:'Fresh per-invocation frame and args objects, reuse, exact left/right traversal and repeated-call values. Instrumented copies only, no timing or total-allocation claim.',
 inputs:[identity(import.meta.filename),identity(path.join(dir,'derive.json'))],rows:[],repeated:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-counts.mjs'));
function instrument(text,variant){
 const edit=(before,after)=>{assert.equal(text.split(before).length-1,1,before);text=text.replace(before,after)};
 edit('/* private scalar tree */','/* private scalar tree */$counts.entries++;');
 edit('$visit:for(;;){','$visit:for(;;){$counts.nodes++;if($s0===0n){$counts.leaves++;$counts.indices.push($s1);}');
 let push=derived.proof.push,changed=push+'$counts.pushes++;$counts.fresh++;$counts.highWater=Math.max($counts.highWater,$top);';
 if(variant==='reuse'){
  push=derived.proof.replacementPush;
  changed=push.replace('if($reuseFrame30){','if($reuseFrame30){$counts.reuses++;');
  const allocation=changed.match(/else (\$frames\[\$top-1\]=\{args:\[[^\]]+\],phase:0,left:null\};)$/);
  assert.ok(allocation);changed=changed.replace(allocation[0],'else {'+allocation[1]+'$counts.fresh++;}');
  changed+='$counts.pushes++;$counts.highWater=Math.max($counts.highWater,$top);';
 }
 edit(push,changed);
 const pop=variant==='baseline'?derived.proof.pop:derived.proof.replacementPop;
 edit(pop,'$counts.combines++;'+pop);
 const empty='{entries:0,nodes:0,leaves:0,combines:0,pushes:0,fresh:0,reuses:0,highWater:0,indices:[]}';
 return 'let $counts='+empty+';\n'+text+'\nexport function frameCounts(reset=false){const old=$counts;if(reset)$counts='+empty+';return old;}\n';
}
function checkCounts(c,depth,index,variant){
 assert.equal(c.entries,1);assert.equal(c.nodes,2**(depth+1)-1);assert.equal(c.leaves,2**depth);
 assert.equal(c.combines,2**depth-1);assert.equal(c.pushes,2**depth-1);assert.equal(c.highWater,depth);
 assert.equal(c.fresh,variant==='baseline'?c.pushes:depth);assert.equal(c.reuses,c.pushes-c.fresh);
 assert.deepEqual(c.indices,Array.from({length:2**depth},(_,i)=>(index+i)>>>0));
}
try{
 for(const variant of variants){
  const source=path.join(dir,variant+'.mjs'),target=path.join(out,variant+'.mjs');report.inputs.push(identity(source));
  fs.writeFileSync(target,instrument(fs.readFileSync(source,'utf8'),variant),{flag:'wx'});
  const m=await import(pathToFileURL(target));
  for(const [size,expected]of [[0,2747870681],[2,887240761]]){
   m.frameCounts(true);const value=m.default.bench(size,0),counts=structuredClone(m.frameCounts());assert.equal(value,expected);
   checkCounts(counts,size+6,0,variant);report.rows.push({variant,kind:'bench',args:[size,0],value,counts});
  }
  for(const depth of [1,2,3,5,6])for(const index of [0,4294967292]){
   m.frameCounts(true);const value=m.default.rcol(BigInt(depth),index,7n,1,3,7,17,31,63,127,255),counts=structuredClone(m.frameCounts());
   checkCounts(counts,depth,index,variant);report.rows.push({variant,kind:'tree',depth,index,value,counts});
  }
  // Reuse cannot retain either tree state or palette across distinct invocations.
  for(const [i,depth]of [5,1,0,6,2,5,3,0].entries()){
   const index=(4294967295-Math.imul(i,123456789))>>>0,total=BigInt(i%5);
   const colors=Array.from({length:8},(_,j)=>(Math.imul(i+7,j*987654321)+j)>>>0);
   m.frameCounts(true);const value=m.default.rcol(BigInt(depth),index,total,...colors),counts=structuredClone(m.frameCounts());
   if(depth)checkCounts(counts,depth,index,variant);else assert.equal(counts.entries,0);
   report.repeated.push({variant,sequence:i,depth,index,total:String(total),colors,value,counts});
  }
 }
 for(const item of [...report.rows,...report.repeated].filter(x=>x.variant==='reuse')){
  const pool=Object.hasOwn(item,'sequence')?report.repeated:report.rows;
  const original=pool.find(x=>x.variant==='baseline'&&x.kind===item.kind&&x.depth===item.depth&&x.index===item.index&&x.sequence===item.sequence&&JSON.stringify(x.args)===JSON.stringify(item.args));
  assert.ok(original);assert.equal(item.value,original.value);
 }
 for(const item of report.inputs)assert.deepEqual(identity(item.file),item);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,repeated:report.repeated.length,error:report.error}));
