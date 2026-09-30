// Paired permission-state tests expose private factories only in untimed copies.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [dirArgument,outArgument]=process.argv.slice(2),dir=path.resolve(dirArgument),out=path.resolve(outArgument);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const names=['baseline','slots'],pointFile=path.resolve(import.meta.dirname,'../phase29/fixture-points.json');
const scalarFiles=names.map(n=>path.join(dir,'scalar',n+'.mjs')),
 diagnosticFiles=names.map(n=>path.join(dir,'scalar',n+'-diagnostic.mjs')),
 rowFiles=names.map(n=>path.join(dir,'editdist',n+'-row.mjs'));
const report={kind:'phase30-independent-scalar-entry-state-controls',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,path.join(dir,'derive.json'),pointFile,path.join(dir,'row-points.json'),...scalarFiles,...diagnosticFiles,...rowFiles].map(identity),
 points:[],rows:[],permissions:[],scope:'Same checked actual12 program/runtime except private permission storage. Diagnostic flags must agree as well as values, errors and order. No timing.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const load=files=>Promise.all(files.map(file=>import(pathToFileURL(file))));
const errorValue=e=>({name:e.name,message:e.message});
function observe(m,action){const events=[];try{return {value:action(m,events),events}}catch(e){return {error:errorValue(e),events}}}
const registered=(m,inner,arity=1)=>m.fn(arity,m.exactCode(inner));
try{
 const scalar=await load(scalarFiles),diagnostic=await load(diagnosticFiles),row=await load(rowFiles);
 for(const point of [...JSON.parse(fs.readFileSync(pointFile)).points,{exportName:'point',args:[50000,0,0,0,0,0,0],expected:50000}]){
  const values=scalar.map(m=>m.default[point.exportName](...point.args));report.current={point,values};
  for(const value of values)assert.equal(value,point.expected);report.points.push({...point,values});delete report.current;
 }
 for(const point of JSON.parse(fs.readFileSync(path.join(dir,'row-points.json')))){
  const values=row.map(m=>m.default.bench(...point.args));report.current={point,values};
  for(const value of values)assert.equal(value,point.expected);report.rows.push({...point,values});delete report.current;
 }
 function check(name,action,expected){
  const values=diagnostic.map(m=>observe(m,action));report.current={name,values};assert.deepEqual(values[1],values[0],name);
  if(expected)expected(values[0]);report.permissions.push({name,values});delete report.current;
 }
 check('ordinary-owned-raw-forged',(m,e)=>{const f=registered(m,(a,p)=>{e.push(p);return a[0]});
  return [m.call(f,[7]),m.callOwned(f,[8]),Reflect.apply(f.code,null,[[9],true]),new f.code([10]) instanceof f.code];
 },x=>assert.deepEqual(x.events,[true,true,false,false]));
 check('partial-and-oversaturation',(m,e)=>{const f=registered(m,(a,p)=>{e.push(p);return a[0]+a[1]},2),part=m.call(f,[3]);
  const first=m.call(part,[4]),g=registered(m,(a,p)=>{e.push(p);return m.fn(1,b=>a[0]+b[0])});return [first,m.call(g,[5,6])];
 },x=>assert.deepEqual(x.events,[true,false]));
 check('zero-arity-and-arrow',(m,e)=>{const f=registered(m,(a,p)=>{e.push(['zero',p]);return 7},0),code=m.exactCode((a,p)=>{e.push(['arrow',p]);return a[0]},true);
  return [m.call(f,[]),m.call(m.fn(1,code),[9]),Object.hasOwn(code,'prototype')];
 },x=>assert.deepEqual(x.events,[['zero',true],['arrow',true]]));
 check('same-code-nesting-restores-used',(m,e)=>{let f;f=registered(m,(a,p)=>{e.push([a[0],p]);
  if(p&&a[0]){m.call(f,[a[0]-1]);Reflect.apply(f.code,null,[a,true]);}return a[0]});return m.call(f,[12]);
 },x=>{assert.equal(x.events.filter(r=>r[1]).length,13);assert.equal(x.events.filter(r=>!r[1]).length,12)});
 check('different-code-nesting-restores-used',(m,e)=>{let outer;const inner=registered(m,(a,p)=>{e.push(['inner',p]);return a[0]});
  outer=registered(m,(a,p)=>{e.push(['outer',p]);if(p){m.call(inner,[9]);Reflect.apply(outer.code,null,[a,true])}return a[0]});return m.call(outer,[7]);
 },x=>assert.deepEqual(x.events,[['outer',true],['inner',true],['outer',false]]));
 check('same-vector-slot-exact-then-raw-reentry',(m,e)=>{let active=false,f;const frame=[];
  Object.defineProperty(frame,0,{get(){e.push('slot');if(!active){active=true;m.call(f,{slice:()=>frame});Reflect.apply(f.code,null,[frame,true])}return 7}});
  f=registered(m,(a,p)=>{e.push(p);return a[0]});return m.call(f,{slice:()=>frame});
 },x=>assert.deepEqual(x.events,[true,'slot',true,'slot',false,'slot']));
 check('environment-nested-and-raw-before-install',(m,e)=>{let f;const frame=[7],inner=registered(m,(a,p)=>{e.push(['inner',p]);return a[0]});
  f=registered(m,(a,p)=>{e.push(['outer',p]);return a[0]});Object.defineProperty(f,'env',{get(){e.push('env');m.call(inner,[9]);Reflect.apply(f.code,null,[frame,true]);return null}});
  return m.call(f,{slice:()=>frame});
 },x=>assert.deepEqual(x.events,['env',['inner',true],['outer',false],['outer',true]]));
 check('caught-nested-throw-restores-consumed-outer',(m,e)=>{let outer;const inner=registered(m,(a,p)=>{e.push(['inner',p]);throw Error('nested sentinel')});
  outer=registered(m,(a,p)=>{e.push(['outer',p]);if(p){try{m.call(inner,[9])}catch(error){e.push(errorValue(error))}Reflect.apply(outer.code,null,[a,true])}return a[0]});return m.call(outer,[7]);
 },x=>assert.deepEqual(x.events.map(x=>Array.isArray(x)?x[1]:x.message),[true,true,'nested sentinel',false]));
 check('uncaught-throw-restores-empty-state',(m,e)=>{let fail=true;const f=registered(m,(a,p)=>{e.push(p);if(fail)throw Error('callback sentinel');return a[0]});
  try{m.call(f,[7])}catch(error){e.push(errorValue(error))}fail=false;const raw=Reflect.apply(f.code,null,[[8],true]);return [raw,m.call(f,[9])];
 },x=>assert.deepEqual(x.events,[true,{name:'Error',message:'callback sentinel'},false,true]));
 check('throwing-slot-restores-empty-state',(m,e)=>{const frame=[];Object.defineProperty(frame,0,{get(){e.push('slot');throw Error('slot sentinel')}});
  const f=registered(m,(a,p)=>{e.push(p);return a[0]});try{m.call(f,{slice:()=>frame})}catch(error){e.push(errorValue(error))}return Reflect.apply(f.code,null,[[8],true]);
 },x=>assert.deepEqual(x.events,[true,'slot',{name:'Error',message:'slot sentinel'},false]));
 check('throwing-env-never-installs',(m,e)=>{const f=registered(m,(a,p)=>{e.push(p);return a[0]});
  Object.defineProperty(f,'env',{get(){e.push('env');throw Error('env sentinel')}});try{m.call(f,[7])}catch(error){e.push(errorValue(error))}return Reflect.apply(f.code,null,[[8],true]);
 },x=>assert.deepEqual(x.events,['env',{name:'Error',message:'env sentinel'},false]));
 for(const mode of ['data','getter','throws','noncallable'])check('call-hook-'+mode,(m,e)=>{
  const f=registered(m,(a,p)=>{e.push(['body',p]);return a[0]}),code=f.code;
  const invoke=function(env,args){e.push(['method',this===code,env===null]);return Reflect.apply(code,env,[args])};
  if(mode==='data')code.call=invoke;else Object.defineProperty(code,'call',{get(){e.push('get-call');if(mode==='throws')throw Error('call sentinel');return mode==='noncallable'?null:invoke}});
  Object.defineProperty(f,'env',{get(){e.push('env');return null}});return m.call(f,[7]);
 });
 check('deferred-bounce-enters-after-restoration',(m,e)=>{const next=registered(m,(a,p)=>{e.push(['next',p]);return a[0]});
  const first=registered(m,(a,p)=>{e.push(['first',p]);return m.jump(next,[a[0]+1])});return m.call(first,[7]);
 },x=>assert.deepEqual(x.events,[['first',true],['next',true]]));
 check('deferred-build-raw-call-is-unprivileged',(m,e)=>{let f;f=registered(m,(a,p)=>{e.push(p);if(!p)return a[0];return m.build('ReviewPair',[()=>Reflect.apply(f.code,null,[a,true]),()=>9])});
  return m.call(f,[7]);
 },x=>assert.deepEqual(x.events,[true,false]));
 for(const item of report.inputs)assert.deepEqual(identity(item.file),item);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,points:report.points.length,rows:report.rows.length,permissions:report.permissions.length,error:report.error}));
