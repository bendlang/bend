// Independent complete-state, native schedule, and public-boundary review.
// Usage: node review-local-data.mjs DERIVATION_DIR OUT_DIR [VARIANT ...]
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [dirArg,outArg,...selected]=process.argv.slice(2);
const dir=path.resolve(dirArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const sha=raw=>createHash('sha256').update(raw).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const manifestPath=path.join(dir,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestPath));
const variants=selected.length?selected:Object.keys(manifest.variants).filter(x=>x!=='typescript');
assert.equal(variants[0],'baseline','baseline must be the first variant');
assert.ok(variants.length>=2);
const files=variants.map(name=>path.resolve(manifest.variants[name].file));
for(let i=0;i<files.length;i++)assert.equal(identity(files[i]).sha256,manifest.variants[variants[i]].sha256);
const design=path.resolve('design/phase31/local-data-independent-review.md');
const report={kind:'phase31-independent-local-data-review',complete:false,pass:false,node:process.version,
  scope:'Frozen row fixture only; complete values, exact native operation schedule, public fallback and semantic witnesses. No timing.',
  inputs:[import.meta.filename,design,manifestPath,...files].map(identity),variants,oracle:[],traces:[],aliases:[],boundaries:[],witnesses:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review.mjs'));
fs.copyFileSync(design,path.join(out,'design.md'));
const modules=await Promise.all(files.map(file=>import(pathToFileURL(file))));
const force=(m,x)=>m.call({arity:0,code:()=>x,env:null,bound:[]},[]);
const data=st=>st.a.map(h=>Array.from(h.array));
const hashData=st=>sha(JSON.stringify(data(st)));

// BigInt arithmetic is intentionally independent of emitted JS word operators.
const mask=0xffffffffn;
function prng(word){let x=BigInt(word);x=(x^(x<<13n))&mask;x=(x^(x>>17n))&mask;x=(x^(x<<5n))&mask;return Number(x)}
function oracle(n,seed){
  const stores=[],events=[];
  const alloc=()=>{const id=stores.length;stores.push(Array(128).fill(0));events.push(['new',id,7,0,128]);return id};
  const set=(id,index,value)=>{stores[id][index]=value;events.push(['set',id,index,value])};
  const get=(id,index)=>{const value=stores[id][index];events.push(['get',id,index,value]);return value};
  const a=alloc();let x=seed;
  for(let i=0;i<n;i++){x=prng(x);set(a,i,x%4)}
  const b=alloc();x=Number((BigInt(seed)*340573321n)&mask);
  for(let i=0;i<n;i++){x=prng(x);set(b,i,x%4)}
  const prev=alloc();for(let i=0;i<=n;i++)set(prev,i,i);
  const cur=alloc();
  for(let j=0;j<n;j++){
    const bj=get(b,j),diag=get(prev,j),up=get(prev,j+1),left=get(cur,j);
    const cost=seed%4===bj?0:1;
    set(cur,j+1,Math.min(up+1,left+1,diag+cost));
  }
  return {values:[stores[a],stores[b],stores[cur],stores[prev]],events,roles:[a,b,cur,prev]};
}

function replaceOnce(source,before,after){assert.equal(source.split(before).length,2,before);return source.replace(before,after)}
function instrument(source){
  source=replaceOnce(source,
    "function arrayfill(v,n,mode){if(mode==='^'&&n>31n)bad('an array past the deepest block class 31');const size=mode==='^'?2**Number(n):Number(n);if(size<1||!Number.isSafeInteger(size)||(size&(size-1)))bad('array size must be a power of two');return {array:Array(size).fill(v)}}",
    "function arrayfill(v,n,mode){if(mode==='^'&&n>31n)bad('an array past the deepest block class 31');const size=mode==='^'?2**Number(n):Number(n);if(size<1||!Number.isSafeInteger(size)||(size&(size-1)))bad('array size must be a power of two');const h={array:Array(size).fill(v)};const id=$ReviewHandles.length;$ReviewHandles.push(h);$ReviewEvents.push(['new',id,Number(n),v,size]);return h}");
  source=replaceOnce(source,
    'function arrayget(a,i){const xs=arraydata(a);return [a,xs[Number(i)%xs.length]]}',
    "function arrayget(a,i){const xs=arraydata(a),v=xs[Number(i)%xs.length];$ReviewEvents.push(['get',$ReviewHandles.indexOf(a),Number(i),v]);return [a,v]}");
  source=replaceOnce(source,
    'function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;return a}',
    "function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;$ReviewEvents.push(['set',$ReviewHandles.indexOf(a),Number(i),v]);return a}");
  return 'const $ReviewEvents=[],$ReviewHandles=[];\n'+source+
    '\nexport const reviewTrace={events:$ReviewEvents,handles:$ReviewHandles,reset(){ $ReviewEvents.length=0;$ReviewHandles.length=0; }};\n';
}

function observe(m,action){
  const saved=Object.fromEntries(Object.keys(m.G).map(k=>[k,Object.getOwnPropertyDescriptor(m.G,k)]));
  const events=[];
  try{return {value:action(m,events),events}}
  catch(error){return {error:{name:error.name,message:error.message},events}}
  finally{for(const [name,descriptor]of Object.entries(saved))Object.defineProperty(m.G,name,descriptor)}
}
function check(name,action){
  const observations=modules.map(m=>observe(m,action));report.current={name,observations};
  for(let i=1;i<observations.length;i++)assert.deepEqual(observations[i],observations[0],name+':'+variants[i]);
  report.boundaries.push({name,observations});delete report.current;
}
function replacement(m,events,name){const f=m.G[name],code=f.code;m.G[name]={...f,code:function(a){events.push(name);return Reflect.apply(code,this,[a])}}}

try{
  const sizes=[0,1,2,3,7,15,16,31,32,63,64];
  const seeds=[0,1,2,3,17,0x7fffffff,0x80000000,0xfffffffe,0xffffffff];
  for(const n of sizes)for(const seed of seeds){
    const expected=oracle(n,seed),observed=[];
    for(let i=0;i<modules.length;i++){
      const st=modules[i].default['row.probe'](n,seed);
      assert.deepEqual(data(st),expected.values,variants[i]+':oracle:'+n+':'+seed);
      assert.equal(new Set(st.a).size,4);assert.equal(new Set(st.a.map(h=>h.array)).size,4);
      observed.push(hashData(st));
    }
    report.oracle.push({n,seed,expectedHash:sha(JSON.stringify(expected.values)),observed});
  }
  const traced=[];
  for(let i=0;i<files.length;i++){
    const target=path.join(out,variants[i]+'-trace.mjs');fs.writeFileSync(target,instrument(fs.readFileSync(files[i],'utf8')),{flag:'wx'});
    traced.push(await import(pathToFileURL(target)));
  }
  for(const n of [0,1,2,7,32,64])for(const seed of [17,0xffffffff]){
    const expected=oracle(n,seed),observations=[];
    for(let i=0;i<traced.length;i++){
      const m=traced[i];m.reviewTrace.reset();const st=m.default['row.probe'](n,seed);
      assert.deepEqual(data(st),expected.values);assert.deepEqual(m.reviewTrace.events,expected.events,variants[i]+':native-order');
      assert.deepEqual(st.a.map(h=>m.reviewTrace.handles.indexOf(h)),expected.roles);
      observations.push({variant:variants[i],events:m.reviewTrace.events.slice(),roles:st.a.map(h=>m.reviewTrace.handles.indexOf(h))});
    }
    report.traces.push({n,seed,expected,observations});
  }
  for(let i=0;i<modules.length;i++)for(const n of [0,1,2,7,32,64]){
    const m=modules[i],a=m.default['row.probe'](n,17),before=data(a),b=m.default['row.probe'](n,17);
    for(const x of a.a)for(const y of b.a){assert.notEqual(x,y);assert.notEqual(x.array,y.array)}
    assert.deepEqual(data(a),before);
    const saved=a.a.slice(),zero=m.default.row(0n,0,0,a),next=m.default.row(1n,0,1,zero);
    assert.deepEqual(zero.a.map(x=>saved.indexOf(x)),[0,1,3,2]);
    assert.deepEqual(next.a.map(x=>saved.indexOf(x)),[0,1,2,3]);
    assert.equal(m.call(m.G['Array.set'],[null,saved[2],0,0xffffffff]),saved[2]);
    assert.equal(zero.a[3].array[0],0xffffffff);assert.equal(next.a[2].array[0],0xffffffff);
    report.aliases.push({variant:variants[i],n,fresh:true,zeroRoles:[0,1,3,2],nextRoles:[0,1,2,3],aliasWrite:0xffffffff});
  }
  for(const mode of ['raw','forged','constructed'])for(const name of ['Array.get','Array.set','cell'])check('deferred:'+mode+':'+name,(m,events)=>{
    const code=m.G['row.probe'].code;
    const raw=mode==='constructed'?Reflect.construct(code,[[2,17]]):Reflect.apply(code,null,[[2,17],mode==='forged']);
    assert.equal(raw.bounce,true);events.push('saved');replacement(m,events,name);const st=force(m,raw);
    assert.ok(events.includes(name));return data(st);
  });
  for(const mode of ['raw','constructed'])check('repeated-saved-bounce:'+mode,(m,events)=>{
    const code=m.G['row.probe'].code,raw=mode==='constructed'?Reflect.construct(code,[[2,17]]):Reflect.apply(code,null,[[2,17]]);
    const first=force(m,raw),before=data(first),later=m.default.row(1n,0,3,first),after=data(first);
    replacement(m,events,'Array.set');const second=force(m,raw);
    return {before,after,later:data(later),second:data(second),roles:second.a.map(x=>first.a.indexOf(x))};
  });
  for(const mode of ['same-handle','same-storage','proxy-storage','array-getter'])for(const n of [0n,1n,2n])check('public-alias:'+mode+':'+n,(m,events)=>{
    const backing=[0,1,2,3],store=mode==='proxy-storage'?new Proxy(backing,{get(t,k,r){events.push('get:'+String(k));return Reflect.get(t,k,r)},set(t,k,v,r){events.push('set:'+String(k)+':'+v);return Reflect.set(t,k,v,r)}}):backing;
    const a={array:store},b=mode==='same-handle'?a:mode==='array-getter'?Object.defineProperty({},'array',{get(){events.push('array');return store}}):{array:store};
    const handles=[a,b,a,b],state={$:'Dp',a:handles},first=m.default.row(n,0,3,state),second=m.default.row(1n,1,2,first);
    return {input:data(state),first:data(first),second:data(second),roles:first.a.map(x=>handles.indexOf(x)),laterRoles:second.a.map(x=>handles.indexOf(x))};
  });
  for(const prototype of [Object.prototype,Array.prototype])for(const key of ['request','bounce','build','code'])for(const mode of ['observe','mutate'])check((prototype===Array.prototype?'Array':'Object')+'.prototype.'+key+':'+mode,(m,events)=>{
    const old=Object.getOwnPropertyDescriptor(prototype,key);let changed=false;
    try{
      Object.defineProperty(prototype,key,{configurable:true,get(){
        const tuple=Array.isArray(this)&&this.length===2&&this[0]!==null&&typeof this[0]==='object'&&Object.hasOwn(this[0],'array');
        if(tuple){events.push('tuple:'+key);if(mode==='mutate'&&!changed){changed=true;replacement(m,events,'umin')}}
        return false;
      }});
      return {values:data(m.default['row.probe'](2,17)),changed};
    }finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key]}
  });
  // Deliberately wrong rewrites prove that the demand/role oracle is discriminating.
  for(let i=0;i<modules.length;i++){
    const m=modules[i];
    function deferred(eager){const h={array:[0]},events=[];const write=()=>{events.push('write');return m.call(m.G['Array.set'],[null,h,0,9])};
      const field=eager?write():undefined;const record={build:true,name:'Dp',fields:[()=>h,()=>h,()=>h,()=>eager?field:write()]};
      const before=m.call(m.G['Array.get'],[null,h,0])[1];events.push('observe:'+before);const st=force(m,record);
      return {before,after:h.array[0],roles:st.a.map(x=>x===h),events};}
    const correct=deferred(false),eager=deferred(true);assert.equal(correct.before,0);assert.equal(eager.before,9);assert.notDeepEqual(correct,eager);
    const state={$:'Dp',a:[{array:[0]},{array:[0]},{array:[0]},{array:[0]}]},zero=m.default.row(0n,0,0,state);
    const correctRoles=zero.a.map(x=>state.a.indexOf(x)),wrongRoles=state.a.map(x=>state.a.indexOf(x));
    assert.notDeepEqual(correctRoles,wrongRoles);
    report.witnesses.push({variant:variants[i],eagerWrite:{correct,eager,expectedMismatch:true},omittedZeroSwap:{correctRoles,wrongRoles,expectedMismatch:true}});
  }
  for(const input of report.inputs)assert.deepEqual(identity(input.file),input);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,traces:report.traces.length,aliases:report.aliases.length,boundaries:report.boundaries.length,witnesses:report.witnesses.length,error:report.error}));
