// Mechanism counters and explicit-stack shape checks; never time these copies.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const variants=['baseline','public_leaf','private_leaf'];
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-private-scalar-tree-counts',complete:false,pass:false,
  scope:'Administrative events and explicit-stack shape, instrumented modules only; no timing or total-allocation claim.',
  inputs:[identity(import.meta.filename),identity(path.join(dir,'derive.json'))],rows:[],stackChecks:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-counts.mjs'));
function instrument(text,variant){
  function edit(before,after){assert.equal(text.split(before).length-1,1,before);text=text.replace(before,after)}
  edit('function apply(f,args,owned=false){','function apply(f,args,owned=false){$counts.apply++;');
  edit('const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});','const fn=(arity,code,env=null,bound=[])=>{$counts.fn++;if(bound.length)$counts.partial++;return {arity,code,env,bound}};');
  edit('const jump=(f,args)=>({bounce:true,f,args});','const jump=(f,args)=>{$counts.jump++;return {bounce:true,f,args}};');
  edit('const build=(name,fields)=>({build:true,name,fields});','const build=(name,fields)=>{$counts.build++;return {build:true,name,fields}};');
  edit('function force(x){','function force(x){$counts.force++;');
  edit('function project(k,x){','function project(k,x){$counts.project++;');
  edit('function ctor(k,a){','function ctor(k,a){$counts.ctor++;');
  edit('function scalarGuard(names){','function scalarGuard(names){const $label=names.join(",");$counts.guards[$label]=($counts.guards[$label]||0)+1;');
  if(variant!=='baseline'){
    edit('const $tree30Stack=[];','const $tree30Stack=[];$counts.treeEntries++;');
    edit('$tree30Visit:for(;;){','$tree30Visit:for(;;){$counts.treeNodes++;');
    const push=text.match(/\$tree30Stack\[\$tree30Top\+\+\]=\{args:\[[^\]]*\],phase:0,left:0\};/g);assert.equal(push.length,1);
    edit(push[0],push[0]+'$counts.frames++;$counts.highWater=Math.max($counts.highWater,$tree30Top);');
    const leaf=variant==='public_leaf'?'$tree30Value=force(':'$tree30Value=$tree30Rpix(';
    edit(leaf,'$counts.treeLeaves++;$counts.indices.push($tree30S1);'+leaf);
    edit('$tree30Stack.length=--$tree30Top;','$counts.treeCombines++;$tree30Stack.length=--$tree30Top;');
  }
  const empty='{apply:0,fn:0,partial:0,jump:0,build:0,force:0,project:0,ctor:0,guards:{},treeEntries:0,treeNodes:0,treeLeaves:0,treeCombines:0,frames:0,highWater:0,indices:[]}';
  return 'let $counts='+empty+';\n'+text+'\nexport function treeCounts(reset=false){const old=$counts;if(reset)$counts='+empty+';return old;}\n';
}
try{
  for(const variant of variants){
    const source=path.join(dir,variant+'.mjs'),target=path.join(out,variant+'.mjs');report.inputs.push(identity(source));
    fs.writeFileSync(target,instrument(fs.readFileSync(source,'utf8'),variant),{flag:'wx'});
    const m=await import(pathToFileURL(target));
    for(const [size,expected]of [[0,2747870681],[2,887240761]]){
      m.treeCounts(true);const result=m.default.bench(size,0),counts=structuredClone(m.treeCounts());assert.equal(result,expected);
      report.rows.push({variant,name:'original-bench',args:[size,0],result,counts});
    }
    for(const depth of [1,2,3,5,6])for(const index of [0,4294967292]){
      m.treeCounts(true);const result=m.default.rcol(BigInt(depth),index,7n,1,3,7,17,31,63,127,255),counts=structuredClone(m.treeCounts());
      if(variant!=='baseline'){
        assert.equal(counts.treeEntries,1);assert.equal(counts.treeNodes,2**(depth+1)-1);
        assert.equal(counts.treeLeaves,2**depth);assert.equal(counts.treeCombines,2**depth-1);
        assert.equal(counts.frames,2**depth-1);assert.equal(counts.highWater,depth);
        assert.deepEqual(counts.indices,Array.from({length:2**depth},(_,n)=>(index+n)>>>0));
      }
      report.stackChecks.push({variant,depth,index,result,counts});
    }
  }
  for(const row of report.stackChecks){const baseline=report.stackChecks.find(x=>x.variant==='baseline'&&x.depth===row.depth&&x.index===row.index);assert.equal(row.result,baseline.result)}
  for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,stackChecks:report.stackChecks.length,error:report.error}));
