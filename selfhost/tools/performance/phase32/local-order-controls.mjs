// Ordering witnesses using the exact emitted fold bridge and scalar-read body.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifest=JSON.parse(fs.readFileSync(path.join(dir,'derive.json'))),detail=manifest.cases.fold.fusion;
const edit=detail.edits.find(e=>e.kind==='private-consumer-clone'),selected=detail.selected[0],read=detail.edits.find(e=>e.kind==='scalar-read-helper').after;
const bridge=edit.after.slice(edit.after.indexOf('function '+selected.bridge+'('));
assert.ok(bridge.startsWith('function '+selected.bridge+'($p0,$p1,$L32_h,$L32_i)'));
const baselineFile=manifest.cases.fold.variants.baseline.file,deriverFile=path.join(dir,'consumed-derive.mjs');
const report={kind:'phase32-local-producer-order-controls',complete:false,pass:false,inputs:[import.meta.filename,path.join(dir,'derive.json'),baselineFile,deriverFile].map(identity),exactBridge:bridge,exactRead:read,cases:[],negative:[],refusals:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function run(kind,scenario){
 const events=[],raw=[7,11],store=new Proxy(raw,{get(t,k,r){if(k==='length'||/^\d+$/.test(String(k)))events.push('read:'+String(k));return Reflect.get(t,k,r)},set(t,k,v,r){events.push('write:'+String(k)+':'+v);return Reflect.set(t,k,v,r)}}),handle={array:store};
 const consume=(a,b,h,v)=>{events.push('consumer');assert.equal(h,handle);if(scenario==='consumer-write'||scenario==='aliases')h.array[0]=99;return scenario==='unused'?a+b:[a,b,v,h===handle]};
 const arraydata=h=>{events.push('arraydata');assert.equal(h,handle);return h.array};
 const invoke=kind==='fused'?new Function('arraydata','consume','const '+selected.clone+'=consume;'+read+bridge+';return '+selected.bridge)(arraydata,consume):
  (a,b,h,i)=>{const xs=arraydata(h),tuple=[h,xs[Number(i)%xs.length]];return consume(a,b,tuple[0],tuple[1])};
 function prefix(which){events.push('prefix:'+which);if(scenario==='prefix-'+which)store[0]=which===0?13:17;return which+3}
 function harg(){events.push('handle');if(scenario==='handle-write')store[0]=23;return handle}
 function iarg(){events.push('index');if(scenario==='index-write')store[0]=29;return scenario==='wrap'?129:0}
 const value=invoke(prefix(0),prefix(1),harg(),iarg());
 if(scenario==='separated-gets'){store[0]=41;const second=invoke(3,4,handle,0);return {value,second,events,store:raw.slice()}}
 return {value,events,store:raw.slice()};
}
try{
 for(const scenario of ['plain','prefix-0','prefix-1','handle-write','index-write','consumer-write','aliases','wrap','unused','separated-gets']){
  const baseline=run('baseline',scenario),fused=run('fused',scenario);assert.deepEqual(fused,baseline,scenario);
  if(scenario==='consumer-write')assert.equal(fused.value[2],7);
  if(scenario==='unused')assert.ok(fused.events.includes('read:0'),'unused scalar still read');
  assert.equal(fused.events.filter(x=>x==='handle').length,1);assert.equal(fused.events.filter(x=>x==='index').length,1);
  report.cases.push({scenario,baseline,fused});
 }
 const observed=run('fused','consumer-write').value[2],h={array:[7,11]},deferred=()=>h.array[0];h.array[0]=99;const wrong=deferred();assert.equal(observed,7);assert.equal(wrong,99);assert.notEqual(observed,wrong);report.negative.push({kind:'defer-read-until-consumer-use',captured:observed,incorrect:wrong});
 // Call the exact preserved deriver functions on refused shapes, without
 // executing its top-level filesystem driver or modifying a saved module.
 const parserModule={exports:{}};new Function('exports','module',process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'])(parserModule.exports,parserModule);const acorn=parserModule.exports;
 const deriver=fs.readFileSync(deriverFile,'utf8'),ast=acorn.parse(deriver,{ecmaVersion:'latest',sourceType:'module'});
 const functions=ast.body.filter(n=>n.type==='FunctionDeclaration').map(n=>deriver.slice(n.start,n.end)).join('\n');
 const actual=new Function('acorn','assert',functions+';return {fusion,inventory};')(acorn,assert),base=fs.readFileSync(baselineFile,'utf8');
 const native='((_t,a,i)=>arrayget(a,i))';assert.equal(base.split(native).length,2);
 const unknown=base.replace(native,'((_t,a,i)=>unknown_get(a,i))');assert.throws(()=>actual.fusion(unknown),/at least one canonical producer/);report.refusals.push('unknown-native-producer');
 const consumer=actual.inventory(base).workers.find(w=>w.node.id.name===selected.consumer).node;
 const original=base.slice(consumer.start,consumer.end),last=consumer.params.at(-1).name;
 const changed=original.replaceAll(last+'[',last+'.a[');assert.notEqual(changed,original);
 const noncanonical=base.slice(0,consumer.start)+changed+base.slice(consumer.end);assert.throws(()=>actual.fusion(noncanonical),/at least one canonical producer/);report.refusals.push('record-vector-instead-of-canonical-tuple');
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:report.cases.length,error:report.error}));
