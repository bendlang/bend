// Independent F32 formula and paired public-boundary observations; no timing.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,outArg,scope='leaf']=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);
assert.ok(['leaf','original'].includes(scope));fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const variants=['baseline','f32-root'],names=['fl','isect.t2','isect.t','isect.go2','isect.go','isect5'];
const files=variants.map(n=>path.join(base,n+'.mjs'));
const modules=await Promise.all(files.map(file=>import(pathToFileURL(file))));
const report={kind:'phase30-f32-ordinary-root-controls',complete:false,pass:false,scope,node:process.version,
  inputs:[import.meta.filename,path.join(base,'derive.json'),...files].map(identity),oracle:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const host=(arity,code,bound=[])=>({arity,code,env:null,bound});
const force=(m,value)=>m.call(host(0,()=>value),[]);
const ordinaryArgs=[0,0,5,1,0,0,0,0,0,1];

// Independent implementation of the Bend formula, with one rounding per F32
// operation. No copied generated expressions, helper calls, or matcher code.
const q=Math.fround,add=(a,b)=>q(a+b),sub=(a,b)=>q(a-b),mul=(a,b)=>q(a*b);
function intersection(cx,cy,cz,r,ox,oy,oz,dx,dy,dz){
  const px=sub(ox,cx),py=sub(oy,cy),pz=sub(oz,cz);
  const b=add(add(mul(px,dx),mul(py,dy)),mul(pz,dz));
  const distance=add(add(mul(px,px),mul(py,py)),mul(pz,pz));
  const disc=sub(mul(b,b),sub(distance,mul(r,r)));
  if(disc<q(0))return q(1000000000);
  const t=sub(sub(q(0),b),q(Math.sqrt(disc)));
  return t<q(q(1)/q(1000))?q(1000000000):t;
}
function normalize(x,seen=new Set()){
  if(typeof x==='bigint')return {$bigint:String(x)};
  if(typeof x==='function')return '[Function]';if(typeof x==='symbol')return String(x);
  if(x===undefined)return '[Undefined]';if(Object.is(x,-0))return '-0';
  if(typeof x==='number'&&!Number.isFinite(x))return String(x);
  if(x===null||typeof x!=='object')return x;
  if(seen.has(x))return '[Cycle]';seen.add(x);
  const result=Array.isArray(x)?x.map(v=>normalize(v,seen)):Object.fromEntries(Object.keys(x).sort().map(k=>[k,normalize(x[k],seen)]));
  seen.delete(x);return result;
}
function snapshot(m){
  const rows=names.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value,code=f.code;
    return {name,gd,f,fd:Object.getOwnPropertyDescriptors(f),fp:Object.getPrototypeOf(f),code,
      cd:Object.getOwnPropertyDescriptors(code),cp:Object.getPrototypeOf(code),bound:f.bound,bd:Object.getOwnPropertyDescriptors(f.bound)};});
  return()=>{for(const r of rows){
    for(const k of Reflect.ownKeys(r.f))if(!Object.hasOwn(r.fd,k))delete r.f[k];
    for(const k of Reflect.ownKeys(r.code))if(!Object.hasOwn(r.cd,k))delete r.code[k];
    for(const k of Reflect.ownKeys(r.bound))if(!Object.hasOwn(r.bd,k))delete r.bound[k];
    Object.defineProperties(r.bound,r.bd);Object.setPrototypeOf(r.code,r.cp);Object.defineProperties(r.code,r.cd);
    Object.setPrototypeOf(r.f,r.fp);Object.defineProperties(r.f,r.fd);Object.defineProperty(m.G,r.name,r.gd);
  }};
}
function observe(m,action){
  const restore=snapshot(m),events=[];
  try{return {value:normalize(action(m,events)),events}}
  catch(error){return {error:{name:error.name,message:error.message},events}}
  finally{restore()}
}
function boundary(name,action){
  const observations=modules.map(m=>observe(m,action));report.current={name,observations};
  assert.deepEqual(observations[1],observations[0],name);
  report.boundaries.push({name,observations});delete report.current;
}
function install(m,events,name,kind){
  const original=m.G[name],code=original.code,arity=original.arity,bound=original.bound;
  switch(kind){
    case 'binding-getter':Object.defineProperty(m.G,name,{configurable:true,get(){events.push(name+':G');return original}});break;
    case 'binding-replaced':m.G[name]={...original,code:function(a){events.push(name+':replacement');return Reflect.apply(code,this,[a])}};break;
    case 'proxy':m.G[name]=new Proxy(original,{get(t,k,r){events.push(name+':'+String(k));return Reflect.get(t,k,r)}});break;
    case 'code-getter':Object.defineProperty(original,'code',{configurable:true,get(){events.push(name+':code');return code}});break;
    case 'code-wrapper':original.code=function(a){events.push(name+':invoke');return Reflect.apply(code,this,[a])};break;
    case 'call-hook':code.call=function(env,a){events.push(name+':call');return Reflect.apply(code,env,[a])};break;
    case 'arity-getter':Object.defineProperty(original,'arity',{configurable:true,get(){events.push(name+':arity');return arity}});break;
    case 'env-getter':Object.defineProperty(original,'env',{configurable:true,get(){events.push(name+':env');return null}});break;
    case 'bound-getter':Object.defineProperty(original,'bound',{configurable:true,get(){events.push(name+':bound');return bound}});break;
    default:throw Error('unknown mutation');
  }
}
const ordinary=m=>m.default.isect5(...ordinaryArgs);
function check(args,label){
  const expected=intersection(...args),values=modules.map(m=>m.default.isect5(...args));
  report.current={label,args:normalize(args),expected:normalize(expected),values:normalize(values)};
  for(const value of values)assert.ok(Object.is(value,expected),label+' Object.is scalar equality');
  report.oracle.push({label,args:normalize(args),expected:normalize(expected)});delete report.current;
}
try{
  if(scope==='original'){
    for(const [i,m]of modules.entries()){
      const value=m.default.bench(80,0);report.current={variant:variants[i],value};
      assert.equal(value,402971);report.oracle.push({variant:variants[i],args:[80,0],expected:402971});delete report.current;
    }
  }else{
    for(const [label,args]of [
      ['hit',ordinaryArgs],['miss',[3,0,5,1,0,0,0,0,0,1]],
      ['tangent',[1,0,5,1,0,0,0,0,0,1]],['behind',[0,0,-5,1,0,0,0,0,0,1]],
      ['inside',[0,0,0,1,0,0,0,0,0,1]],['epsilon',[0,0,q(1.001),1,0,0,0,0,0,1]],
      ['epsilon-below',[0,0,q(1.001-2**-23),1,0,0,0,0,0,1]],
      ['epsilon-above',[0,0,q(1.001+2**-23),1,0,0,0,0,0,1]],
    ])check(args,label);
    const special=[0,-0,2**-149,-(2**-149),2**-126,-(2**-126),q(3.4028234663852886e38),
      -q(3.4028234663852886e38),Infinity,-Infinity,NaN,q(0.001),q(0.001+2**-34),q(0.001-2**-34),q(1+2**-23),q(1-2**-24)];
    for(let at=0;at<10;at++)for(let i=0;i<special.length;i++){
      const args=ordinaryArgs.slice();args[at]=special[i];check(args,'special:'+at+':'+i);
    }
    let seed=0x31415926;
    const next=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return q(((seed%2001)-1000)/37)};
    for(let i=0;i<257;i++){const args=Array.from({length:10},next);args[3]=q(Math.abs(args[3])+0.125);check(args,'deterministic:'+i)}
    for(const name of names)for(const kind of ['binding-getter','binding-replaced','proxy','code-getter','code-wrapper','call-hook','arity-getter','env-getter','bound-getter'])
      boundary(name+':'+kind,(m,events)=>{install(m,events,name,kind);return ordinary(m)});
    for(const name of names)for(const prefix of [1,5,9])boundary('saved:'+prefix+':'+name,(m,events)=>{
      const selected=m.call(m.G.isect5,ordinaryArgs.slice(0,prefix));install(m,events,name,'code-wrapper');
      return m.call(selected,ordinaryArgs.slice(prefix));
    });
    for(const kind of ['raw','forged','exact','reentry','slot-mutation','slot-throw','proxy-frame','env-reentry','call-hook','new'])
      boundary('entry:'+kind,(m,events)=>{
        const descriptor=m.G.isect5,code=descriptor.code;let entered=false;
        let frame={length:10};
        for(let at=0;at<10;at++)Object.defineProperty(frame,String(at),{get(){
          events.push('slot:'+at);
          if(at===0&&kind==='reentry'&&!entered){entered=true;const raw=Reflect.apply(code,null,[frame]);events.push(['raw-bounce',raw?.bounce===true]);}
          if(at===3&&kind==='slot-mutation')install(m,events,'isect.go','code-wrapper');
          if(at===3&&kind==='slot-throw')throw Error('slot sentinel');
          return ordinaryArgs[at];
        }});
        if(kind==='proxy-frame')frame=new Proxy(frame,{get(t,k,r){events.push('frame:'+String(k));return Reflect.get(t,k,r)}});
        if(kind==='env-reentry')Object.defineProperty(descriptor,'env',{configurable:true,get(){
          events.push('env');if(!entered){entered=true;const raw=Reflect.apply(code,null,[frame]);events.push(['env-raw-bounce',raw?.bounce===true]);}return null;
        }});
        if(kind==='call-hook')code.call=function(env,a){events.push('callback.call');return Reflect.apply(code,env,[a])};
        if(kind==='new'){
          const raw=Reflect.construct(code,[frame]);events.push(['new-bounce',raw?.bounce===true],['own-instance',raw instanceof code]);return force(m,raw);
        }
        if(kind==='raw'||kind==='forged'){
          const raw=Reflect.apply(code,null,[frame,kind==='forged']);events.push(['raw-bounce',raw?.bounce===true]);return force(m,raw);
        }
        return m.call(descriptor,{slice(){events.push('slice');return frame}});
      });
    for(const kind of ['plain','mutation','throw'])for(const trigger of [2,3,4])boundary('oversaturated:'+kind+':'+trigger,(m,events)=>{
      let reads=0;const args=[...ordinaryArgs,99];
      const frame=new Proxy(args,{get(t,k,r){
        if(k==='length'){
          events.push('length:'+ ++reads);
          if(reads===trigger&&kind==='mutation')install(m,events,'isect.go','code-wrapper');
          if(reads===trigger&&kind==='throw')throw Error('length sentinel');
        }return Reflect.get(t,k,r);
      }});
      return m.call(m.G.isect5,{slice(){events.push('slice');return frame}});
    });
    for(let at=0;at<10;at++)for(const kind of ['boxed','coerce','mutation','throw','proxy','proxy-boxed','non-f32','symbol','bigint','null','undefined','string','bool'])
      boundary('input:'+at+':'+kind,(m,events)=>{
        const args=ordinaryArgs.slice(),value=args[at];let input;
        if(kind==='boxed')input=new Number(value);
        if(['coerce','mutation','throw'].includes(kind))input={[Symbol.toPrimitive](hint){events.push('coerce:'+hint);if(kind==='throw')throw Error('coercion sentinel');if(kind==='mutation')install(m,events,'isect.go','code-wrapper');return value}};
        if(kind==='proxy')input=new Proxy({[Symbol.toPrimitive](hint){events.push('coerce:'+hint);return value}},{get(t,k,r){events.push('proxy:'+String(k));return Reflect.get(t,k,r)}});
        if(kind==='proxy-boxed')input=new Proxy(new Number(value),{get(t,k,r){events.push('proxy-boxed:'+String(k));return Reflect.get(t,k,r)}});
        if(kind==='non-f32')input=1.1;if(kind==='symbol')input=Symbol('scalar');if(kind==='bigint')input=BigInt(value);
        if(kind==='null')input=null;if(kind==='undefined')input=undefined;if(kind==='string')input=String(value);if(kind==='bool')input=Boolean(value);args[at]=input;
        return m.default.isect5(...args);
      });
    for(const [label,prototype]of [['Object',Object.prototype],['Number',Number.prototype],['Boolean',Boolean.prototype]])
      for(const key of ['request','bounce','build','code'])boundary('prototype:'+label+':'+key,(m,events)=>{
        const old=Object.getOwnPropertyDescriptor(prototype,key);
        Object.defineProperty(prototype,key,{configurable:true,get(){events.push(label+':'+key);return undefined}});
        try{return ordinary(m)}finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key]}
      });
    boundary('prototype-removes-itself',(m,events)=>{
      const p=Boolean.prototype,k='request',old=Object.getOwnPropertyDescriptor(p,k);
      Object.defineProperty(p,k,{configurable:true,get(){events.push('request:remove');delete p[k];return undefined}});
      try{return ordinary(m)}finally{if(old)Object.defineProperty(p,k,old);else delete p[k]}
    });
    boundary('public-shape',m=>{const f=m.G.isect5;return {arity:f.arity,env:f.env,bound:f.bound,
      name:f.code.name,length:f.code.length,own:Reflect.ownKeys(f.code).map(String),constructible:Object.hasOwn(f.code,'prototype'),prototype:Object.getPrototypeOf(f.code)===Function.prototype}});
    for(const zero of [0,-0])boundary('returned-signed-zero:'+Object.is(zero,-0),(m,events)=>{
      m.G['isect.go'].code=function(){events.push('replacement-zero');return zero};
      const value=ordinary(m);assert.ok(Object.is(value,zero));return value;
    });
    boundary('later-binding-mutation',(m,events)=>{const first=ordinary(m);install(m,events,'isect.go','code-wrapper');return [first,ordinary(m)]});
    for(const variant of variants){
      const file=path.join(base,variant+'-leaf.mjs');report.inputs.push(identity(file));
      const leaf=await import(pathToFileURL(file));assert.equal(leaf.default.bench(5,0),4);assert.equal(leaf.default.bench(5,3),1000000000);
    }
  }
  for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,scope,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
