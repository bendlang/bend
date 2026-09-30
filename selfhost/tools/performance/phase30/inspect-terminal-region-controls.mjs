// Independent scalar histogram oracle plus exact public/runtime boundary controls.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [directoryArg,outArg]=process.argv.slice(2),directory=path.resolve(directoryArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const stringify=value=>JSON.stringify(value,(_,x)=>typeof x==='bigint'?{$bigint:String(x)}:x,2)+'\n';
const names=['hchunk','pix','bkt','mit','asr8','sel','sel.go','b2u'];
const variants=['baseline','outer','acyclic','nested'];
const files=variants.map(name=>path.join(directory,name+'.mjs'));
const report={kind:'phase30-terminal-record-region-controls',complete:false,pass:false,node:process.version,
  inputs:[import.meta.filename,path.join(directory,'derive.json'),...files].map(identity),oracle:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules=await Promise.all(files.map(file=>import(pathToFileURL(file))));
const host=(arity,code,bound=[])=>({arity,code,env:null,bound});
const force=(m,value)=>m.call(host(0,()=>value),[]);

// This independent oracle uses numeric signed shift and an ordinary histogram
// array; it shares neither generated expression text nor prototype derivation.
function iterations(index,total){
  const real=(Math.floor(Math.imul(index&4095,768)>>>0)/4096|0)-512>>>0;
  const imag=(Math.floor(Math.imul(index>>>12,768)>>>0)/4096|0)-384>>>0;
  let zr=0,zi=0,escaped=0,count=0;
  for(let step=0n;step<total;step++){
    const rr=(Math.imul(zr,zr)>>8)>>>0,ii=(Math.imul(zi,zi)>>8)>>>0;
    escaped|=((rr+ii)>>>0)>1024?1:0;
    const nextReal=(rr-ii+real)>>>0;
    const nextImag=(((Math.imul(2,Math.imul(zr,zi))>>8)>>>0)+imag)>>>0;
    if(escaped===0){zr=nextReal;zi=nextImag;count=(count+1)>>>0;}
  }
  return count;
}
function histogram(pixels,index,total,initial){
  const result=initial.slice(),denominator=Number(total&0xffffffffn);
  for(let left=pixels;left>0n;left--){
    const point=(index+Number((left-1n)&0xffffffffn))>>>0;
    const numerator=Math.imul(iterations(point,total),8)>>>0;
    const bucket=denominator===0?0:Math.min(7,Math.floor(numerator/denominator)>>>0);
    result[bucket]=(result[bucket]+1)>>>0;
  }
  return {$:'Hl',a:result};
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
function normalize(x,seen=new Set()){
  if(typeof x==='bigint')return {$bigint:String(x)};
  if(typeof x==='function')return '[Function]';
  if(typeof x==='symbol')return String(x);
  if(x===undefined)return '[Undefined]';
  if(Object.is(x,-0))return '-0';
  if(typeof x==='number'&&!Number.isFinite(x))return String(x);
  if(x===null||typeof x!=='object')return x;
  if(seen.has(x))return '[Cycle]';seen.add(x);
  const result=Array.isArray(x)?x.map(v=>normalize(v,seen)):Object.fromEntries(Object.keys(x).sort().map(k=>[k,normalize(x[k],seen)]));
  seen.delete(x);return result;
}
function observe(m,action){
  const restore=snapshot(m),events=[];
  try{return {value:normalize(action(m,events)),events};}
  catch(error){return {error:{name:error.name,message:error.message},events};}
  finally{restore();}
}
function boundary(name,action){
  const observations=modules.map(m=>observe(m,action));
  report.current={name,observations};
  for(let i=1;i<observations.length;i++)assert.deepEqual(observations[i],observations[0],name+' '+variants[i]);
  report.boundaries.push({name,observations});delete report.current;
}
const initial=[0,0,0,0,0,0,0,0];
const ordinary=(m)=>m.default.hchunk(3n,4094,3n,...initial);
function install(m,events,name,kind){
  const original=m.G[name],code=original.code;
  switch(kind){
    case 'binding-getter':Object.defineProperty(m.G,name,{configurable:true,get(){events.push(name+':G');return original}});break;
    case 'proxy':m.G[name]=new Proxy(original,{get(t,k,r){events.push(name+':'+String(k));return Reflect.get(t,k,r)}});break;
    case 'code-getter':Object.defineProperty(original,'code',{configurable:true,get(){events.push(name+':code');return code}});break;
    case 'code-wrapper':original.code=function(a){events.push(name+':invoke');return Reflect.apply(code,this,[a])};break;
    case 'call-hook':code.call=function(env,a){events.push(name+':call');return Reflect.apply(code,env,[a])};break;
    case 'arity-getter':Object.defineProperty(original,'arity',{configurable:true,get(){events.push(name+':arity');return 1}});break;
    case 'env-getter':Object.defineProperty(original,'env',{configurable:true,get(){events.push(name+':env');return null}});break;
    case 'bound-getter':Object.defineProperty(original,'bound',{configurable:true,get(){events.push(name+':bound');return []}});break;
    default:throw Error('unknown mutation');
  }
}
try{
  for(const pixels of [0n,1n,2n,7n,16n])for(const total of [0n,1n,2n,7n,11n])for(const index of [0,4095,4096,4294967293])for(const start of [initial,[4294967295,2,17,4294967294,0,1,7,9]]){
    const expected=histogram(pixels,index,total,start);
    const observations=modules.map(m=>m.default.hchunk(pixels,index,total,...start));
    report.current={pixels,total,index,start,expected,observations};
    for(let i=0;i<observations.length;i++)assert.deepEqual(observations[i],expected,'full histogram '+variants[i]);
    report.oracle.push({pixels,total,index,start,expected});delete report.current;
  }
  for(const hd of [0,2])boundary('original-bench-'+hd,m=>m.default.bench(hd,0));
  assert.equal(modules[0].default.bench(0,0),2747870681);
  for(const name of names)for(const kind of ['binding-getter','proxy','code-getter','code-wrapper','call-hook','arity-getter','env-getter','bound-getter']){
    boundary(name+'-'+kind,(m,events)=>{install(m,events,name,kind);return ordinary(m)});
  }
  for(const name of names)boundary('saved-partial-'+name,(m,events)=>{
    const partial=m.default.hchunk(3n,4094,3n);install(m,events,name,'code-wrapper');return m.call(partial,initial);
  });
  for(const kind of ['raw','forged-permission','exact','slot-reentry','slot-mutation','slot-throw','proxy-frame','env-reentry','call-hook'])boundary(kind,(m,events)=>{
    const partial=m.default.hchunk(3n),code=partial.code,values=[2n,4094,3n,...initial];
    let active=false,frame={length:11};
    for(let i=0;i<11;i++)Object.defineProperty(frame,String(i),{get(){
      events.push('slot:'+i);
      if(i===0&&kind==='slot-reentry'&&!active){active=true;const raw=code.call(null,frame);events.push(['reentry-bounce',raw?.bounce===true]);}
      if(i===2&&kind==='slot-mutation')install(m,events,'b2u','code-wrapper');
      if(i===4&&kind==='slot-throw')throw Error('slot sentinel');
      return values[i];
    }});
    if(kind==='proxy-frame')frame=new Proxy(frame,{get(t,k,r){events.push('frame:'+String(k));return Reflect.get(t,k,r)}});
    if(kind==='call-hook')code.call=function(env,a){events.push('callback.call');return Reflect.apply(code,env,[a])};
    if(kind==='raw'||kind==='forged-permission'){
      const raw=code.call(null,frame,kind==='forged-permission');events.push(['raw-bounce',raw?.bounce===true]);return force(m,raw);
    }
    const descriptor={...partial,bound:[]};
    if(kind==='env-reentry')Object.defineProperty(descriptor,'env',{get(){events.push('env');const raw=code.call(null,values);events.push(['env-raw-bounce',raw?.bounce===true]);return null}});
    return m.call(descriptor,{slice(){events.push('slice');return frame}});
  });
  for(const index of [1,2,3,10])for(const kind of ['boxed','coerce','mutation','throw','proxy','nan','infinity','fraction','overflow'])boundary('input-'+index+'-'+kind,(m,events)=>{
    const args=[3n,4094,3n,...initial],value=index===2?3n:7;
    let x;
    if(kind==='boxed')x=Object(value);
    if(kind==='coerce'||kind==='mutation'||kind==='throw')x={[Symbol.toPrimitive](hint){events.push('coerce:'+hint);if(kind==='throw')throw Error('coercion sentinel');if(kind==='mutation')install(m,events,'b2u','code-wrapper');return value}};
    if(kind==='proxy')x=new Proxy(Object(value),{get(t,k,r){events.push('proxy:'+String(k));return Reflect.get(t,k,r)}});
    if(kind==='nan')x=NaN;if(kind==='infinity')x=Infinity;if(kind==='fraction')x=1.5;if(kind==='overflow')x=4294967296;
    args[index]=x;return m.default.hchunk(...args);
  });
  boundary('oversaturated-copy-length-owner-mutation',(m,events)=>{
    const partial=m.default.hchunk(3n),values=[2n,4094,3n,...initial,99];let reads=0;
    const descriptor={...partial,bound:[]};
    const frame=new Proxy(values,{get(t,k,r){if(k==='length'){events.push(['length',++reads]);if(reads===4)install(m,events,'hchunk','code-wrapper')}return Reflect.get(t,k,r)}});
    return m.call(descriptor,{slice(){events.push('slice');return frame}});
  });
  for(const failAt of [2,3,4,5])boundary('oversaturated-copy-length-throw-'+failAt,(m,events)=>{
    const partial=m.default.hchunk(3n),values=[2n,4094,3n,...initial,99];let reads=0;
    const descriptor={...partial,bound:[]};
    const frame=new Proxy(values,{get(t,k,r){if(k==='length'){events.push(['length',++reads]);if(reads===failAt)throw Error('length sentinel '+failAt)}return Reflect.get(t,k,r)}});
    return m.call(descriptor,{slice(){events.push('slice');return frame}});
  });
  boundary('successor-public-code-shape',(m)=>{
    const code=m.default.hchunk(3n).code;
    return {name:code.name,length:code.length,own:Object.getOwnPropertyDescriptors(code),
      prototypeOwn:Object.getOwnPropertyDescriptors(code.prototype),functionPrototype:Object.getPrototypeOf(code)===Function.prototype};
  });
  boundary('successor-public-code-constructible',(m,events)=>{
    const code=m.default.hchunk(3n).code,raw=Reflect.construct(code,[[2n,4094,3n,...initial]]);
    events.push(['constructed-bounce',raw?.bounce===true]);return force(m,raw);
  });
  boundary('zero-terminal-field-forcing',(m,events)=>{
    const fields=initial.map((_,i)=>Object.defineProperties({value:i},{bounce:{get(){events.push('bounce:'+i);return false}},build:{get(){events.push('build:'+i);return false}}}));
    return m.default.hchunk(0n,0,0n,...fields);
  });
  boundary('zero-terminal-field-throw',(m,events)=>{
    const fields=initial.map((_,i)=>Object.defineProperty({value:i},'bounce',{get(){events.push('bounce:'+i);if(i===3)throw Error('terminal field sentinel');return false}}));
    return m.default.hchunk(0n,0,0n,...fields);
  });
  boundary('zero-raw-build-is-deferred',(m,events)=>{
    const p=m.default.hchunk(0n),fields=initial.map((_,i)=>Object.defineProperty({value:i},'bounce',{get(){events.push('bounce:'+i);return false}}));
    const raw=p.code.call(null,[0,0n,...fields]);events.push(['raw-build',raw?.build===true]);return force(m,raw);
  });
  report.changedInputs=report.inputs.filter(row=>identity(row.file).sha256!==row.sha256);
  assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),stringify(report),{flag:'wx'});
console.log(stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
