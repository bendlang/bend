// Array marker callbacks can invalidate an otherwise closed local region.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const variants=['baseline','private_native','private_row'],files=variants.map(x=>path.join(dir,x+'.mjs'));
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const modules=await Promise.all(files.map(p=>import(pathToFileURL(p)))),report={kind:'phase30-independent-native-array-markers',complete:false,pass:false,
 scope:'New native variant must match baseline under Array marker callbacks; old private-row witness is outside its frozen standard-Array domain. No timing.',
 inputs:[import.meta.filename,path.join(dir,'derive.json'),...files].map(identity),observations:[],historicalWitness:null};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function marker(m,key,mode){
 const old=Object.getOwnPropertyDescriptor(Array.prototype,key),minimum=m.G.umin,events=[];let changed=false,value,error;
 try{
  Object.defineProperty(Array.prototype,key,{configurable:true,get(){
   const tuple=Array.isArray(this)&&this.length===2&&this[0]!==null&&typeof this[0]==='object'&&Object.hasOwn(this[0],'array');
   if(tuple){events.push('tuple.'+key);if(!changed&&mode!=='log'){changed=true;if(mode==='throw')throw Error('tuple marker sentinel');
    m.G.umin={...minimum,code:function(a){events.push('changed minimum');return (Reflect.apply(minimum.code,this,[a])+1)>>>0}};
   }}return false;
  }});
  const st=m.default['row.probe'](2,17);value=st.a.map(h=>Array.from(h.array));
 }catch(e){error={name:e.name,message:e.message}}
 finally{m.G.umin=minimum;if(old)Object.defineProperty(Array.prototype,key,old);else delete Array.prototype[key]}
 return {value,error,events,changed};
}
try{
 for(const key of ['request','bounce','build','code'])for(const mode of ['log','throw','mutate']){
  const expected=marker(modules[0],key,mode),actual=marker(modules[1],key,mode);assert.deepEqual(actual,expected,key+':'+mode);
  if(['bounce','build'].includes(key)&&mode!=='log')assert.equal(expected.changed,true);
  report.observations.push({name:key+':'+mode,expected,actual});
 }
 const baseline=marker(modules[0],'bounce','mutate'),old=marker(modules[2],'bounce','mutate'),candidate=marker(modules[1],'bounce','mutate');
 assert.notDeepEqual(old.value,baseline.value);assert.deepEqual(candidate,baseline);
 report.historicalWitness={baseline,oldPrivateRow:old,candidate,expectedOldMismatch:true,scope:'Old private-row assumed standard Array prototype; new explicit refusal expands only the fallback observation domain.'};
 for(const name of ['Array.new','Array.get','Array.set'])for(const kind of ['code','arity','env','bound','call']){
  const observed=[];
  for(const file of files.slice(0,2)){
   const m=await import(pathToFileURL(file).href+'?before-first='+encodeURIComponent(name+kind)),f=m.G[name],code=f.code,events=[];let value,error;
   if(kind==='code')f.code=function(a){events.push(name);return Reflect.apply(code,this,[a])};
   if(kind==='arity')Object.defineProperty(f,'arity',{get(){events.push('arity');return name==='Array.set'?4:3}});
   if(kind==='env')Object.defineProperty(f,'env',{get(){events.push('env');return null}});
   if(kind==='bound')Object.defineProperty(f,'bound',{get(){events.push('bound');return []}});
   if(kind==='call')Object.defineProperty(code,'call',{get(){events.push('call');return Function.prototype.call}});
   try{const st=m.default['row.probe'](2,17);value=st.a.map(h=>Array.from(h.array))}catch(e){error={name:e.name,message:e.message}}
   observed.push({value,error,events});
  }
  assert.deepEqual(observed[1],observed[0]);assert.ok(observed[0].events.length);report.observations.push({name:'before-first:'+name+':'+kind,observed});
 }
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,historicalWitness:!!report.historicalWitness,error:report.error}));
