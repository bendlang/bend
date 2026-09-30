// Complete RLE lists plus registration-free public dispatch; no measurements.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const derivation=JSON.parse(fs.readFileSync(path.join(base,'derive.json')));assert.equal(derivation.complete,true);assert.equal(derivation.audit.registrationFree,true);
const report={kind:'phase30-registration-free-rle-controls',complete:false,pass:false,inputs:[ident(import.meta.filename),ident(path.join(base,'derive.json'))],oracles:[],host:[]};
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';const save=()=>fs.writeFileSync(path.join(out,'report.json'),json(report));save();
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));const names=['baseline','direct','flag'],modules=[];
for(const name of names){const file=path.join(base,name+'.mjs'),item=ident(file),expected=name==='baseline'?derivation.baseline:derivation.variants[name].output;assert.deepEqual(item,expected);report.inputs.push(item);
 const target=path.join(out,name+'.mjs');fs.writeFileSync(target,fs.readFileSync(file,'utf8')+'\nexport {fn,apply};\n',{flag:'wx'});modules.push(await import(pathToFileURL(target)));
}
function array(x){const xs=[];for(let i=0;i<512;i++){assert.ok(x&&Array.isArray(x.a));if(x.$==='Nil')return xs;assert.equal(x.$,'Con');assert.equal(x.a.length,2);xs.push(x.a[0]);x=x.a[1]}assert.fail('Unexpected cyclic/large list')}
function runs(xs){const out=[];for(const x of xs){if(out.length&&out.at(-1)[1]===x)out.at(-1)[0]++;else out.push([1,x])}return out}
const digest=xs=>xs.reduce((a,b)=>(Math.imul(a,10)+b)>>>0,0);
const points=[[],[0],[7],[7,7],[7,7,7,2,9,9],[7,2,7],[1,2,3,4],[0xffffffff,0xffffffff,0],[0,0xffffffff,0,0xffffffff],Array(20).fill(5),Array.from({length:24},(_,i)=>i%3)];
try{
 for(const xs of points)for(let i=0;i<modules.length;i++){
  const m=modules[i],expected=runs(xs),list=m.list(xs),tuple=xs=>m.ctor('Tuple',xs);
  const packed=xs.length?m.default.rle(m.list(xs.slice(1)),tuple([xs[0],tuple([1,m.list([])])])):m.list([]);
  const decoded=array(packed).map(x=>{assert.ok(Array.isArray(x));assert.equal(x.length,2);return x});
  const value={runs:decoded,expanded:array(m.default.expand(packed)),count:m.default.llenp(packed),digest:m.default.digest(list),go:m.default.go(list),main:m.default['main.out']()};
  const want={runs:expected,expanded:xs,count:expected.length,digest:digest(xs),go:xs.length?10*Number(expected.length===3)+Number(digest(xs)===777299):0,main:11};
  report.current={variant:names[i],xs,value,want};save();assert.deepEqual(value,want);report.oracles.push(report.current);delete report.current;
 }
 const observe=(m,action)=>{const events=[];try{return {value:action(m,events),events}}catch(e){return {error:{name:e.name,message:e.message},events}}};
 const test=(name,action)=>{const rows=modules.map(m=>observe(m,action));report.current={name,rows};save();for(const row of rows.slice(1))assert.deepEqual(row,rows[0],name);report.host.push(report.current);delete report.current};
 for(const kind of ['ordinary','proxy','object'])for(const method of ['native','getter','throw','noncallable','env-mutates-method'])test(kind+'-'+method,(m,events)=>{
  const body=function(a){events.push(['body',this?.marker,a[0]]);return a[0]+1};
  const code=kind==='proxy'?new Proxy(body,{get(t,k,r){events.push(['get',String(k)]);return Reflect.get(t,k,r)}}):kind==='object'?{}:body;
  const invoke=function(env,a){events.push(['receiver',this===code]);return Reflect.apply(body,env,[a])};
  if(kind==='object'&&method==='native')code.call=invoke;
  if(method!=='native')Object.defineProperty(code,'call',{configurable:true,get(){events.push('call');if(method==='throw')throw Error('call sentinel');if(method==='noncallable')return 4;return invoke}});
  const f=m.fn(1,code);Object.defineProperty(f,'env',{get(){events.push('env');if(method==='env-mutates-method')Object.defineProperty(code,'call',{configurable:true,value:()=>{throw Error('late')}});return {marker:13}}});
  return m.call(f,[8]);
 });
 for(const action of ['ordinary','second-code-throw','code-reentry','arity-reentry'])test('metadata-'+action,(m,e)=>{
  let count=0;const code=a=>{e.push(['body',a[0]]);return a[0]+1},f={bound:[],get code(){e.push('code:'+ ++count);if(count===2&&action==='second-code-throw')throw Error('code sentinel');if(count===2&&action==='code-reentry')e.push(['nested',m.call(m.fn(1,a=>a[0]),[3])]);return code},get arity(){e.push('arity');if(action==='arity-reentry')e.push(['nested',m.call(m.fn(1,a=>a[0]),[4])]);return 1},get env(){e.push('env');return null}};
  return m.call(f,{slice(){e.push('slice');return [8]}});
 });
 for(const size of [0,1,2])test('partial-exact-oversaturated-'+size,(m,e)=>{const f=m.fn(1,a=>{e.push(['first',a[0]]);return m.fn(1,b=>{e.push(['second',b[0]]);return a[0]+b[0]})}),x=m.call(f,[3,5].slice(0,size));return x?.code?{arity:x.arity,bound:x.bound}:x});
 for(const x of report.inputs)assert.deepEqual(ident(x.file),x);report.complete=report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}save();console.log(json({complete:report.complete,pass:report.pass,oracles:report.oracles.length,host:report.host.length,error:report.error}));
