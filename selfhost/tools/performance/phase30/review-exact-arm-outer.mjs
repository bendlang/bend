// Outer matcher oversaturation observes whether an exact arm returns a bounce.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baselineFile,candidateFile,outArgument,mode='counterexample']=process.argv.slice(2);assert.ok(baselineFile&&candidateFile&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-exact-arm-outer-scheduling',complete:false,mode,inputs:[import.meta.filename,baselineFile,candidateFile].map(identity),observations:[]};fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-exact-arm-outer.mjs'));
function observe(m,kind){
 const events=[],arrays=[[1,2],[2,1],[0,1],[0,0]],state=m.ctor('Dp',arrays.map(array=>({array}))),saved=m.G['Array.get'];let reads=0;
 m.G['Array.get']={arity:3,env:null,bound:[],code(a){events.push(['Array.get',a[2]]);return saved.code.call(saved.env,a)}};
 try{
  const matcher=m.call(m.G.cell,[0,1]);
  const copied=new Proxy([state,99],{get(t,k,r){if(k==='length'){events.push(['outer.length',++reads]);
   if(reads===4&&kind==='throw')throw Error('outer length sentinel');
   if(reads===4&&kind==='replace')m.G['Array.get']={arity:3,env:null,bound:[],code(){events.push('replacement');throw Error('replacement sentinel')}};
  }return Reflect.get(t,k,r)}});
  let error,value;try{value=m.call(matcher,{slice(){events.push('outer.slice');return copied}})}catch(e){error={name:e.name,message:e.message}}
  return {events,arrays,value,error};
 }finally{m.G['Array.get']=saved}
}
try{
 const baseline=await import(pathToFileURL(path.resolve(baselineFile))),candidate=await import(pathToFileURL(path.resolve(candidateFile)));
 for(const kind of ['order','throw','replace']){const a=observe(baseline,kind),b=observe(candidate,kind),same=JSON.stringify(a)===JSON.stringify(b);report.observations.push({kind,baseline:a,candidate:b,same});if(mode==='repaired')assert.deepEqual(b,a,kind);else assert.equal(same,false,kind+' retained counterexample')}
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,mode,observations:report.observations.length,error:report.error}));
