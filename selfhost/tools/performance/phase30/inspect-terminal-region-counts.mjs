// Instrumented mechanism counts and direct internal apply/build checks. Never time these modules.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [sourceArg,outArg]=process.argv.slice(2),source=path.resolve(sourceArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const variants=['baseline','outer','acyclic','nested'];
const report={kind:'phase30-terminal-region-diagnostic-counts',complete:false,pass:false,
  scope:'Named administrative events for one exact original bench call and one complete 64-pixel chunk; instrumented copies only, not timings or total allocations.',
  inputs:[identity(import.meta.filename),identity(path.join(source,'derive.json'))],rows:[],buildControls:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-counts.mjs'));
function instrument(text){
  const edits=[
    ['function apply(f,args,owned=false){','function apply(f,args,owned=false){$counts.apply++;'],
    ['const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});','const fn=(arity,code,env=null,bound=[])=>{$counts.fn++;if(bound.length)$counts.partial++;return {arity,code,env,bound}};'],
    ['const jump=(f,args)=>({bounce:true,f,args});','const jump=(f,args)=>{$counts.jump++;return {bounce:true,f,args}};'],
    ['const build=(name,fields)=>({build:true,name,fields});','const build=(name,fields)=>{$counts.build++;return {build:true,name,fields}};'],
    ['function scalarGuard(names){','function scalarGuard(names){const $label=names.join(",");$counts.guards[$label]=($counts.guards[$label]||0)+1;'],
    ['function force(x){','function force(x){$counts.force++;'],
    ['function project(k,x){','function project(k,x){$counts.project++;'],
    ['function ctor(k,a){','function ctor(k,a){$counts.ctor++;'],
  ];
  for(const [before,after]of edits){assert.equal(text.split(before).length-1,1,before);text=text.replace(before,after)}
  return 'let $counts={apply:0,fn:0,partial:0,jump:0,build:0,force:0,project:0,ctor:0,guards:{}};\n'+text+
    '\nexport {apply as inspectionApply,force as inspectionForce};\n'+
    'export function inspectionCounts(reset=false){const old=$counts;if(reset)$counts={apply:0,fn:0,partial:0,jump:0,build:0,force:0,project:0,ctor:0,guards:{}};return old;}\n';
}
try{
  for(const variant of variants){
    const original=path.join(source,variant+'.mjs'),target=path.join(out,variant+'.mjs');
    report.inputs.push(identity(original));fs.writeFileSync(target,instrument(fs.readFileSync(original,'utf8')),{flag:'wx'});
    const m=await import(pathToFileURL(target));
    for(const depth of [0,2]){
      m.inspectionCounts(true);const result=m.default.bench(depth,0),counts=structuredClone(m.inspectionCounts());
      assert.equal(result,depth===0?2747870681:887240761);report.rows.push({variant,kind:'original-bench',args:[depth,0],result,counts});
    }
    m.inspectionCounts(true);const result=m.default.hchunk(64n,0,7n,0,0,0,0,0,0,0,0),counts=structuredClone(m.inspectionCounts());
    // At these 64 coordinates, the first update is inside and the second is
    // outside: zr²+zi² >= floor(501²/256)+floor(384²/256) >1024.
    assert.deepEqual(result,{$:'Hl',a:[0,64,0,0,0,0,0,0]});
    report.rows.push({variant,kind:'chunk64',result,counts});
    const partial=m.default.hchunk(3n),raw=m.inspectionApply(partial,[0,7n,0,0,0,0,0,0,0,0]);
    if(variant==='baseline')assert.equal(raw.bounce,true);
    else{
      assert.equal(raw.build,true);assert.equal(raw.name,'Hl');assert.equal(raw.fields.length,8);
      assert.ok(raw.fields.every(field=>typeof field==='function'));
      assert.deepEqual(raw.fields.map(field=>field()),[0,3,0,0,0,0,0,0]);
      // A second invocation must not overwrite the first build's immutable
      // field captures even though both loops share the private worker code.
      m.default.hchunk(5n,0,7n,1,2,3,4,5,6,7,8);
      assert.deepEqual(raw.fields.map(field=>field()),[0,3,0,0,0,0,0,0]);
    }
    assert.deepEqual(m.inspectionForce(raw),{$:'Hl',a:[0,3,0,0,0,0,0,0]});
    report.buildControls.push({variant,rawKind:variant==='baseline'?'bounce':'build',immutableTerminalFields:true,forcedResult:true,module:identity(target)});
  }
  for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,buildControls:report.buildControls.length,error:report.error}));
