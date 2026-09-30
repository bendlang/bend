// Public matcher callback identity, arrow shape, raw entry and hooked return.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseFile,nextFile,outArgument]=process.argv.slice(2),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-exact-arm-retry-public-shape',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,baseFile,nextFile].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function observe(m,name,kind,arity,tag){
 const one=m.call(m.G[name],Array(arity).fill(0)),two=m.call(m.G[name],Array(arity).fill(0));
 assert.notEqual(one.code,two.code);const code=one.code,value=tag==='Dp'?{a:[0,0,0,0]}:[0,0],events=[];
 const shape={arity:one.arity,env:one.env,bound:one.bound,name:code.name,length:code.length,own:Reflect.ownKeys(code).map(key=>{
  const d=Object.getOwnPropertyDescriptor(code,key);return {key:String(key),value:d.value,enumerable:d.enumerable,configurable:d.configurable,writable:d.writable}}),
  functionPrototype:Object.getPrototypeOf(code)===Function.prototype,constructible:(()=>{try{Reflect.construct(String,[],code);return true}catch{return false}})()};
 if(kind==='shape'){assert.equal(shape.constructible,false);return {shape,independentCodes:true};}
 if(kind==='raw'||kind==='raw-forged'){
  const result=code.call(null,[value],kind==='raw-forged');assert.equal(result?.bounce,true);return {bounce:true,targetArity:result.f.arity,vector:result.args};
 }
 code.call=function(env,frame){events.push(['call-receiver',this===code]);const result=Reflect.apply(code,env,[frame]);events.push(['raw-bounce',result?.bounce===true]);throw Error('hook sentinel')};
 let error;try{m.call(one,[value])}catch(e){error={name:e.name,message:e.message}}
 assert.deepEqual(events,[['call-receiver',true],['raw-bounce',true]]);assert.equal(Object.hasOwn(two.code,'call'),false);
 return {events,error,otherCodeUnaffected:true};
}
try{
 const old=await import(pathToFileURL(path.resolve(baseFile))),next=await import(pathToFileURL(path.resolve(nextFile)));
 const text=fs.readFileSync(baseFile,'utf8');
 for(const name of ['cell','cell.f1','cell.f2','cell.f3','cell.f4']){
  const line=text.split('\n').find(line=>line.startsWith('G['+JSON.stringify(name)+']=fn('));
  const arity=Number(line.match(/=fn\((\d+),/)[1]),tag=line.match(/matcher1\("(Dp|Tuple)"/)[1];
  for(const kind of ['shape','raw','raw-forged','hook']){const baseline=observe(old,name,kind,arity,tag),candidate=observe(next,name,kind,arity,tag);
   report.current={name,kind,baseline,candidate};assert.deepEqual(candidate,baseline);report.observations.push(report.current);delete report.current;}
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
