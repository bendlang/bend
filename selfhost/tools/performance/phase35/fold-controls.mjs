// Checked compiled programs, independent integer oracles, and public controls.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const[cohortArg,outArg]=process.argv.slice(2);assert(cohortArg&&outArg,'usage: fold-controls.mjs COHORT NEW_OUT');
const root=path.resolve(cohortArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifestFile=path.join(root,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));assert(manifest.complete);
const roles=['baseline','candidate','typescript'],files=roles.map(r=>manifest.variants[r].file);
for(let i=0;i<files.length;i++)assert.equal(identity(files[i]).sha256,manifest.variants[roles[i]].sha256);
const report={kind:'phase35-compiled-recursive-fold-controls',complete:false,pass:false,inputs:[import.meta.filename,manifestFile,...files].map(identity),oracle:[],boundaries:[],structure:[],admission:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules=[],mask=0xffffffffn,word=n=>Number(n&mask),record=r=>r.a??[r.score,r.weighted];
function oracle(n,seed){const value=(BigInt(seed)+2n*BigInt(n)+7n)&mask;let weight=(BigInt(seed)+BigInt(n)+7n)&mask;
 for(let i=0;i<n;i++)weight=(3n*weight)&mask;
 const shared=word(1n+2n*(BigInt(seed)+2n*BigInt(n)+1n)),duplicate=word((BigInt(seed)+BigInt(n)+7n)*(1n<<BigInt(n)));
 return {benchDeep:Number(value),benchShared:shared,benchOrder:word(24n-value),benchOrderLocal:word(24n-value),benchWeight:Number(weight),
  benchRecord:[Number(value),word(value*65599n)],benchDuplicate:duplicate,benchChanging:Number(value),bench:(Number(value)^shared)>>>0};}
const normalize=x=>typeof x==='bigint'?String(x)+'n':x===undefined?'[undefined]':Object.is(x,-0)?'-0':typeof x==='number'&&!Number.isFinite(x)?String(x):x;
function snapshot(m){const rows=Object.keys(m.G).filter(k=>m.G[k]?.code).map(name=>{const f=m.G[name];return{name,gd:Object.getOwnPropertyDescriptor(m.G,name),f,fd:Object.getOwnPropertyDescriptors(f),code:f.code,cd:Object.getOwnPropertyDescriptors(f.code)};});
 return()=>{for(const r of rows){for(const[v,ds]of[[r.f,r.fd],[r.code,r.cd]]){for(const k of Reflect.ownKeys(v))if(!Object.hasOwn(ds,k))delete v[k];Object.defineProperties(v,ds);}Object.defineProperty(m.G,r.name,r.gd);}};}
function boundary(name,action){const observations=[];for(const m of modules.slice(0,2)){const restore=snapshot(m),events=[];let value,error;
 try{value=normalize(action(m,events));}catch(e){error={name:e.name,message:e.message};}finally{restore();}observations.push({value,error,events});}
 report.current={name,observations};assert.deepEqual(observations[1],observations[0],name);report.boundaries.push(report.current);delete report.current;}
function hook(object,key,descriptor,action){const old=Object.getOwnPropertyDescriptor(object,key);try{Object.defineProperty(object,key,{configurable:true,...descriptor});return action();}finally{if(old)Object.defineProperty(object,key,old);else delete object[key];}}
function change(m,events,name,kind){const f=m.G[name],code=f.code;if(kind==='binding')Object.defineProperty(m.G,name,{configurable:true,get(){events.push('binding:'+name);return f;}});
 else if(kind==='getter')Object.defineProperty(f,'code',{configurable:true,get(){events.push('code:'+name);return code;}});
 else f.code=function(a){events.push('call:'+name);return Reflect.apply(code,this,[a]);};}
const force=(m,x)=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
try{
 for(const file of files)modules.push(await import(pathToFileURL(file)));
 for(const n of [0,1,2,7,12])for(const seed of [0,1,17,4294967294,4294967295]){const expected=oracle(n,seed),results=[];
  for(const m of modules){const row={};for(const name of Object.keys(expected)){const value=m.default[name](n,seed);row[name]=name==='benchRecord'?record(value):value;assert.deepEqual(row[name],expected[name],name);}results.push(row);}
  report.oracle.push({n,seed,expected,results});}
 // The candidate must stay stack safe; historical/upstream native recursion is
 // not required to survive a depth it was never claimed to support.
 for(const n of [4096,50000]){const expected=word(17n+2n*BigInt(n)+7n),actual=modules[1].default.benchDeep(n,17);assert.equal(actual,expected);report.oracle.push({kind:'candidate-deep-local-tree',n,expected,actual});}
 const source=fs.readFileSync(files[1],'utf8'),privateName=n=>'$R_'+Array.from(n,c=>c.codePointAt(0)).join('_');
 for(const name of ['fold.value','fold.size','fold.weight']){const marker='function '+privateName(name)+'(',start=source.indexOf(marker);assert(start>=0,'private fold '+name);
  const body=source.slice(start,source.indexOf('return $value;}',start)+16);assert(body.includes('$fold:for(;;)'));assert(!body.slice(marker.length).includes(privateName(name)+'('),'no native recursive call');report.structure.push({name,iterative:true});}
 for(const name of ['fold.duplicate','fold.changing'])assert(!source.includes('function '+privateName(name)+'('),'unsupported fold refused: '+name);
 const rootLine=name=>{const at=source.indexOf('G['+JSON.stringify(name)+']=');assert(at>=0);return source.slice(at,source.indexOf('\n',at));};
 assert(rootLine('benchRecord').includes('build('),'terminal record keeps deferred construction');
 assert(rootLine('benchDeep').includes('regionHostGuard()'),'fold host guard');
 const countMarker='const $frames=[];let $top=0';assert(source.includes(countMarker));
 const witnessFile=path.join(out,'admission-witness.mjs');fs.writeFileSync(witnessFile,'let phase35FoldEntries=0;\n'+source.replaceAll(countMarker,'++phase35FoldEntries;'+countMarker)+'\nexport const phase35FoldCount=()=>phase35FoldEntries;\n',{flag:'wx'});
 const witness=await import(pathToFileURL(witnessFile));for(const[name,args]of[['benchDeep',[7,17]],['benchShared',[7,17]],['benchWeight',[7,17]],['benchRecord',[7,17]]]){const before=witness.phase35FoldCount();witness.default[name](...args);const entries=witness.phase35FoldCount()-before;assert.equal(entries,1,name+' enters fold');report.admission.push({name,entries});}
 report.witness={...identity(witnessFile),parent:identity(files[1]),timed:false};
 for(const count of [0,1])boundary('public-prefix:'+count,m=>{const args=[7,17],p=m.call(m.G.benchDeep,args.slice(0,count));return{arity:p.arity,bound:p.bound.length,name:p.code.name,length:p.code.length,own:Reflect.ownKeys(p.code).map(String),constructible:Object.hasOwn(p.code,'prototype'),value:m.call(p,args.slice(count))};});
 for(const helper of ['benchDeep','fold.make','fold.value'])for(const mode of ['wrapper','getter','binding'])boundary(helper+':'+mode,(m,e)=>{change(m,e,helper,mode);return m.default.benchDeep(3,17);});
 for(const count of [0,1])for(const helper of ['fold.make','fold.value'])boundary('saved-prefix:'+count+':'+helper,(m,e)=>{const p=m.call(m.G.benchDeep,[3,17].slice(0,count));change(m,e,helper,'wrapper');return m.call(p,[3,17].slice(count));});
 for(const mode of ['raw','forged','new','oversaturated','slot-getter','slot-mutation','slot-throw'])boundary('entry:'+mode,(m,e)=>{const code=m.G.benchDeep.code,frame={length:2,1:17};Object.defineProperty(frame,'0',{get(){e.push('slot:0');if(mode==='slot-mutation')change(m,e,'fold.make','wrapper');if(mode==='slot-throw')throw Error('slot sentinel');return 3;}});
  if(mode==='raw'||mode==='forged')return force(m,Reflect.apply(code,null,[frame,mode==='forged']));if(mode==='new')return force(m,Reflect.construct(code,[frame]));if(mode==='oversaturated')return m.call(m.G.benchDeep,[3,17,99]);return m.call(m.G.benchDeep,{slice(){e.push('slice');return frame;}});});
 for(const mode of ['shared','tag-getter','field-getter','array-getter','throw'])boundary('changed-generator:'+mode,(m,e)=>{const leaf={$:'Tip',a:[17]},tree={$:'Two',a:[leaf,leaf]};
  if(mode==='tag-getter')Object.defineProperty(tree,'$',{get(){e.push('tag');return 'Two';}});if(mode==='array-getter'){const a=tree.a;Object.defineProperty(tree,'a',{get(){e.push('fields');return a;}});}
  if(mode==='field-getter'||mode==='throw')Object.defineProperty(tree.a,'0',{get(){e.push('field:0');if(mode==='throw')throw Error('field sentinel');return leaf;}});
  m.G['fold.make']={arity:2,code(){e.push('foreign-gen');return tree;},env:null,bound:[]};return m.default.benchDeep(3,17);});
 for(const mode of ['wrapper','getter','mutation','throw'])boundary('Math.imul:'+mode,(m,e)=>{const old=Math.imul;let calls=0,once=false,value;const replacement=function(a,b){calls++;if(mode==='throw')throw Error('Math sentinel');if(mode==='mutation'&&!once){once=true;change(m,e,'fold.weight','wrapper');}return old(a,b);};
  try{value=hook(Math,'imul',mode==='getter'?{get(){calls++;return old;}}:{value:replacement},()=>m.default.benchWeight(3,17));}finally{e.push(['calls',calls]);}return value;});
 boundary('terminal-field-demand-after-entry',(m,e)=>{const result=m.G.benchRecord.code([3,17]),old=Math.imul;let calls=0;const value=hook(Math,'imul',{value(a,b){calls++;return old(a,b);}},()=>record(force(m,result)));e.push(['calls',calls]);return value;});
 for(const key of ['push','pop','slice','concat','every'])boundary('Array:'+key,(m,e)=>{const old=Array.prototype[key];let calls=0;const value=hook(Array.prototype,key,{value:function(...a){calls++;return Reflect.apply(old,this,a);}},()=>m.default.benchDeep(3,17));e.push(['calls',calls]);return value;});
 for(const[label,prototype]of[['Array',Array.prototype],['Object',Object.prototype]])for(const index of ['0','7'])for(const mode of ['getter','setter','mutation'])boundary('numeric-prototype:'+label+':'+index+':'+mode,(m,e)=>{
  let gets=0,sets=0,once=false,value;const descriptor={get(){gets++;return undefined;},set(x){sets++;Object.defineProperty(this,index,{value:x,writable:true,enumerable:true,configurable:true});
   if(mode==='mutation'&&!once){once=true;const old=m.G['fold.value'].code;m.G['fold.value'].code=function(a){return Reflect.apply(old,this,[a]);};}}};
  if(mode==='getter')delete descriptor.set;if(mode==='setter')delete descriptor.get;
  try{value=hook(prototype,index,descriptor,()=>m.default.benchDeep(3,17));}finally{e.push(['gets',gets],['sets',sets]);}return value;
 });
 for(const key of ['Math','Number','BigInt','Array'])boundary('global:'+key,(m,e)=>{const old=globalThis[key];let calls=0;const value=hook(globalThis,key,{get(){calls++;return old;}},()=>m.default.benchDeep(3,17));e.push(['calls',calls]);return value;});
 for(const mode of ['object','proxy','mutation','throw'])boundary('coercion:'+mode,(m,e)=>{let once=false;const value={valueOf(){e.push('coerce');if(mode==='throw')throw Error('coercion sentinel');if(mode==='mutation'&&!once){once=true;change(m,e,'fold.value','wrapper');}return 17;}};
  return m.default.benchDeep(3,mode==='proxy'?new Proxy(value,{get(t,k,r){e.push('get:'+String(k));return Reflect.get(t,k,r);}}):value);});
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,admission:report.admission,error:report.error}));
