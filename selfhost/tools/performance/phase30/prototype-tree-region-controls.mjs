// Independent scalar-tree values, ordered public boundaries and depth admission.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const variants=['baseline','public_leaf','private_leaf'];
const names=['rcol','rpix','pix','bkt','mit','asr8','sel','sel.go','b2u'];
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const files=variants.map(v=>path.join(dir,v+'.mjs'));
const modules=await Promise.all(files.map(file=>import(pathToFileURL(file))));
const report={kind:'phase30-private-scalar-tree-controls',complete:false,pass:false,node:process.version,
  scope:'Independent small-tree scalar oracle and ordered host boundaries; separate sentinel copies prove depth admission without large computations. No timing.',
  inputs:[import.meta.filename,path.join(dir,'derive.json'),...files].map(identity),oracle:[],boundaries:[],depthAdmission:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const palette=[1,3,7,17,31,63,127,255];
const host=(arity,code,bound=[])=>({arity,code,env:null,bound});
const force=(m,x)=>m.call(host(0,()=>x),[]);
function pixel(index,total){
  const real=((Math.imul(index&4095,768)>>>0)/4096|0)-512>>>0;
  const imag=((Math.imul(index>>>12,768)>>>0)/4096|0)-384>>>0;
  let zr=0,zi=0,escaped=false,count=0;
  for(let step=0n;step<total;step++){
    const rr=(Math.imul(zr,zr)>>8)>>>0,ii=(Math.imul(zi,zi)>>8)>>>0;
    escaped=escaped||((rr+ii)>>>0)>1024;
    if(!escaped){const nextReal=(rr-ii+real)>>>0;zi=(((Math.imul(2,Math.imul(zr,zi))>>8)>>>0)+imag)>>>0;zr=nextReal;count=(count+1)>>>0;}
  }
  return count;
}
function leaf(index,total,colors){
  const it=pixel(index,total),denominator=Number(total&0xffffffffn);
  const bucket=denominator===0?0:Math.min(7,Math.floor((Math.imul(it,8)>>>0)/denominator)>>>0);
  return (Math.imul(colors[bucket],(Math.imul(index,2654435761)+1)>>>0)+it)>>>0;
}
function tree(depth,index,total,colors){
  if(depth===0)return leaf(index,total,colors);
  const left=tree(depth-1,index,total,colors);
  const right=tree(depth-1,(index+2**(depth-1))>>>0,total,colors);
  return (left+right)>>>0;
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
  if(typeof x==='function')return '[Function]';if(typeof x==='symbol')return String(x);
  if(x===undefined)return '[Undefined]';if(Object.is(x,-0))return '-0';
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
  const observations=modules.map(m=>observe(m,action));report.current={name,observations};
  for(let i=1;i<observations.length;i++)assert.deepEqual(observations[i],observations[0],name+' '+variants[i]);
  report.boundaries.push({name,observations});delete report.current;
}
function install(m,events,name,kind){
  const original=m.G[name],code=original.code,arity=original.arity,bound=original.bound;
  switch(kind){
    case 'binding-getter':Object.defineProperty(m.G,name,{configurable:true,get(){events.push(name+':G');return original}});break;
    case 'binding-replaced':m.G[name]={...original,code:function(a){events.push([name+':replacement',normalize(a)]);return Reflect.apply(code,this,[a])}};break;
    case 'proxy':m.G[name]=new Proxy(original,{get(t,k,r){events.push(name+':'+String(k));return Reflect.get(t,k,r)}});break;
    case 'code-getter':Object.defineProperty(original,'code',{configurable:true,get(){events.push(name+':code');return code}});break;
    case 'code-wrapper':original.code=function(a){events.push([name+':invoke',normalize(a)]);return Reflect.apply(code,this,[a])};break;
    case 'call-hook':code.call=function(env,a){events.push(name+':call');return Reflect.apply(code,env,[a])};break;
    case 'arity-getter':Object.defineProperty(original,'arity',{configurable:true,get(){events.push(name+':arity');return arity}});break;
    case 'env-getter':Object.defineProperty(original,'env',{configurable:true,get(){events.push(name+':env');return null}});break;
    case 'bound-getter':Object.defineProperty(original,'bound',{configurable:true,get(){events.push(name+':bound');return bound}});break;
    default:throw Error('unknown mutation');
  }
}
const args=()=>[3n,4095,3n,...palette];
const frameArgs=()=>[2n,4095,3n,...palette];
const ordinary=m=>m.default.rcol(...args());
try{
  for(const depth of [0,1,3,5])for(const index of [0,4095,4294967292])for(const total of [0n,1n,7n])for(const colors of [palette,[4294967295,0,17,4294967294,3,1,7,9]]){
    const expected=tree(depth,index,total,colors);
    for(let i=0;i<modules.length;i++)assert.equal(modules[i].default.rcol(BigInt(depth),index,total,...colors),expected,'tree '+variants[i]);
    report.oracle.push({depth,index,total,colors,expected});
  }
  for(const [size,expected]of [[0,2747870681],[2,887240761]]){
    for(const m of modules)assert.equal(m.default.bench(size,0),expected);
    report.oracle.push({name:'original-bench',size,expected});
  }
  for(const name of names)for(const kind of ['binding-getter','binding-replaced','proxy','code-getter','code-wrapper','call-hook','arity-getter','env-getter','bound-getter'])
    boundary(name+':'+kind,(m,events)=>{install(m,events,name,kind);return ordinary(m)});
  for(const name of names)boundary('saved-partial:'+name,(m,events)=>{
    const partial=m.default.rcol(3n,4095);install(m,events,name,'code-wrapper');return m.call(partial,[3n,...palette]);
  });
  for(const kind of ['raw','forged','exact','reentry','slot-mutation','slot-throw','proxy-frame','env-reentry','call-hook','new'])
    boundary('entry:'+kind,(m,events)=>{
      const partial=m.default.rcol(3n),code=partial.code,values=frameArgs();let active=false;
      let frame={length:11};
      for(let i=0;i<11;i++)Object.defineProperty(frame,String(i),{get(){
        events.push('slot:'+i);
        if(i===0&&kind==='reentry'&&!active){active=true;const raw=Reflect.apply(code,null,[frame]);events.push(['reentry',typeof raw]);}
        if(i===1&&kind==='slot-mutation')install(m,events,'rpix','code-wrapper');
        if(i===2&&kind==='slot-throw')throw Error('slot sentinel');return values[i];
      }});
      if(kind==='proxy-frame')frame=new Proxy(frame,{get(t,k,r){events.push('frame:'+String(k));return Reflect.get(t,k,r)}});
      if(kind==='call-hook')code.call=function(env,a){events.push('callback.call');return Reflect.apply(code,env,[a])};
      if(kind==='new'){const raw=Reflect.construct(code,[frame]);events.push(['new-bounce',raw?.bounce===true],['own-instance',raw instanceof code]);return raw?.bounce?force(m,raw):Object.keys(raw)}
      if(kind==='raw'||kind==='forged'){const raw=Reflect.apply(code,null,[frame,kind==='forged']);events.push(['raw-bounce',raw?.bounce===true]);return force(m,raw)}
      const f={...partial,bound:[]};
      if(kind==='env-reentry')Object.defineProperty(f,'env',{get(){events.push('env');events.push(['env-raw',typeof Reflect.apply(code,null,[values])]);return null}});
      return m.call(f,{slice(){events.push('slice');return frame}});
    });
  for(const kind of ['length-order','length-mutation','length-throw'])boundary('oversaturated:'+kind,(m,events)=>{
    const partial=m.default.rcol(3n),values=[...frameArgs(),99];let reads=0;
    const frame=new Proxy(values,{get(t,k,r){if(k==='length'){
      events.push(['length',++reads]);if(reads===4&&kind==='length-mutation')install(m,events,'rpix','code-wrapper');
      if(reads===4&&kind==='length-throw')throw Error('length sentinel');
    }return Reflect.get(t,k,r)}});
    return m.call({...partial,bound:[]},{slice(){events.push('slice');return frame}});
  });
  for(const kind of ['boxed','coerce','mutation','throw'])boundary('raw-predecessor:'+kind,(m,events)=>{
    const partial=m.default.rcol(3n),values=frameArgs();let p;
    if(kind==='boxed')p=Object(2n);
    else p={[Symbol.toPrimitive](hint){events.push('predecessor:'+hint);if(kind==='mutation')install(m,events,'rpix','code-wrapper');if(kind==='throw')throw Error('predecessor sentinel');return 2n}};
    values[0]=p;return force(m,Reflect.apply(partial.code,null,[values]));
  });
  for(const index of [1,2,10])for(const kind of ['boxed','coerce','mutation','throw','nan','fraction','overflow'])
    boundary('input:'+index+':'+kind,(m,events)=>{
      const values=args(),value=values[index];let x;
      if(kind==='boxed')x=Object(value);
      if(['coerce','mutation','throw'].includes(kind))x={[Symbol.toPrimitive](hint){events.push('coerce:'+hint);if(kind==='throw')throw Error('coercion sentinel');if(kind==='mutation')install(m,events,'rpix','code-wrapper');return value}};
      if(kind==='nan')x=NaN;if(kind==='fraction')x=1.5;if(kind==='overflow')x=4294967296;
      values[index]=x;return m.default.rcol(...values);
    });
  boundary('next-call-mutation',(m,events)=>{const first=ordinary(m);install(m,events,'rpix','code-wrapper');return [first,ordinary(m)]});
  boundary('successor-descriptor',m=>{const f=m.default.rcol(3n);return {arity:f.arity,bound:f.bound,env:f.env,codeLength:f.code.length,codeName:f.code.name,constructible:Object.hasOwn(f.code,'prototype')}});
  // Sentinels replace only bodies after the real guards. Neither path evaluates
  // the huge admitted/refused tree. Pristine snapshots remain intact.
  for(const variant of variants.slice(1)){
    const original=path.join(dir,variant+'.mjs');let text=fs.readFileSync(original,'utf8');
    const fast=/\/\* tree fast entry \*\/return \$tree30Loop\([^;]*\);/g;
    const generic=/\/\* tree generic entry \*\/return [^;]*;/g;
    assert.equal([...text.matchAll(fast)].length,1);assert.equal([...text.matchAll(generic)].length,1);
    text=text.replace(fast,'/* tree fast entry */return "fast";').replace(generic,'/* tree generic entry */return "generic";');
    const file=path.join(out,variant+'-depth-sentinel.mjs');fs.writeFileSync(file,text,{flag:'wx'});
    const m=await import(pathToFileURL(file));
    for(const [depth,expected]of [[1n,'fast'],[32n,'fast'],[33n,'generic']]){
      const result=m.default.rcol(depth,0,0n,...palette);assert.equal(result,expected);
      report.depthAdmission.push({variant,depth,expected,result,module:identity(file)});
    }
    const partial=m.default.rcol(1n),values=[Object(31n),0,0n,...palette];
    assert.equal(m.call({...partial,bound:[]},values),'generic');
    report.depthAdmission.push({variant,name:'coercible-predecessor-refused',result:'generic',module:identity(file)});
  }
  for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,(_,x)=>typeof x==='bigint'?{$bigint:String(x)}:x,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,depthAdmission:report.depthAdmission.length,error:report.error}));
