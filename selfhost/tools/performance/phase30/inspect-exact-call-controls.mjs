// Paired public traces for actual method-value exact-entry authorization.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const json=value=>JSON.stringify(value,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const sides=['baseline','actual-call'],report={kind:'phase30-exact-call-value-controls',complete:false,pass:false,node:process.version,
  inputs:[identity(import.meta.filename),identity(path.join(base,'derive.json'))],observations:[],points:[],permission:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules=[];
for(const side of sides){
  const file=path.join(base,'helper',side+'.mjs'),target=path.join(out,side+'.mjs');report.inputs.push(identity(file));
  fs.writeFileSync(target,fs.readFileSync(file,'utf8')+'\nexport {exactCode,fn,force,matcher1,matcher1p};\n',{flag:'wx'});
  modules.push(await import(pathToFileURL(target)));
}
const nativeCall=Function.prototype.call;
function normalize(value){
  if(value?.code)return {descriptor:true,arity:value.arity,bound:value.bound,env:value.env};
  return value;
}
function observe(m,run){
  const events=[],old=m.G.b2u.code;
  try{return {value:normalize(run(m,events)),events}}
  catch(error){return {error:{name:error.name,message:error.message},events}}
  finally{m.G.b2u.code=old}
}
function compare(name,run){
  const observations=modules.map(m=>observe(m,run));report.current={name,observations};
  assert.deepEqual(observations[1],observations[0],name);report.observations.push({name,observations});delete report.current;
}
function method(code,kind,events,frame,mutate){
  const invoke=function(env,args){events.push(['invoke-this',this===code,'vector',args===frame]);const value=Reflect.apply(code,env,[args]);events.push(['raw-bounce',value?.bounce===true]);return value};
  Object.defineProperty(invoke,'call',{get(){throw Error('custom invoke.call must not be read')}});
  if(kind==='own-native')Object.defineProperty(code,'call',{value:nativeCall});
  else if(kind==='getter-native'||kind.startsWith('getter-'))Object.defineProperty(code,'call',{get(){
    events.push('get-call');
    if(kind==='getter-throw')throw Error('call getter sentinel');
    if(kind==='getter-raw'){const raw=Reflect.apply(code,null,[frame]);events.push(['getter-raw-bounce',raw?.bounce===true]);}
    if(kind==='getter-mutate')mutate();
    if(kind==='getter-length')frame.length=8;
    return nativeCall;
  }});
  else if(kind==='inherited-native')Object.setPrototypeOf(code,{call:nativeCall});
  else if(kind==='inherited-getter')Object.setPrototypeOf(code,{get call(){events.push('prototype-call');return nativeCall}});
  else if(kind==='prototype-proxy')Object.setPrototypeOf(code,new Proxy({call:nativeCall},{get(t,k,r){events.push(['prototype-get',String(k)]);return Reflect.get(t,k,r)}}));
  else if(kind==='custom')Object.defineProperty(code,'call',{value:invoke});
  else if(kind==='custom-bound')Object.defineProperty(code,'call',{value:invoke.bind({boundReceiver:true})});
  else if(kind==='custom-proxy')Object.defineProperty(code,'call',{value:new Proxy(invoke,{apply(target,receiver,args){events.push(['proxy-apply',receiver===code,args.length,args[1]===frame]);return Reflect.apply(target,receiver,args)}})});
  else if(kind==='custom-revoked'){const pair=Proxy.revocable(invoke,{});pair.revoke();Object.defineProperty(code,'call',{value:pair.proxy});}
  else if(kind==='custom-class')Object.defineProperty(code,'call',{value:class Hook {}});
  else if(kind==='custom-throw')Object.defineProperty(code,'call',{value:function(){events.push('custom-throw');throw TypeError('host TypeError sentinel')}});
  else if(kind.startsWith('noncallable-')){
    const values={null:null,undefined:undefined,number:17,symbol:Symbol('method'),object:{method:true}};
    Object.defineProperty(code,'call',{get(){events.push('get-call');return values[kind.slice(12)]}});
  }else throw Error('unknown method mode '+kind);
}
try{
  const methodKinds=['own-native','getter-native','inherited-native','inherited-getter','prototype-proxy','getter-raw','getter-mutate','getter-length','getter-throw','custom','custom-bound','custom-proxy','custom-revoked','custom-class','custom-throw',...['null','undefined','number','symbol','object'].map(x=>'noncallable-'+x)];
  for(const kind of methodKinds)for(const envKind of ['plain','getter','throw'])compare(kind+'-env-'+envKind,(m,events)=>{
    const partial=m.default.mit(2n),code=partial.code,frame=[1n,255,384,0,0,0,0],descriptor={...partial,bound:[]};
    const mutate=()=>{events.push('mutate');const previous=m.G.b2u.code;m.G.b2u.code=function(a){events.push('b2u');return Reflect.apply(previous,this,[a])}};
    method(code,kind,events,frame,mutate);
    if(envKind!=='plain')Object.defineProperty(descriptor,'env',{get(){events.push('env');if(envKind==='throw')throw Error('env sentinel');return null}});
    return m.call(descriptor,{slice(){events.push('slice');return frame}});
  });
  for(const envKind of ['mutate-method','raw-reentry','nested-reentry'])compare('native-getter-'+envKind,(m,events)=>{
    const partial=m.default.mit(2n),code=partial.code,frame=[1n,255,384,0,0,0,0],descriptor={...partial,bound:[]};
    Object.defineProperty(code,'call',{configurable:true,get(){events.push('get-call');return nativeCall}});
    Object.defineProperty(descriptor,'env',{get(){events.push('env');
      if(envKind==='mutate-method')Object.defineProperty(code,'call',{value:()=>{events.push('wrong-method');return 0}});
      if(envKind==='nested-reentry')events.push(['nested',m.default.mit(1n,255,384,0,0,0,0)]);
      if(envKind!=='mutate-method'){const raw=Reflect.apply(code,null,[frame]);events.push(['env-raw',raw?.bounce===true])}
      return null;
    }});
    return m.call(descriptor,{slice(){events.push('slice');return frame}});
  });
  for(const change of ['raw','exact','throw','mutation'])compare('native-getter-slot-'+change,(m,events)=>{
    const p=m.default.mit(2n),code=p.code,values=[1n,255,384,0,0,0,0],frame={length:7};let once=false;
    Object.defineProperty(code,'call',{get(){events.push('get-call');return nativeCall}});
    for(let i=0;i<7;i++)Object.defineProperty(frame,String(i),{get(){events.push('slot:'+i);
      if(i===0&&!once){once=true;
        if(change==='exact')events.push(['nested',m.default.mit(1n,255,384,0,0,0,0)]);
        if(change==='raw'||change==='exact'){const raw=Reflect.apply(code,null,[frame]);events.push(['slot-raw',raw?.bounce===true]);}
        if(change==='mutation'){const prior=m.G.b2u.code;m.G.b2u.code=function(a){events.push('b2u');return Reflect.apply(prior,this,[a])}}
      }
      if(i===3&&change==='throw')throw Error('slot sentinel');return values[i];
    }});
    return m.call({...p,bound:[]},{slice(){events.push('slice');return frame}});
  });
  for(const methodKind of ['getter-native','inherited-getter','prototype-proxy','custom'])for(const mode of ['exact','outer','outer-throw','slice-throw','copied-throw','raw'])compare('matcher-'+methodKind+'-'+mode,(m,events)=>{
    const fields={get length(){events.push('fields.length');return 2},slice(){events.push('fields.slice');if(mode==='slice-throw')throw Error('fields slice sentinel');
      if(mode==='copied-throw')return new Proxy([7,11],{get(t,k,r){if(k==='length'){events.push('copied.length');throw Error('copied length sentinel')}return Reflect.get(t,k,r)}});
      return [7,11];
    }},value={$:'ReviewRecord',a:fields};
    const code=function(a){events.push('body');return a[0]+a[1]+a[2]},f=m.matcher1p('ReviewRecord',2,3,()=>code),frame=[value];
    method(f.code,methodKind,events,frame,()=>{});
    if(mode==='raw'){const raw=Reflect.apply(f.code,null,[frame]);events.push(['raw-bounce',raw?.bounce===true]);return m.call(m.force(raw),[13])}
    if(mode==='outer'||mode==='outer-throw'){
      let reads=0;const all=new Proxy([value,13],{get(t,k,r){if(k==='length'){events.push(['outer.length',++reads]);if(reads===4&&mode==='outer-throw')throw Error('outer length sentinel')}return Reflect.get(t,k,r)}});
      return m.call(f,{slice(){events.push('outer.slice');return all}});
    }
    return m.call(m.call(f,frame),[13]);
  });
  for(const m of modules){
    const flags=[],code=m.exactCode((a,entered)=>{flags.push(entered);return a[0]});
    code([17],true);const before=flags.splice(0);assert.deepEqual(before,[false]);
    Object.defineProperty(code,'call',{get(){return nativeCall}});m.call(m.fn(1,code),[17]);
    report.permission.push({side:sides[modules.indexOf(m)],raw:before,accessorNativeExact:flags});
  }
  assert.deepEqual(report.permission.map(x=>x.accessorNativeExact),[[false],[true]]);
  const pointsFile=path.resolve(import.meta.dirname,'../phase29/fixture-points.json');report.inputs.push(identity(pointsFile));
  const points=[...JSON.parse(fs.readFileSync(pointsFile)).points,{exportName:'point',args:[50000,0,0,0,0,0,0],expected:50000}];
  for(const point of points){const values=modules.map(m=>m.default[point.exportName](...point.args));report.current={point,values};for(const value of values)assert.equal(value,point.expected);report.points.push({...point,values});delete report.current;}
  for(const side of sides){const file=path.join(base,'editdist',side+'.mjs');report.inputs.push(identity(file));const m=await import(pathToFileURL(file));assert.equal(m.default.bench(2,0),2065873279)}
  for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),json(report),{flag:'wx'});
console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,points:report.points.length,error:report.error}));
