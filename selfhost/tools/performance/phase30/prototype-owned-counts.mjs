// Named operations only, in separate instrumented modules. Never time these.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-closed-owned-row-mechanism-counts',complete:false,pass:false,
 scope:'Named runtime operation counts, not time shares or total allocations. Only instrumented copies execute.',
 inputs:[import.meta.filename,path.join(dir,'derive.json'),path.join(dir,'points.json')].map(identity),rows:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-counts.mjs'));
function instrument(text,variant){
 function edit(before,after){assert.equal(text.split(before).length-1,1,before);text=text.replace(before,after)}
 for(const name of ['apply','force','project','ctor','arrayfill','arrayget','arrayset']){
  const signatures={apply:'function apply(f,args,owned=false){',force:'function force(x){',project:'function project(k,x){',ctor:'function ctor(k,a){',
   arrayfill:'function arrayfill(v,n,mode){',arrayget:'function arrayget(a,i){',arrayset:'function arrayset(a,i,v){'};
  edit(signatures[name],signatures[name]+'$counts.'+name+'++;');
 }
 edit('const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});','const fn=(arity,code,env=null,bound=[])=>{$counts.fn++;if(bound.length)$counts.partial++;return {arity,code,env,bound}};');
 edit('const jump=(f,args)=>({bounce:true,f,args});','const jump=(f,args)=>{$counts.jump++;return {bounce:true,f,args}};');
 edit('const build=(name,fields)=>({build:true,name,fields});','const build=(name,fields)=>{$counts.build++;return {build:true,name,fields}};');
 edit('function scalarGuard(names){','function scalarGuard(names){$counts.guard++;');
 if(variant!=='baseline'){
  edit('/* owned row entry */','/* owned row entry */$counts.entry++;');
  const copy='const all=p.slice();';assert.equal(text.split(copy).length-1,5);
  text=text.replaceAll(copy,copy+'$counts.privateCopiedSlots+=all.length;');
 }
 const empty='{apply:0,force:0,project:0,ctor:0,arrayfill:0,arrayget:0,arrayset:0,fn:0,partial:0,jump:0,build:0,guard:0,entry:0,privateCopiedSlots:0}';
 return 'let $counts='+empty+';\n'+text+'\nexport function ownedCounts(reset=false){const old=$counts;if(reset)$counts='+empty+';return old;}\n';
}
try{
 const points=JSON.parse(fs.readFileSync(path.join(dir,'points.json')));
 for(const variant of ['baseline','private_cell','private_scalar','private_row']){
  const source=path.join(dir,variant+'.mjs');report.inputs.push(identity(source));
  const target=path.join(out,variant+'.mjs');fs.writeFileSync(target,instrument(fs.readFileSync(source,'utf8'),variant),{flag:'wx'});
  const m=await import(pathToFileURL(target));
  for(const n of [0,1,32,64]){
   const point=points.find(p=>p.args[0]===n&&p.args[1]===17);m.ownedCounts(true);const result=m.default.bench(...point.args),counts=structuredClone(m.ownedCounts());
   assert.equal(result,point.expected);assert.equal(counts.arrayfill,4);assert.equal(counts.arrayget,4*n);assert.equal(counts.arrayset,4*n+1);
   assert.equal(counts.build,n+1);assert.equal(counts.ctor,n+2);
   assert.equal(counts.entry,variant==='baseline'?0:1);assert.equal(counts.guard,variant==='baseline'?0:1);
   if(variant!=='baseline')assert.equal(counts.privateCopiedSlots,12*n);
   report.rows.push({variant,args:point.args,result,counts});
  }
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
