// Actual runtime matcher1p versus its original matcher1/literal-fn behavior.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [runtimeFile,outArgument,mode='counterexample']=process.argv.slice(2);assert.ok(runtimeFile&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-prebinding-entry-scheduling',complete:false,mode,node:process.version,inputs:[import.meta.filename,runtimeFile].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-prebind-entry.mjs'));
const moduleFile=path.join(out,'runtime-diagnostic.mjs');fs.writeFileSync(moduleFile,fs.readFileSync(runtimeFile,'utf8')+'\nexport {call,fn,matcher1,matcher1p};\n',{flag:'wx'});report.module=identity(moduleFile);
try{
 const m=await import(pathToFileURL(moduleFile));
 function observe(optimized,kind){
  const events=[];let lengthReads=0;const fields={get length(){events.push('fields.length');return 2},slice(){events.push('fields.slice');if(kind==='field-throw')throw Error('field slice sentinel');return [7,11]}};
  const value={$:'ReviewRec',a:fields};const code=function(a){events.push('body');return a[0]+a[1]+a[2]};
  const f=optimized?m.matcher1p('ReviewRec',2,3,()=>code):m.matcher1('ReviewRec',()=>m.fn(3,code));
  if(kind==='code-call-observer')f.code.call=function(env,a){events.push('code.call');const raw=Reflect.apply(f.code,env,[a]);events.push(['raw-bounce',raw?.bounce===true]);return raw};
  let result,error,rawBounce,before;
  try{
   if(kind==='raw'){
    const raw=f.code.call(null,[value]);rawBounce=raw?.bounce===true;before=[...events];
    const p=m.call(m.fn(0,()=>raw),[]);result=m.call(p,[13]);
   }else if(kind==='exact'||kind==='code-call-observer'||kind==='field-throw'){
    const p=m.call(f,[value]);result=m.call(p,[13]);
   }else if(kind==='partial'){
    const p=m.call(f,[]);events.push(['matcher-partial',p.arity,p.bound.length]);result=m.call(p,[value,13]);
   }else{
    const copied=new Proxy([value,13],{get(t,k,r){if(k==='length'){events.push(['outer.length',++lengthReads]);if(lengthReads===4&&kind==='outer-throw')throw Error('outer length sentinel')}return Reflect.get(t,k,r)}});
    result=m.call(f,{slice(){events.push('outer.slice');return copied}});
   }
  }catch(e){error={name:e.name,message:e.message}}
  return {events,result,error,rawBounce,before};
 }
 for(const kind of ['exact','partial','outer','outer-throw','field-throw','raw','code-call-observer']){
  const baseline=observe(false,kind),candidate=observe(true,kind),same=JSON.stringify(baseline)===JSON.stringify(candidate);report.observations.push({kind,baseline,candidate,same});
  if(mode==='repaired')assert.deepEqual(candidate,baseline,kind);
 }
 report.differences=report.observations.filter(x=>!x.same).map(x=>x.kind);
 if(mode==='counterexample')assert.ok(report.differences.includes('outer')&&report.differences.includes('raw')&&report.differences.includes('outer-throw'));
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,mode,observations:report.observations.length,differences:report.differences,error:report.error}));
