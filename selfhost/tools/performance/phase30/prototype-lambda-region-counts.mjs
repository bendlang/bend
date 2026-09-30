// Administrative mechanism counts, never used as a timing module.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const variants=['baseline','pix','rpix','both'];
const report={kind:'phase30-ordinary-lambda-region-counts',complete:false,pass:false,
  scope:'Named administrative events, instrumented modules only; not total allocations or performance timings.',
  inputs:[identity(import.meta.filename),identity(path.join(dir,'derive.json'))],rows:[]};
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
  const initial='{apply:0,fn:0,partial:0,jump:0,build:0,force:0,project:0,ctor:0,guards:{}}';
  return 'let $counts='+initial+';\n'+text+'\nexport function lambdaCounts(reset=false){const old=$counts;if(reset)$counts='+initial+';return old;}\n';
}
try{
  for(const variant of variants){
    const original=path.join(dir,variant+'.mjs'),target=path.join(out,variant+'.mjs');
    report.inputs.push(identity(original));fs.writeFileSync(target,instrument(fs.readFileSync(original,'utf8')),{flag:'wx'});
    const m=await import(pathToFileURL(target));
    for(const [size,expected]of [[0,2747870681],[2,887240761]]){
      m.lambdaCounts(true);const result=m.default.bench(size,0),counts=structuredClone(m.lambdaCounts());
      assert.equal(result,expected);report.rows.push({variant,name:'original-bench',args:[size,0],result,counts});
    }
    for(const root of ['pix','rpix']){
      const args=root==='pix'?[4095,7n]:[4095,7n,1,3,7,17,31,63,127,255];
      m.lambdaCounts(true);const result=m.default[root](...args),counts=structuredClone(m.lambdaCounts());
      report.rows.push({variant,name:root,args,result,counts});
    }
  }
  for(const row of report.rows){const baseline=report.rows.find(x=>x.variant==='baseline'&&x.name===row.name&&String(x.args)===String(row.args));assert.equal(row.result,baseline.result)}
  for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,(_,x)=>typeof x==='bigint'?{$bigint:String(x)}:x,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
