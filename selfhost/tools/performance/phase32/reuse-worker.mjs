import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [planFile,resultFile]=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile));
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:hash(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const verify=()=>{for(const x of p.inputs){assert.equal(identity(x.file).sha256,x.sha256,x.file)}};
const report={kind:p.kind,complete:false,pass:false,scope:p.scope,plan:identity(planFile),rows:[],node:process.version,args:process.execArgv};
const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n');save();
let phase='',state=null,previous=new Set(),allPrevious=new Set(),previousDef=new Set();
const coarse=new Set(['j_nat_loop_worker','j_tree_worker','j_region_root','j_region_plan','j_u32_worker']);
function begin(){state={merkle:new WeakMap(),objects:0,ids:new WeakMap(),nextId:1,calls:0,queries:{},definitions:[],api:[]}}
function scalar(v){if(v===null)return 'null';if(typeof v==='number')return 'n:'+String(v)+(Object.is(v,-0)?':negativezero':'');if(['string','boolean','undefined'].includes(typeof v))return typeof v+':'+JSON.stringify(v);throw Error('Non-data scalar '+typeof v)}
function digest(value){
 if(value===null||typeof value!=='object')return hash(scalar(value));
 const seen=state.merkle;if(seen.has(value))return seen.get(value);
 const active=new WeakSet(),stack=[[value,false]];
 while(stack.length){const [v,leave]=stack.pop();if(seen.has(v))continue;
  if(leave){const keys=Object.keys(v).sort();const h=createHash('sha256');h.update(Array.isArray(v)?'array:':'object:');for(const k of keys){h.update(JSON.stringify(k));const x=v[k];h.update(x!==null&&typeof x==='object'?seen.get(x):hash(scalar(x)))}seen.set(v,h.digest('hex'));active.delete(v);continue}
  if(active.has(v))throw Error('Cyclic semantic state');if(++state.objects>p.merkleObjectCap)throw Error('Merkle object cap');
  assert.ok(Object.getPrototypeOf(v)===Object.prototype||Array.isArray(v)||Object.getPrototypeOf(v)===null,'Non-data object');active.add(v);stack.push([v,true]);
  for(const k of Object.keys(v).reverse()){const x=v[k];if(x!==null&&typeof x==='object'&&!seen.has(x))stack.push([x,false])}
 }return seen.get(value);
}
function identityKey(args){return args.map(x=>{if(x!==null&&(typeof x==='object'||typeof x==='function')){let id=state.ids.get(x);if(!id){id=state.nextId++;state.ids.set(x,id)}return 'o'+id}return scalar(x)}).join('|')}
globalThis.__p32Hook=(name,args,call)=>{
 if(!state)return call();
 if(name==='check_definition_world'&&phase==='check_program_diagnostic'){
  assert.ok(state.definitions.length<10000);const key=hash(args.map(digest).join('|')),definition=digest(args[1]);
  state.definitions.push({name:args[1].name,depth:args[2],key,definition,previous:previous.has(key),ever:allPrevious.has(key),sameDefinition:previousDef.has(definition)});return call();
 }
 if(phase!=='j_library_selected')return call();
 if(++state.calls>p.queryCap)throw Error('Query cap');
 const q=state.queries[name]??={calls:0,hits:0,keys:new Set(),inclusiveMs:0};q.calls++;const key=identityKey(args);if(q.keys.has(key))q.hits++;else q.keys.add(key);
 if(!coarse.has(name))return call();const t=performance.now();try{return call()}finally{q.inclusiveMs+=performance.now()-t}
};
try{
 verify();const v=p.baseline;process.env.BEND_TYPED_API=v.api.file;process.env.BEND_TYPED_RUNTIME=v.runtime.file;process.env.BEND_BASE=v.base.file;
 const D=await import(pathToFileURL(v.driver.file)),original=await D.loadApi(),instrumented=(await import(pathToFileURL(p.api.file))).default;
 const wrapped=Object.fromEntries(Object.entries(instrumented).map(([name,fn])=>[name,function(...args){const old=phase;phase=name;const t=performance.now();try{return Reflect.apply(fn,instrumented,args)}finally{if(state)state.api.push({name,inclusiveMs:performance.now()-t});phase=old}}]));
 const observe=result=>{const {code,...observation}=result;return {observation,output:typeof code==='string'?{sha256:hash(code),bytes:Buffer.byteLength(code)}:null}};
 for(const c of p.cases){
  let file=c.source?.file;if(c.text){file=c.path;fs.writeFileSync(file,fs.readFileSync(c.text.file));fs.writeFileSync(path.join(path.dirname(file),'dep.bend'),c.dependency)}
  state=null;const expected=observe(await D.inspect(file,{mode:'library',api:original}));begin();
  const actual=observe(await D.inspect(file,{mode:'library',api:wrapped}));assert.deepEqual(actual,expected,'Complete observation/output mismatch '+c.id);
  const definitions=state.definitions;previous=new Set(definitions.map(x=>x.key));previousDef=new Set(definitions.map(x=>x.definition));for(const k of previous)allPrevious.add(k);
  const queries=Object.fromEntries(Object.entries(state.queries).map(([name,{keys,...q}])=>[name,{...q,unique:keys.size}]));
  report.rows.push({id:c.id,source:identity(file),...actual,equal:true,objectsHashed:state.objects,definitions,queries,api:state.api,semantic:{calls:definitions.length,previous:definitions.filter(x=>x.previous).length,ever:definitions.filter(x=>x.ever).length,sameDefinition:definitions.filter(x=>x.sameDefinition).length}});save();
 }
 state=null;verify();report.complete=true;report.pass=true;
}catch(e){report.error=String(e?.stack??e);process.exitCode=1}
report.maxRssKiB=process.resourceUsage().maxRSS;save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
