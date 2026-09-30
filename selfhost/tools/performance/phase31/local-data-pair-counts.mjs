// Separate diagnostic modules: count administration in one complete pair.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const d=JSON.parse(fs.readFileSync(path.join(dir,'derive.json')));assert(d.complete);
const report={kind:'phase31-full-pair-operation-counts',complete:false,pass:false,inputs:[import.meta.filename,path.join(dir,'derive.json'),path.join(dir,'points.json')].map(identity),rows:[]};fs.copyFileSync(import.meta.filename,path.join(out,'consumed-counts.mjs'));
try{
 for(const name of Object.keys(d.variants).filter(v=>v!=='typescript')){
  const file=d.variants[name].file;report.inputs.push(identity(file));let text=fs.readFileSync(file,'utf8');
  function edit(a,b){assert.equal(text.split(a).length-1,1,a);text=text.replace(a,b)}
  const signatures={apply:'function apply(f,args,owned=false){',force:'function force(x){',project:'function project(k,x){',ctor:'function ctor(k,a){',arrayfill:'function arrayfill(v,n,mode){',arrayget:'function arrayget(a,i){',arrayset:'function arrayset(a,i,v){',guard:'function scalarGuard(names){'};
  for(const [key,value]of Object.entries(signatures))edit(value,value+'$count.'+key+'++;');
  edit('const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});','const fn=(arity,code,env=null,bound=[])=>{$count.fn++;if(bound.length)$count.partial++;return {arity,code,env,bound}};');
  edit('const jump=(f,args)=>({bounce:true,f,args});','const jump=(f,args)=>{$count.jump++;return {bounce:true,f,args}};');
  edit('const build=(name,fields)=>({build:true,name,fields});','const build=(name,fields)=>{$count.build++;return {build:true,name,fields}};');
  const zero=JSON.stringify(Object.fromEntries([...Object.keys(signatures),'fn','partial','jump','build'].map(k=>[k,0])));text='let $count='+zero+';\n'+text+'\nexport function pairCounts(reset=false){const x=$count;if(reset)$count='+zero+';return x}\n';
  const target=path.join(out,name+'.mjs');fs.writeFileSync(target,text,{flag:'wx'});const m=await import(pathToFileURL(target));m.pairCounts(true);const result=m.default.bench(0),counts=m.pairCounts();assert.equal(result,1866542166);assert.equal(counts.arrayfill,4);assert.equal(counts.arrayget,262401);assert.equal(counts.arrayset,66561);report.rows.push({name,result,counts,module:identity(target)});
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
