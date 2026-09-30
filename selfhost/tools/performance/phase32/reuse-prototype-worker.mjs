import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [planFile,resultFile,role='both']=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile));
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:hash(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const verify=()=>{for(const x of p.inputs)assert.equal(identity(x.file).sha256,x.sha256,x.file)};
const report={kind:p.kind,complete:false,pass:false,role,plan:identity(planFile),rows:[],node:process.version,args:process.execArgv,scope:'Saved generated-code prototype; no production edits. Complete normal requests; any clean measurement requires separate grant.'};
const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n');save();
let phase='',mode='',previous=[],current=[],at=0,reuse=true,pairs=null,stats=null,apiTimes=null,compact=null;
const frozen=new WeakSet(),family=new Set(['wnf','j_arm_type','j_primitive_type','j_nat_loop_native','j_nat_shape','j_region_local_type','j_region_local_signature','j_region_capture_eligible']);
const plain=x=>Object.getPrototypeOf(x)===Object.prototype||Array.isArray(x)||Object.getPrototypeOf(x)===null;
function equal(a,b){const stack=[[a,b]];while(stack.length){const [x,y]=stack.pop();if(Object.is(x,y))continue;if(x===null||y===null||typeof x!=='object'||typeof y!=='object')return false;if(!plain(x)||!plain(y))throw Error('Non-data equality');if(Array.isArray(x)!==Array.isArray(y))return false;if(Array.isArray(x)&&x.length!==y.length)return false;let s=pairs.get(x);if(s?.has(y))continue;if(!s){s=new WeakSet();pairs.set(x,s)}s.add(y);if(++stats.comparedObjects>1000000)throw Error('Equality object cap');const k=Object.keys(x),l=Object.keys(y);if(k.length!==l.length)return false;for(const z of k){if(!Object.hasOwn(y,z))return false;stack.push([x[z],y[z]])}}return true}
function freeze(value){const stack=[value];while(stack.length){const v=stack.pop();if(v===null||typeof v!=='object'){assert.notEqual(typeof v,'function');continue}if(frozen.has(v))continue;assert.ok(plain(v),'Non-data cache');if(++stats.frozenObjects>1000000)throw Error('Freeze object cap');Object.freeze(v);frozen.add(v);for(const k of Object.keys(v))stack.push(v[k])}}
function start(){at=0;current=[];reuse=true;pairs=new WeakMap();stats={calls:0,hits:0,logicalSkipped:0,comparedObjects:0,frozenObjects:0,keyMs:0,freezeMs:0,memo:{}};apiTimes=[]}
globalThis.__p32Hook=(name,args,call)=>{
 if(mode==='prefix'&&phase==='check_program_diagnostic'&&name==='check_definition_world'){
  const index=at++;stats.calls++;const old=previous[index];let hit=false;
  if(reuse&&old){const t=performance.now();try{hit=equal(args,old.args)}finally{stats.keyMs+=performance.now()-t}}
  if(hit){stats.hits++;stats.logicalSkipped+=old.end-index;for(let i=index;i<old.end;i++)current[i]=previous[i];at=old.end;return old.result}
  reuse=false;const result=call();const t=performance.now();try{freeze(args);freeze(result)}finally{stats.freezeMs+=performance.now()-t}current[index]={args,result,end:at};return result;
 }
 if(mode==='compact'&&phase==='j_library_selected'&&family.has(name)){
  let table=compact.get(name);if(!table){table=new Map();compact.set(name,table)}const m=stats.memo[name]??={calls:0,hits:0,entries:0};m.calls++;
  for(const arg of args){let next=table.get(arg);if(!next){next=new Map();table.set(arg,next)}table=next}
  if(table.has('result')){m.hits++;return table.get('result')}const result=call();table.set('result',result);m.entries++;return result;
 }
 return call();
};
const observe=result=>{const {code,...observation}=result;return {observation,output:typeof code==='string'?{sha256:hash(code),bytes:Buffer.byteLength(code)}:null}};
try{
 verify();const v=p.baseline;process.env.BEND_TYPED_API=v.api.file;process.env.BEND_TYPED_RUNTIME=v.runtime.file;process.env.BEND_BASE=v.base.file;
 const D=await import(pathToFileURL(v.driver.file)),original=await D.loadApi(),instrumented=(await import(pathToFileURL(p.api.file))).default;
 const wrapped=Object.fromEntries(Object.entries(instrumented).map(([name,fn])=>[name,function(...args){const old=phase;phase=name;if(name==='j_library_selected')compact=new Map();const t=performance.now();try{return Reflect.apply(fn,instrumented,args)}finally{apiTimes.push({name,inclusiveMs:performance.now()-t});if(name==='j_library_selected')compact=null;phase=old}}]));
 const chosen=role==='both'?['prefix','compact']:[role];
 for(const variant of chosen){mode=variant;previous=[];
  for(const c of p.cases){let file=c.source?.file;if(c.text){file=c.path;fs.writeFileSync(file,fs.readFileSync(c.text.file));fs.writeFileSync(path.join(path.dirname(file),'dep.bend'),c.dependency)}
   let expected;if(role==='both'){const saved=mode;mode='';expected=observe(await D.inspect(file,{mode:'library',api:original}));mode=saved}
   start();const t=performance.now(),actual=observe(await D.inspect(file,{mode:'library',api:variant==='baseline'?original:wrapped})),requestMs=performance.now()-t;
   if(expected)assert.deepEqual(actual,expected,'Complete observation/output mismatch '+variant+'/'+c.id);
   if(variant==='prefix'){assert.equal(current.length,at);previous=current}
   report.rows.push({id:c.id,variant,source:identity(file),...actual,equal:expected?true:null,requestMs,stats,api:apiTimes,retainedChecks:previous.length,maxRssKiB:process.resourceUsage().maxRSS});save();
  }
 }
 verify();report.complete=true;report.pass=true;
}catch(e){report.error=String(e?.stack??e);process.exitCode=1}
report.maxRssKiB=process.resourceUsage().maxRSS;save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
