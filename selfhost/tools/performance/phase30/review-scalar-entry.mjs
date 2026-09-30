// Exact-entry capability: compare actual generated code with preworker output.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);assert.ok(configFile&&outArgument);
const config=JSON.parse(fs.readFileSync(configFile)),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-independent-scalar-exact-entry',complete:false,pass:false,node:process.version,inputs:[configFile,import.meta.filename,config.baseline,config.candidate].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-scalar-entry.mjs'));
function observe(m,kind){
 const events=[],p=m.default.mit(2n),code=p.code,codeAttrs=Object.getOwnPropertyDescriptors(code),rawFrame=[1n,255,384,0,0,0,0];
 const descriptor={...p,bound:[]};let active=false,frame;
 const raw=(a=rawFrame)=>{const x=code.call(null,a);events.push(['raw-bounce',x?.bounce===true]);return x?.bounce===true};
 const force=x=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
 try{
  if(kind==='env-raw-reentry')Object.defineProperty(descriptor,'env',{get(){events.push('env');raw();return null}});
  if(kind==='env-throw')Object.defineProperty(descriptor,'env',{get(){events.push('env');throw Error('env sentinel')}});
  if(kind==='metadata-code-reads')Object.defineProperty(descriptor,'code',{get(){events.push('code');return code}});
  if(kind==='own-call-observes-raw')code.call=function(env,a){events.push('call');const x=Reflect.apply(code,env,[a]);events.push(['call-result-bounce',x?.bounce===true]);return x};
  if(kind==='own-call-getter-order'){
   Object.defineProperty(code,'call',{configurable:true,get(){events.push('call-getter');return function(env,a){return Reflect.apply(code,env,[a])}}});
   Object.defineProperty(descriptor,'env',{get(){events.push('env');return null}});
  }
  if(kind==='env-changes-call-after-read')Object.defineProperty(descriptor,'env',{get(){events.push('env');Object.defineProperty(code,'call',{configurable:true,value:function(env,a){events.push('new-call');return Reflect.apply(code,env,[a])}});return null}});
  if(kind.startsWith('slot-')){
   frame={length:7};for(let i=0;i<7;i++)Object.defineProperty(frame,String(i),{get(){events.push('slot:'+i);
    if(i===0&&!active){active=true;
     if(kind==='slot-raw-same-frame')raw(frame);
     if(kind==='slot-exact-then-raw'){events.push(['nested-exact',m.call({...p,bound:[]},rawFrame)]);raw(frame)}
    }
    if(i===3&&kind==='slot-throw')throw Error('slot sentinel');return rawFrame[i];
   }});
  }else frame=rawFrame;
  let value,error;try{value=m.call(descriptor,{slice(){events.push('slice');return frame}})}catch(e){error={name:e.name,message:e.message}}
  // After every failure/success, raw entry remains unprivileged. This catches
  // leaked active tokens without depending on a private runtime export.
  const after=code.call(null,rawFrame),afterBounce=after?.bounce===true,afterValue=force(after);
  return {events,value,error,afterBounce,afterValue};
 }finally{for(const key of Object.getOwnPropertyNames(code))if(!(key in codeAttrs))delete code[key];Object.defineProperties(code,codeAttrs)}
}
try{
 const baseline=await import(pathToFileURL(path.resolve(config.baseline))),candidate=await import(pathToFileURL(path.resolve(config.candidate)));
 assert.ok(fs.readFileSync(config.candidate,'utf8').includes('exactCode('),'candidate must use actual registered callback entry');
 for(const kind of ['env-raw-reentry','env-throw','metadata-code-reads','own-call-observes-raw','own-call-getter-order','env-changes-call-after-read','slot-raw-same-frame','slot-exact-then-raw','slot-throw']){
  const a=observe(baseline,kind),b=observe(candidate,kind);report.currentComparison={kind,baseline:a,candidate:b};assert.deepEqual(b,a,kind);assert.equal(b.afterBounce,true,kind+' raw after-entry');
  report.observations.push({kind,transcript:a});delete report.currentComparison;
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
