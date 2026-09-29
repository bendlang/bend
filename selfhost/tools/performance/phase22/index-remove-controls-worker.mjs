// Original generated helpers, independent finite filter oracle, explicit demand.
import fs from 'node:fs';
import {pathToFileURL} from 'node:url';
import {isDeepStrictEqual as equal} from 'node:util';
const [probeFile,casesFile,resultFile]=process.argv.slice(2);
const {__phase22Probe:p}=await import(pathToFileURL(probeFile));
const cases=JSON.parse(fs.readFileSync(casesFile));
const nil=()=>({$: 'Nil'}),list=xs=>xs.reduceRight((tail,head)=>({$: 'Con',head,tail}),nil());
const atom=()=>({$: 'KTerm',tag:'Absent',name:'',id:0,quant:0,kids:nil(),removed:nil(),originBegin:0,originEnd:0});
const def=(name,i=0)=>({$: 'KDef',name,kind:i%2?'Other':'Def',arity:i,templates:0,typ:atom(),value:atom(),ctors:nil(),native:false,unsafe:false});
const rows=[];
function observed(f){try{return {kind:'return',value:f()};}catch(e){return {kind:'throw',value:e instanceof Error?{name:e.name,message:e.message}:e};}}
function indices(xs,defs){const map=new Map(defs.map((d,i)=>[d,i])),out=[];for(let n=xs;n.$!=='Nil';n=n.tail){if(!map.has(n.head))throw Error('Definition identity changed');out.push(map.get(n.head));}return out;}
function filter(c,long=false){const names=c.names??Array.from({length:c.count},(_,i)=>i%3?'keep-'+i:'x');const defs=names.map((n,i)=>def(n,i));const wanted=names.flatMap((n,i)=>n===c.query?[]:[i]);const actual=observed(()=>indices(p.remove(list(defs),c.query),defs));const expected={kind:'return',value:wanted};rows.push({name:c.name,category:long?'stack':'filter',pass:equal(actual,expected)||long&&actual.kind==='throw'&&actual.value.name==='RangeError',actual,expected});}
for(const c of cases.filters)filter(c);
for(const count of cases.longLengths)for(const query of ['x','missing'])filter({name:`long-${count}-${query}`,count,query},true);
function demand(name){const events=[];const poison={kind:'owned-poison',test:name};const defs=[def('x',1),def('y',2)];const get=(o,k,label,value,throws=false)=>Object.defineProperty(o,k,{enumerable:true,get(){events.push(label);if(throws)throw value;return value;}});
  for(let i=0;i<2;i++)get(defs[i],'name',`name${i}`,i?'y':'x');
  let end={};get(end,'$','end','Nil');
  const tail={},head={};get(tail,'$','tag1','Con');get(tail,'head','head1',defs[1]);get(tail,'tail','tail1',end);
  get(head,'$','tag0','Con');get(head,'head','head0',defs[0]);get(head,'tail','tail0',tail);
  // New nodes avoid redefining frozen accessor descriptors.
  const override=(o,k,label,value,throws=false)=>{const next={};Object.defineProperties(next,Object.fromEntries(Object.entries(Object.getOwnPropertyDescriptors(o)).filter(([x])=>x!==k)));get(next,k,label,value,throws);return next;};
  let book=head;
  if(name==='first-name-throws'){defs[0]=override(defs[0],'name','name0',poison,true);book=override(head,'head','head0',defs[0]);}
  if(name==='later-name-throws-after-hit'){const d=override(defs[1],'name','name1',poison,true),t=override(tail,'head','head1',d);book=override(head,'tail','tail0',t);}
  if(name==='tail-demand-after-hit'){const bad={};get(bad,'$','tail-poison',poison,true);book=override(head,'tail','tail0',bad);}
  if(name==='tail-projection-precedes-name')book=override(head,'tail','tail0',poison,true);
  if(name==='head-projection-precedes-tail')book=override(head,'head','head0',poison,true);
  if(name==='non-name-payload-unused')for(const d of defs)for(const key of ['kind','arity','templates','typ','value','ctors','native','unsafe'])get(d,key,key,poison,true);
  if(name==='malformed-name-null'||name==='malformed-name-object'){const d=override(defs[0],'name','name0',name.endsWith('null')?null:{not:'a string'});book=override(head,'head','head0',d);defs[0]=d;}
  if(name==='malformed-list-tag')book=override(head,'$','tag0','NotList');
  if(name==='null-list')book=null;
  if(name==='null-definition')book=override(head,'head','head0',null);
  const actual=observed(()=>{const value=p.remove(book,'x');const out=[];for(let n=value;n.$!=='Nil';n=n.tail)out.push(n.head===defs[0]?0:n.head===defs[1]?1:'other');return out;});
  let expectedEvents=null;
  if(['projection-order','non-name-payload-unused','malformed-list-tag'].includes(name))expectedEvents=['tag0','head0','tail0','name0','tag1','head1','tail1','name1','end'];
  if(name==='first-name-throws')expectedEvents=['tag0','head0','tail0','name0'];
  if(name==='later-name-throws-after-hit')expectedEvents=['tag0','head0','tail0','name0','tag1','head1','tail1','name1'];
  if(name==='tail-demand-after-hit')expectedEvents=['tag0','head0','tail0','name0','tail-poison'];
  if(name==='tail-projection-precedes-name')expectedEvents=['tag0','head0','tail0'];
  if(name==='head-projection-precedes-tail')expectedEvents=['tag0','head0'];
  const poisonExpected=['first-name-throws','later-name-throws-after-hit','tail-demand-after-hit','tail-projection-precedes-name','head-projection-precedes-tail'].includes(name);
  rows.push({name,category:'demand',pass:(!expectedEvents||equal(events,expectedEvents))&&(!poisonExpected||equal(actual,{kind:'throw',value:poison})),actual:{result:actual,events},expectedEvents});
}
for(const name of cases.demand)demand(name);
for(const name of cases.callers){const actual=observed(()=>{
  const ds=[def('x',1),def('other',2),def('x',3)];
  if(name==='raw-duplicate-replacement')return p.put(list(ds),def('x',9));
  if(name==='cached-duplicate-replacement')return p.put(p.cached(list(ds),77),def('x',9));
  if(name==='cached-empty-name')return p.put(p.cached(list([def('',1),def('other',2),def('',3)]),77),def('',9));
  if(name==='cached-hash-collision'){if(p.hash('costarring')!==p.hash('liquid'))throw Error('Collision fixture not a collision');const b=p.put(p.cached(list([def('costarring',1),def('liquid',2)]),77),def('costarring',9));return {book:b,a:p.lookup(b,'costarring'),b:p.lookup(b,'liquid')};}
  if(name==='nested-cache-sentinel'){const inner=p.cached(list([def('x',42)]),99).head;const b=p.cached(list([def('x',1),inner,def('x',3),def('other',4)]),77);return p.put(b,def('x',9));}
  if(name==='legacy-final-duplicates')return p.final(list(ds),list([def('old',5),def('x',6)]));
  throw Error('Unknown caller fixture');
});rows.push({name,category:'caller',pass:actual.kind==='return',actual});}
// Repeat actual helper use around errors in one process; expected values remain independent.
for(let round=0;round<cases.historyRounds;round++){
  filter({name:`history-${round}-before`,names:['x','a','x','b'],query:'x'});
  demand('later-name-throws-after-hit');
  filter({name:`history-${round}-after`,names:['x','a','x','b'],query:'missing'});
}
const report={kind:'phase22-index-remove-direct-lane',complete:true,pass:rows.every(r=>r.pass),rows,node:{version:process.version,args:process.execArgv},affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:'))};
fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({pass:report.pass,rows:rows.length,failed:rows.filter(r=>!r.pass).map(r=>r.name)}));process.exitCode=report.pass?0:1;
