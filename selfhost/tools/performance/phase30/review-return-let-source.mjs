// Checked-source controls for a future general return emitter; no timing.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [configArg,outArg]=process.argv.slice(2),config=JSON.parse(fs.readFileSync(configArg)),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const names=['parallel_lets','nested_lets','escaping_let','rhs_capture','record_closure','callback_order','global_order','nested_factory','let_identity'];
const report={kind:'phase30-independent-checked-return-let-controls',complete:false,pass:false,inputs:[configArg,import.meta.filename].map(identity),oracles:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules={},receipts={};
const host=(arity,code)=>({arity,code,env:null,bound:[]});
const normalize=x=>typeof x==='function'?{name:x.name,length:x.length,prototype:Object.hasOwn(x,'prototype')}:typeof x==='bigint'?String(x):Array.isArray(x)?x.map(normalize):x;
function snapshot(m){const rows=names.map(name=>{const gd=Object.getOwnPropertyDescriptor(m.G,name),f=gd.value;return{name,gd,f,props:Object.getOwnPropertyDescriptors(f),code:f.code,codeProps:Object.getOwnPropertyDescriptors(f.code)}});
 return()=>{for(const r of rows){for(const k of Reflect.ownKeys(r.f))if(!Object.hasOwn(r.props,k))delete r.f[k];for(const k of Reflect.ownKeys(r.code))if(!Object.hasOwn(r.codeProps,k))delete r.code[k];Object.defineProperties(r.code,r.codeProps);Object.defineProperties(r.f,r.props);Object.defineProperty(m.G,r.name,r.gd)}}}
function boundary(name,action){const values={};for(const [side,m]of Object.entries(modules)){const restore=snapshot(m),events=[];try{values[side]={value:normalize(action(m,events)),events}}catch(e){values[side]={error:{name:e.name,message:e.message},events}}finally{restore()}}
 report.current={name,values};assert.deepEqual(values.candidate,values.baseline,name);report.boundaries.push(report.current);delete report.current}
try{
 for(const side of ['baseline','candidate']){
  const file=path.resolve(config[side]),receiptFile=file+'.json',receipt=JSON.parse(fs.readFileSync(receiptFile));
  assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);assert.equal(identity(file).sha256,receipt.output.sha256);
  for(const key of ['attempt','input','api','runtime','base','driver']){assert.equal(identity(receipt[key].file).sha256,receipt[key].sha256);report.inputs.push(identity(receipt[key].file))}
  report.inputs.push(identity(file),identity(receiptFile));receipts[side]=receipt;modules[side]=await import(pathToFileURL(file));
 }
 assert.equal(receipts.baseline.input.sha256,receipts.candidate.input.sha256);
 assert.equal(receipts.baseline.runtime.sha256,receipts.candidate.runtime.sha256);
 for(const a of [0,1,17,255,2147483648,4294967295])for(const b of [0,3,4294967295]){
  const expected={parallel:(Math.imul((b+1)>>>0,100)+((a+2)>>>0))>>>0,nested:(Math.imul(Math.imul((a+4)>>>0,2),100)+((b+7)>>>0))>>>0,
   escape:((a+7)+b)>>>0,rhs:(1+a+b)>>>0,record:(a+11+b)>>>0,nestedFactory:(a+1+b+5)>>>0};
  for(const [side,m]of Object.entries(modules)){
   const escape=m.default.escaping_let(a),rhs=m.default.rhs_capture(a),box=m.default.record_closure(a),factory=m.default.nested_factory(a);
   const values={parallel:m.default.parallel_lets(a,b),nested:m.default.nested_lets(a,b),escape:m.call(escape,[b]),rhs:m.call(rhs,[b]),record:m.call(box.a[0],[b]),nestedFactory:m.call(m.call(factory,[b]),[5])};
   assert.deepEqual(values,expected,side+' '+a+','+b);report.oracles.push({side,a,b,values});
  }
 }
 boundary('saved-factories-after-other-calls',m=>{const a=m.default.escaping_let(1),b=m.default.escaping_let(100),box=m.default.record_closure(7);m.default.parallel_lets(9,8);return [m.call(a,[3]),m.call(b,[3]),m.call(a,[9]),m.call(box.a[0],[2])]});
 boundary('RHS-old-scope-survives',m=>{const a=m.default.rhs_capture(3),b=m.default.rhs_capture(20);return [m.call(a,[4]),m.call(b,[4]),m.call(a,[8])]});
 boundary('nested-saved-partials',m=>{const f=m.default.nested_factory(2),a=m.call(f,[7]),b=m.call(f,[11]);return [m.call(a,[3]),m.call(b,[5]),m.call(a,[9])]});
 for(const mode of ['plain','throw-second','mutate-global','reenter'])boundary('higher-order-'+mode,(m,events)=>{
  let count=0;const callback=host(1,a=>{events.push(['callback',a[0]]);count++;if(mode==='throw-second'&&count===2)throw Error('second RHS sentinel');if(mode==='mutate-global'&&count===1)m.G.let_identity=host(1,x=>(events.push(['changed',x[0]]),(x[0]+7)>>>0));if(mode==='reenter'&&count===1)events.push(['nested',m.default.parallel_lets(2,3)]);return (a[0]+10)>>>0});
  const value=m.default.callback_order(callback,5);return [value,m.default.let_identity(2)];
 });
 for(const mode of ['change','throw'])boundary('live-global-second-RHS-'+mode,(m,events)=>{
  m.G.let_identity=host(1,a=>{events.push(['first',a[0]]);m.G.let_identity=host(1,b=>{events.push(['second',b[0]]);if(mode==='throw')throw Error('second global sentinel');return(b[0]+9)>>>0});return a[0]});
  return m.default.global_order(5);
 });
 boundary('public-callable-metadata',m=>names.map(name=>{const f=m.G[name];return {name,arity:f.arity,env:f.env,bound:f.bound,code:normalize(f.code),keys:Reflect.ownKeys(f.code)}}));
 for(const mode of ['raw','oversaturated','partial','slot-getters'])boundary('callback-boundary-'+mode,(m,events)=>{
  const cb=host(1,a=>(events.push(a[0]),a[0]));const f=m.G.callback_order;
  if(mode==='raw')return m.call(host(0,()=>Reflect.apply(f.code,null,[[cb,3]])),[]);
  if(mode==='oversaturated')return m.call(f,[cb,3,4]);
  if(mode==='partial'){const p=m.call(f,[cb]);return[m.call(p,[3]),p.bound.length]}
  const a={length:2};for(let i=0;i<2;i++)Object.defineProperty(a,i,{get(){events.push('slot:'+i);return [cb,3][i]}});
  return m.call(f,{slice(){events.push('slice');return a}});
 });
 for(const row of report.inputs)assert.deepEqual(identity(row.file),row);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracles:report.oracles.length,boundaries:report.boundaries.length,error:report.error}));
