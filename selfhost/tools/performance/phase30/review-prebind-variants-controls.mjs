// Independent differential controls for delayed versus fused partial prebinding.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-prebind-registration-variants',complete:false,pass:false,inputs:[import.meta.filename,path.join(base,'derive.json')].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules={};for(const side of ['baseline','candidate','fused']){const source=path.join(base,'core-'+side+'.mjs'),target=path.join(out,side+'.mjs');report.inputs.push(identity(source));fs.writeFileSync(target,fs.readFileSync(source,'utf8')+'\nexport {fn,call,apply,force,matcher1,matcher1p,exactCode};\n',{flag:'wx'});modules[side]=await import(pathToFileURL(target));}
function value(x){if(x?.bounce===true)return {bounce:true,targetArity:x.f.arity,vectorLength:x.args.length};if(x?.code)return {function:true,arity:x.arity,env:x.env,bound:Array.from(x.bound)};return x;}
function outcome(m,reference,action){const events=[];try{return {result:action(m,reference,events),events};}catch(e){return {error:{name:e.name,message:e.message},events};}}
function test(name,action){const results={reference:outcome(modules.baseline,true,action)};for(const side of Object.keys(modules))results[side]=outcome(modules[side],false,action);
 report.current={name,results,genericMatchesCurrent:JSON.stringify(results.candidate)===JSON.stringify(results.baseline)};assert.deepEqual(results.candidate,results.reference,name+' generic/reference');assert.deepEqual(results.fused,results.baseline,name+' fused/current');report.observations.push(report.current);delete report.current;}
function make(m,reference,events,body,count=2,arity=3){const factory=()=>{events.push('make');return body;};return reference?m.matcher1('ReviewRec',()=>m.fn(arity,factory())):m.matcher1p('ReviewRec',count,arity,factory);}
try{
 for(const fieldsKind of ['empty','short','exact-count','exact-arity','oversat','changing-length','copy-empty','copy-exact-arity','copy-oversat','slice-throws','copied-length-throws'])for(const entry of ['exact','raw','raw-forged','partial','outer','outer-throws','call-hook'])test(fieldsKind+'/'+entry,(m,reference,e)=>{
  let fieldLength=0,copiedLength=0,outerLength=0;const size={empty:0,short:1,'exact-count':2,'exact-arity':3,oversat:5,'changing-length':2,'copy-empty':2,'copy-exact-arity':2,'copy-oversat':2,'slice-throws':2,'copied-length-throws':2}[fieldsKind];
  const copiedSize={'copy-empty':0,'copy-exact-arity':3,'copy-oversat':5}[fieldsKind]??size;
  const copied=new Proxy(Array.from({length:copiedSize},(_,i)=>i+7),{get(t,k,r){if(k==='length'){e.push('copied.length:'+ ++copiedLength);if(fieldsKind==='copied-length-throws'&&copiedLength===2)throw Error('copied sentinel');}return Reflect.get(t,k,r);}});
  const fields={get length(){e.push('fields.length:'+ ++fieldLength);return fieldsKind==='changing-length'&&fieldLength>1?5:size;},slice(...a){e.push(['fields.slice',a]);if(fieldsKind==='slice-throws')throw Error('slice sentinel');return copied;}};
  const input={$:'ReviewRec',a:fields},body=(a)=>{e.push(['body',...a]);return m.fn(2,b=>{e.push(['extra',...b]);return a.reduce((s,x)=>s+x,0)+b.reduce((s,x)=>s+x,0)});},f=make(m,reference,e,body);
  if(entry==='call-hook')f.code.call=function(env,a){e.push(['hook',this===f.code]);const raw=Reflect.apply(f.code,env,[a]);e.push(['hook-bounce',raw?.bounce===true]);return raw;};
  let result;if(entry==='raw'||entry==='raw-forged'){const raw=f.code([input],entry==='raw-forged');const before=[...e],shape=value(raw);result=m.force(raw);return {before,raw:shape,result:value(result)};}
  if(entry==='partial'){const p=m.call(f,[]);e.push(['partial',p.arity,p.bound.length]);result=m.call(p,[input]);}
  else if(entry==='outer'||entry==='outer-throws'){const frame=new Proxy([input,13],{get(t,k,r){if(k==='length'){e.push('outer.length:'+ ++outerLength);if(entry==='outer-throws'&&outerLength===4)throw Error('outer sentinel');}return Reflect.get(t,k,r);}});result=m.call(f,{slice(){e.push('outer.slice');return frame;}});}
  else result=m.call(f,[input]);return value(result);
 });
 for(const malformed of [null,undefined,17,{},Symbol('bad')])test('malformed-raw/'+String(malformed),(m,reference,e)=>{const f=make(m,reference,e,a=>a);return value(f.code(malformed));});
 for(const trigger of ['slot','iterator','env','fields-slice'])for(const action of ['raw','exact','throws'])test('reentry/'+trigger+'/'+action,(m,reference,e)=>{
  let entered=false,f,frame;const input={$:'ReviewRec',a:{length:2,slice(){e.push('fields.slice');if(trigger==='fields-slice')reenter();return [7,11];}}};
  function reenter(){if(entered)return;entered=true;e.push('reenter');if(action==='throws')throw Error('reentry sentinel');if(action==='raw'){const raw=f.code(frame);e.push(['reentered-bounce',raw?.bounce===true]);}else{const nested=m.call(make(m,reference,e,a=>a[0]+a[1]+a[2]),[{$:'ReviewRec',a:[2,3]}]);e.push(['nested',m.call(nested,[5])]);}}
  frame=new Proxy([input],{get(t,k,r){if(k==='0'){e.push('slot');if(trigger==='slot')reenter();}if(k===Symbol.iterator){e.push('iterator');if(trigger==='iterator')reenter();}return Reflect.get(t,k,r);}});
  f=make(m,reference,e,a=>a[0]+a[1]+a[2]);if(trigger==='env')Object.defineProperty(f,'env',{get(){e.push('env');reenter();return null;}});
  const p=m.call(f,{slice(){e.push('frame.slice');return frame;}});return m.call(p,[13]);
 });
 test('public-callable-shape',(m,reference,e)=>{const a=make(m,reference,e,x=>x),b=make(m,reference,e,x=>x);let constructible;try{Reflect.construct(Object,[],a.code);constructible=true;}catch{constructible=false;}return {independent:a.code!==b.code,name:a.code.name,length:a.code.length,keys:Reflect.ownKeys(a.code),constructible,prototype:Object.getPrototypeOf(a.code)===Function.prototype,arity:a.arity,env:a.env,bound:a.bound};});
 test('saved-partial-call-hook',(m,reference,e)=>{const f=make(m,reference,e,a=>a[0]+a[1]+a[2]),p=m.call(f,[{$:'ReviewRec',a:[7,11]}]);p.code.call=function(env,a){e.push(['saved-call',this===p.code,...a]);return 101;};return m.call(p,[13]);});
 test('throw-restores-token',(m,reference,e)=>{const bad=make(m,reference,e,a=>a);try{m.call(bad,[{get a(){throw Error('projection sentinel');}}]);}catch(x){e.push(x.message);}const f=make(m,reference,e,a=>a[0]+a[1]+a[2]),p=m.call(f,[{$:'ReviewRec',a:[7,11]}]);return m.call(p,[13]);});
 report.genericCurrentDifferences=report.observations.filter(x=>!x.genericMatchesCurrent).map(x=>x.name);for(const item of report.inputs)assert.deepEqual(identity(item.file),item);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,(_,v)=>typeof v==='symbol'?String(v):v,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,genericCurrentDifferences:report.genericCurrentDifferences,error:report.error}));
