// Instrumented leaf mechanism counts only; never time these copies.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-f32-root-mechanism-counts',complete:false,pass:false,
 scope:'Single hit/miss leaf calls; named events rather than total allocations or runtime shares; instrumented copies never timed.',
 inputs:[import.meta.filename,path.join(base,'derive.json')].map(identity),rows:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-counts.mjs'));
try{
 for(const variant of ['baseline','f32-root']){
  const source=path.join(base,variant+'-leaf.mjs'),target=path.join(out,variant+'.mjs');report.inputs.push(identity(source));
  let text=fs.readFileSync(source,'utf8');
  const edits=[
   ['function apply(f,args,owned=false){','function apply(f,args,owned=false){$f32Counts.apply++;'],
   ['const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});','const fn=(arity,code,env=null,bound=[])=>{$f32Counts.fn++;if(bound.length)$f32Counts.partial++;return {arity,code,env,bound}};'],
   ['const jump=(f,args)=>({bounce:true,f,args});','const jump=(f,args)=>{$f32Counts.jump++;return {bounce:true,f,args}};'],
   ['function force(x){','function force(x){$f32Counts.force++;'],
   ['function scalarGuard(names){','function scalarGuard(names){$f32Counts.guard++;'],
  ];
  for(const [before,after]of edits){assert.equal(text.split(before).length-1,1,before);text=text.replace(before,after)}
  text='let $f32Counts={apply:0,fn:0,partial:0,jump:0,force:0,guard:0};\n'+text+
   '\nexport function inspectionCounts(reset=false){const old=$f32Counts;if(reset)$f32Counts={apply:0,fn:0,partial:0,jump:0,force:0,guard:0};return old}\n';
  fs.writeFileSync(target,text,{flag:'wx'});const m=await import(pathToFileURL(target));
  for(const [kind,args,expected]of [['hit',[5,0],4],['miss',[5,3],1000000000]]){
   m.inspectionCounts(true);const value=m.default.bench(...args),counts=structuredClone(m.inspectionCounts());
   assert.ok(Object.is(value,expected));report.rows.push({variant,kind,args,expected,counts,module:identity(target)});
  }
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows,error:report.error}));
