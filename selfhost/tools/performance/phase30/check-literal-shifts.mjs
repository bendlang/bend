// Mathematical oracle and public-ABI comparisons for checked literal shifts.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [configFile,out]=process.argv.slice(2);
assert.ok(configFile&&out&&!fs.existsSync(out),'usage: check-literal-shifts.mjs CONFIG NEW_JSON');
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const config=JSON.parse(fs.readFileSync(configFile)),modules={};
for(const [name,file]of Object.entries(config.modules))modules[name]=await import(pathToFileURL(path.resolve(file)));
const inputs=[identity(import.meta.filename),identity(configFile),...Object.values(config.modules).map(identity)];
const counts=[0,1,8,31,32,33,4294967295],words=[0,1,2,127,128,255,256,65535,2147483647,2147483648,4294967294,4294967295];
let seed=123456789;for(let i=0;i<128;i++){seed=(Math.imul(seed,1664525)+1013904223)>>>0;words.push(seed)}
const oracle=(side,x,n)=>n>=32?0:Number(side==='left'?(BigInt(x)<<BigInt(n))&0xffffffffn:BigInt(x)>>BigInt(n));
const report={kind:'phase30-checked-literal-shift-controls',complete:false,pass:false,inputs,scalarObservations:0,host:[],partials:[]};
const norm=x=>typeof x==='bigint'?String(x)+'n':typeof x==='number'&&!Number.isFinite(x)?String(x):Object.is(x,-0)?'-0':x;
try{
 for(const [variant,m]of Object.entries(modules))for(const side of ['left','right'])for(const x of words){
  for(const n of counts){const expected=oracle(side,x,n);assert.equal(m.default[side+'_'+n](x),expected,`${variant} ${side} ${x} ${n}`);report.scalarObservations++;
   assert.equal(m.default[side+'_dynamic'](x,BigInt(n)),expected);report.scalarObservations++}
  assert.equal(m.default[side+'_annotated'](x),oracle(side,x,8));report.scalarObservations++;
 }
 const choices=[['coercible',e=>({valueOf(){e.push('valueOf');return 4294967295}})],['throwing',e=>({valueOf(){e.push('valueOf');throw Error('operand sentinel')}})],['symbol',()=>Symbol('operand')],['negative',()=>-1],['nan',()=>NaN],['infinity',()=>Infinity],['fraction',()=>1.5],['negative-zero',()=>-0]];
 for(const side of ['left','right'])for(const n of counts)for(const [label,make]of choices){
  const values={};for(const variant of ['baseline','candidate']){
   const m=modules[variant],events=[];try{values[variant]={value:norm(m.call(m.G[side+'_'+n],[make(events)])),events}}
   catch(error){values[variant]={error:{name:error.name,message:error.message},events}}
  }
  assert.deepEqual(values.candidate,values.baseline,`${side} ${n} ${label}`);report.host.push({side,count:n,input:label,observation:values.candidate});
 }
 for(const side of ['left','right'])for(const variant of ['baseline','candidate']){
  const m=modules[variant],partial=m.call(m.G[side+'_dynamic'],[4294967295]),before=[...partial.bound];
  for(const n of counts)assert.equal(m.call(partial,[BigInt(n)]),oracle(side,4294967295,n));
  assert.deepEqual(partial.bound,before);report.partials.push({variant,side,arity:partial.arity,bound:before});
 }
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1}
report.changedInputs=inputs.filter(x=>identity(x.file).sha256!==x.sha256);if(report.changedInputs.length){report.pass=false;process.exitCode=1}
fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,scalarObservations:report.scalarObservations,hostObservations:report.host.length,partials:report.partials.length,error:report.error}));
