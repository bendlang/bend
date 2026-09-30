// Same-runtime dispatch traces for inlining only ordinary exact application.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const json=value=>JSON.stringify(value,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const report={kind:'phase30-inline-ordinary-exact-controls',complete:false,pass:false,
 inputs:[ident(import.meta.filename),ident(path.join(base,'derive.json'))],observations:[]};
const sides=['baseline','inline-exact'],modules=[];
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
for(const side of sides){const source=path.join(base,'helper',side+'.mjs'),target=path.join(out,side+'.mjs');
 report.inputs.push(ident(source));fs.writeFileSync(target,fs.readFileSync(source,'utf8')+'\nexport {apply,fn,exactCode};\n',{flag:'wx'});
 modules.push(await import(pathToFileURL(target)));
}
function observe(m,action){const events=[];try{return {value:action(m,events),events}}
 catch(error){return {error:{name:error.name,message:error.message},events}}}
function test(name,action){const rows=modules.map(m=>observe(m,action));report.current={name,rows};
 assert.deepEqual(rows[1],rows[0],name);report.observations.push({name,observations:rows});delete report.current;}
try{
 for(const change of ['none','arity-selects-registered','second-code-selects-registered','code-reentry','arity-reentry'])test('code-read-'+change,(m,e)=>{
  let reads=0,select=false;
  const ordinary=function(a){e.push(['ordinary',this?.marker,a[0]]);return a[0]+1};
  const registered=m.exactCode((a,entered)=>{e.push(['registered',entered,a[0]]);return a[0]+1});
  const f={bound:[],get code(){e.push('code:'+ ++reads);if(reads>2)throw Error('extra code read');
    if(reads===2&&change==='second-code-selects-registered')select=true;
    if(reads===2&&change==='code-reentry')e.push(['nested',m.call(m.fn(1,a=>a[0]+5),[3])]);
    return select?registered:ordinary;},get arity(){e.push('arity');
    if(change==='arity-selects-registered')select=true;
    if(change==='arity-reentry')e.push(['nested',m.call(m.fn(1,a=>a[0]+5),[3])]);return 1;},
    get env(){e.push('env');return {marker:19}}};
  return m.call(f,{slice(){e.push('slice');return [7]}});
 });
 for(const kind of ['ordinary','registered','proxy','object'])for(const method of ['native','getter','throws','noncallable','mutated-by-env'])test(kind+'-'+method,(m,e)=>{
  let code;
  const body=function(a){e.push(['body',this?.marker,a[0]]);return a[0]+1};
  code=kind==='registered'?m.exactCode((a,entered)=>{e.push(['entered',entered]);return body.call({marker:19},a)}):
       kind==='object'?{}:kind==='proxy'?new Proxy(body,{get(t,k,r){e.push(['proxy-get',String(k)]);return Reflect.get(t,k,r)}}):body;
  const invoke=function(env,a){e.push(['method-receiver',this===code]);return Reflect.apply(body,env,[a])};
  if(method==='native'&&kind==='object')code.call=invoke;
  if(method!=='native')Object.defineProperty(code,'call',{configurable:true,get(){e.push('call');
    if(method==='throws')throw TypeError('method sentinel');
    if(method==='noncallable')return 17;
    return invoke;}});
  const f=m.fn(1,code);Object.defineProperty(f,'env',{get(){e.push('env');
    if(method==='mutated-by-env')Object.defineProperty(code,'call',{value:()=>{throw Error('late method selected')},configurable:true});
    return {marker:19};}});
  return m.call(f,[7]);
 });
 for(const kind of ['ordinary','registered'])for(const size of [0,1,2])test('arity-boundary-'+kind+'-'+size,(m,e)=>{
  const f=m.fn(1,kind==='ordinary'?a=>{e.push(['body',a[0]]);return m.fn(1,b=>a[0]+b[0])}:
    m.exactCode((a,entered)=>{e.push(['body',entered,a[0]]);return m.fn(1,b=>a[0]+b[0])}));
  const value=m.call(f,[7,11].slice(0,size));
  return value?.code?{arity:value.arity,bound:value.bound}:value;
 });
 for(const reentry of ['raw-same-vector','nested-exact','throw'])test('registered-'+reentry,(m,e)=>{
  let once=false;const values=[7],frame=new Proxy(values,{get(t,k,r){if(k==='0'){
    e.push('slot');if(!once){once=true;if(reentry==='throw')throw Error('slot sentinel');
      if(reentry==='raw-same-vector')e.push(['raw',code(frame)]);
      else e.push(['nested',m.call(m.fn(1,code),[11])]);}}
    return Reflect.get(t,k,r);}});
  const code=m.exactCode((a,entered)=>{e.push(['entered',entered]);return a[0]+1});
  return m.call(m.fn(1,code),{slice(){return frame}});
 });
 for(const item of report.inputs)assert.deepEqual(ident(item.file),item);
 report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),json(report),{flag:'wx'});
console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
