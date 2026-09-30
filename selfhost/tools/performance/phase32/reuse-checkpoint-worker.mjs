import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [planFile,resultFile,role]=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile));
assert.ok(['baseline','checkpoint'].includes(role));
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:hash(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const verify=()=>{for(const x of p.inputs)assert.equal(identity(x.file).sha256,x.sha256,x.file)};
const report={kind:p.kind,complete:false,pass:false,role,plan:identity(planFile),rows:[],node:process.version,args:process.execArgv,scope:'Saved-code exact-state feasibility only; no production cache or clean speed claim.'};
const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n');
const observe=result=>{const {code,...observation}=result;return {observation,output:typeof code==='string'?{sha256:hash(code),bytes:Buffer.byteLength(code)}:null}};
let previous=null,current=null,cursor=0,pairs=null,stats=null;
const frozen=new WeakSet();
const plain=x=>Object.getPrototypeOf(x)===Object.prototype||Array.isArray(x)||Object.getPrototypeOf(x)===null;
function equal(a,b){
 const stack=[[a,b]];
 while(stack.length){
  const [x,y]=stack.pop();if(Object.is(x,y))continue;
  if(x===null||y===null||typeof x!=='object'||typeof y!=='object')return false;
  assert.ok(plain(x)&&plain(y),'Non-data equality');
  if(Array.isArray(x)!==Array.isArray(y)||Array.isArray(x)&&x.length!==y.length)return false;
  let memo=pairs.get(x);if(memo?.has(y))continue;
  if(!memo){memo=new WeakSet();pairs.set(x,memo)}memo.add(y);
  assert.ok(++stats.comparedObjects<=750000,'Equality cap');
  const keys=Object.keys(x);if(keys.length!==Object.keys(y).length)return false;
  for(const k of keys){if(!Object.hasOwn(y,k))return false;stack.push([x[k],y[k]])}
 }
 return true;
}
function freeze(value){
 const stack=[value];
 while(stack.length){
  const v=stack.pop();if(v===null||typeof v!=='object'){assert.notEqual(typeof v,'function');continue}
  if(frozen.has(v))continue;assert.ok(plain(v),'Non-data checkpoint');
  assert.ok(++stats.frozenObjects<=750000,'Freeze cap');
  Object.freeze(v);frozen.add(v);for(const k of Object.keys(v))stack.push(v[k]);
 }
}
function events(args,invoke,scheduleItem){
 if(!current){
  const started=performance.now(),schedule=[],tails=[];let todo=args[0];
  while(todo.$==='Con'){
   assert.ok(schedule.length<10000,'Event cap');
   const [effective,later]=scheduleItem(todo.head,todo.tail);
   schedule.push({definition:todo.head,effective,later});tails.push(todo);todo=todo.tail;
  }
  assert.equal(todo.$,'Nil');tails.push(todo);
  current={initial:[args[1],args[2]],schedule,checkpoints:[]};let skip=0;
  if(previous&&equal(current.initial,previous.initial)){
   current.initial=previous.initial;
   const limit=Math.min(schedule.length,previous.schedule.length,previous.checkpoints.length-1);
   while(skip<limit&&equal(schedule[skip],previous.schedule[skip])){schedule[skip]=previous.schedule[skip];skip++}
   for(let i=0;i<skip;i++)current.checkpoints[i]=previous.checkpoints[i];
  }
  stats.keyMs+=performance.now()-started;stats.skipped=skip;
  if(skip){const cached=previous.checkpoints[skip];args=[tails[skip],cached.world,cached.seen];cursor=skip}
 }
 stats.calls++;current.checkpoints[cursor++]={world:args[1],seen:args[2]};return invoke(args);
}
save();
try{
 verify();const v=p.baseline;
 process.env.BEND_TYPED_API=v.api.file;process.env.BEND_TYPED_RUNTIME=v.runtime.file;process.env.BEND_BASE=v.base.file;
 const D=await import(pathToFileURL(v.driver.file)),original=await D.loadApi();
 const derived=role==='checkpoint'?await import(pathToFileURL(p.api.file)):null;
 const selected=derived?{...derived.default,check_program_diagnostic:(...args)=>derived.p32Check(args,events)}:original;
 for(const c of p.cases){
  let file=c.source?.file;
  if(c.text){file=c.path;fs.writeFileSync(file,fs.readFileSync(c.text.file));fs.writeFileSync(path.join(path.dirname(file),'dep.bend'),c.dependency)}
  current=null;cursor=0;pairs=new WeakMap();stats={calls:0,skipped:0,comparedObjects:0,frozenObjects:0,keyMs:0,freezeMs:0};
  const started=performance.now();const actual=observe(await D.inspect(file,{mode:'library',api:selected}));
  if(derived&&current){const t=performance.now();freeze(current);stats.freezeMs=performance.now()-t;previous=current}
  report.rows.push({id:c.id,role,source:identity(file),...actual,requestMs:performance.now()-started,stats,retainedEvents:previous?.checkpoints.length??0,maxRssKiB:process.resourceUsage().maxRSS});save();
 }
 verify();report.complete=true;report.pass=true;
}catch(error){report.error=String(error?.stack??error);process.exitCode=1}
report.maxRssKiB=process.resourceUsage().maxRSS;save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
