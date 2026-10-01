// Checked source cohorts: independent oracles and paired public-boundary controls.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [cohortArg,outArg]=process.argv.slice(2);assert(cohortArg&&outArg,'usage: region-controls.mjs REGION_ACQUISITION NEW_OUT');
const root=path.resolve(cohortArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const normalize=x=>typeof x==='bigint'?String(x)+'n':Object.is(x,-0)?'-0':typeof x==='number'&&!Number.isFinite(x)?String(x):x;
const report={kind:'phase35-checked-region-controls',complete:false,pass:false,inputs:[import.meta.filename,path.join(root,'derive.json')].map(identity),oracle:[],boundaries:[],structure:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const q=Math.fround,mask=0xffffffffn,word=x=>Number(x&mask);
const natSelect=n=>n===0n?11:n===1n?13:word((n-2n)*2n);
const natSecond=(p,n)=>word(BigInt(p)+(n===0n?17n:n===1n?19n:n===2n?23n:(n-3n)*2n));
function accumulated(n,seed){let s=seed;for(let k=BigInt(n)-1n;k>=0n;k--)s=word(BigInt(natSelect(k))+BigInt(natSecond(s,k)));return s;}
function branch(n,sum,flag){for(let k=0n;k<n;k++){sum=word(BigInt(sum)+(flag?5n:3n));flag=!flag;}return word(BigInt(sum)+(flag?7n:0n));}
function floating(n,sum,flag){for(let k=0n;k<n;k++){sum=flag?q(sum*q(q(11)/q(10))):q(sum+q(q(1)/q(10)));flag=sum<q(10);}return flag?q(sum-q(1)):sum;}
const modules={};
async function load(kind){const file=path.join(root,kind,'derive.json'),manifest=JSON.parse(fs.readFileSync(file));assert(manifest.complete);report.inputs.push(identity(file));
 const rows=[];for(const role of ['baseline','candidate','typescript']){const row=manifest.variants[role];assert(row);const file=row.file??row.path;assert.equal(identity(file).sha256,row.sha256);report.inputs.push(identity(file));rows.push({role,file,module:await import(pathToFileURL(file))});}
 modules[kind]=rows;return rows;
}
function point(kind,name,args,expected){const rows=modules[kind],results=rows.map(({role,module:m})=>m.default[name](...args.map(x=>role==='typescript'&&typeof x==='bigint'?Number(x):x)));
 report.current={kind,name,args:args.map(normalize),expected:normalize(expected),results:results.map(normalize)};
 results.forEach(value=>assert.ok(Object.is(value,expected),kind+'/'+name));report.oracle.push(report.current);delete report.current;
}
function snapshot(m){const rows=Object.keys(m.G).filter(n=>m.G[n]?.code).map(name=>{const f=m.G[name],code=f.code;return{name,global:Object.getOwnPropertyDescriptor(m.G,name),f,properties:Object.getOwnPropertyDescriptors(f),code,codeProperties:Object.getOwnPropertyDescriptors(code)}});
 return()=>{for(const r of rows){for(const [value,properties]of[[r.f,r.properties],[r.code,r.codeProperties]]){for(const key of Reflect.ownKeys(value))if(!Object.hasOwn(properties,key))delete value[key];Object.defineProperties(value,properties);}Object.defineProperty(m.G,r.name,r.global);}};
}
function boundary(kind,name,action){const observations=[];for(const {module:m}of modules[kind].slice(0,2)){const restore=snapshot(m),events=[];let value,error;try{value=normalize(action(m,events));}catch(e){error={name:e.name,message:e.message};}finally{restore();}observations.push({value,error,events});}
 report.current={kind,name,observations};assert.deepEqual(observations[1],observations[0],kind+'/'+name);report.boundaries.push(report.current);delete report.current;
}
function hook(object,key,descriptor,action){const old=Object.getOwnPropertyDescriptor(object,key);try{Object.defineProperty(object,key,{configurable:true,...descriptor});return action();}finally{if(old)Object.defineProperty(object,key,old);else delete object[key];}}
try{
 await load('finite-nat');await load('branch-loop');
 for(const n of [0n,1n,2n,3n,8n,9n,65536n,281474976710655n]){
  point('finite-nat','select',[n],natSelect(n));
  for(const seed of [0,17,4294967295])point('finite-nat','select.second',[seed,n],natSecond(seed,n));
 }
 for(const n of [0,1,2,3,8,64,4096])for(const seed of [0,17,4294967295])point('finite-nat','bench',[n,seed],accumulated(n,seed));
 for(const n of [0n,1n,2n,3n,8n,64n,4096n])for(const seed of [0,17,4294967295])for(const flag of [false,true])point('branch-loop','branch',[n,seed,flag],branch(n,seed,flag));
 for(const n of [0n,1n,2n,31n,257n])for(const seed of [0,-0,q(.1),q(11),NaN,Infinity,-Infinity])for(const flag of [false,true])point('branch-loop','float.branch',[n,seed,flag],floating(n,seed,flag));
 for(const n of [0n,1n,2n,32n])for(const value of [q(.1),NaN,Infinity])point('branch-loop','alias.loop',[n,value,17],word(17n+n*2n));
 for(const count of [0,1,2])boundary('branch-loop','public-prefix-'+count,m=>{const args=[9n,17,false],p=m.call(m.G.branch,args.slice(0,count));return JSON.stringify({arity:p.arity,bound:p.bound.length,name:p.code.name,length:p.code.length,constructible:Object.hasOwn(p.code,'prototype'),own:Reflect.ownKeys(p.code).map(String),first:m.call(p,args.slice(count)),second:m.call(p,args.slice(count))});});
 for(const [kind,entry,names,args]of [['finite-nat','bench',['accumulate','select','select.second'],[8,17]],['branch-loop','branch',['branch'],[8n,17,false]],['branch-loop','float.branch',['float.branch'],[8n,q(.1),false]]])for(const name of names)for(const mode of ['wrapper','getter','binding'])boundary(kind,entry+':'+name+':'+mode,(m,e)=>{const f=m.G[name],old=f.code;if(mode==='getter')Object.defineProperty(f,'code',{configurable:true,get(){e.push(name);return old;}});else if(mode==='binding')Object.defineProperty(m.G,name,{configurable:true,get(){e.push(name);return f;}});else f.code=function(a){e.push(name);return Reflect.apply(old,this,[a]);};return m.default[entry](...args);});
 for(const entry of ['float.branch','alias.loop'])for(const mode of ['wrapper','getter','mutation','throw'])boundary('branch-loop',entry+':Math.fround:'+mode,(m,e)=>{const old=Math.fround;let count=0,once=false;const replacement=function(x){count++;if(mode==='throw')throw Error('float sentinel');if(mode==='mutation'&&!once){once=true;const f=m.G[entry],code=f.code;f.code=function(a){e.push('mutated');return Reflect.apply(code,this,[a]);};}return old(x);};let result;try{result=hook(Math,'fround',mode==='getter'?{get(){count++;return old;}}:{value:replacement},()=>entry==='alias.loop'?m.default[entry](8n,.5,17):m.default[entry](8n,.5,false));}finally{e.push(['count',count]);}return result;});
 boundary('branch-loop','alias-global-Math-getter',(m,e)=>{const saved=Math;let count=0;const value=hook(globalThis,'Math',{get(){count++;return saved;}},()=>m.default['alias.loop'](8n,.5,17));e.push(['count',count]);return value;});
 for(const [label,p]of [['Object',Object.prototype],['Number',Number.prototype],['BigInt',BigInt.prototype],['Boolean',Boolean.prototype]])for(const key of ['request','bounce','build','code'])boundary('branch-loop',label+':'+key,(m,e)=>{let count=0;const result=hook(p,key,{get(){count++;return undefined;}},()=>m.default.branch(4n,17,false));e.push(['count',count]);return result;});
 for(const kind of ['iterator','slice','next','return'])boundary('branch-loop','array-'+kind,(m,e)=>{const target=kind==='next'||kind==='return'?Object.getPrototypeOf([][Symbol.iterator]()):Array.prototype,key=kind==='iterator'?Symbol.iterator:kind,old=target[key];let count=0;const result=hook(target,key,{value:function(...args){count++;return old?Reflect.apply(old,this,args):{done:true};}},()=>m.default.branch(4n,17,false));e.push(['count',count]);return result;});
 const finite=fs.readFileSync(modules['finite-nat'][1].file,'utf8'),source=fs.readFileSync(modules['branch-loop'][1].file,'utf8');
 assert(finite.includes('-2n)')&&finite.includes('-3n)'),'finite remainder plans exercised');
 assert(source.includes('/* private final Bool loop */'),'actual compiler branch lowering exercised');
 const begin=source.indexOf('G["alias.loop"]=');assert(begin>=0);const line=source.slice(begin,source.indexOf('\n',begin));
 assert(line.includes('regionHostGuard()')&&line.indexOf('regionHostGuard()')<line.indexOf('Math.fround('),'unused FloatAlias guarded before input rounding');
 report.structure={finiteRemainders:true,finalBoolLoop:true,aliasGuardBeforeRounding:true};
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
 report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
