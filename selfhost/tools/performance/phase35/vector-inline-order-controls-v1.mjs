#!/usr/bin/env node
// Execute extracted inline capture/read scaffolding with hostile order observers.
// The original consumer is replaced; complete-arm semantics have separate gates.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
const [input,outArg]=process.argv.slice(2),file=path.resolve(input),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const hash=s=>createHash('sha256').update(s).digest('hex');
const identity=p=>({file:fs.realpathSync(p),sha256:hash(fs.readFileSync(p))});
const report={kind:'phase35-inline-read-order-controls',complete:false,pass:false,
 scope:'Exact actual compiler capture/binding/read scaffolding with controlled argument expressions and observer continuation. Diagnostic order witnesses, not public hostile-object admission.',
 inputs:[import.meta.filename,file,file+'.json'].map(identity),blocks:[],cases:[],negative:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try {
 const receipt=JSON.parse(fs.readFileSync(file+'.json'));
 assert.equal(receipt.complete,true); assert.equal(receipt.observation.checked,true);
 assert.equal(identity(file).sha256,receipt.output.sha256);
 const source=fs.readFileSync(file,'utf8'),parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
 const m={exports:{}};new Function('module','exports',parserSource)(m,m.exports);
 assert.equal(m.exports.version,'8.16.0');
 report.parser={version:m.exports.version,sourceSha256:hash(parserSource)};
 const tree=m.exports.parse(source,{ecmaVersion:'latest',sourceType:'module'});
 const single=n=>n?.type==='VariableDeclaration'&&n.kind==='const'&&n.declarations.length===1?n.declarations[0]:null;
 function visit(n) {
  if(!n||typeof n!=='object')return;
  if(n.type==='BlockStatement' && n.body.length>=2) {
   const inner=n.body.at(-1),captures=n.body.slice(0,-1).map(single);
   if(inner?.type==='BlockStatement' && captures.every((d,i)=>d?.id.type==='Identifier'&&d.id.name==='$i'+i)) {
    const declarations=inner.body.map(single);
    const readAt=declarations.findIndex(d=>d?.init?.type==='MemberExpression'&&d.init.object?.name==='$data');
    if(readAt>=0 && declarations.slice(0,readAt+1).every(Boolean)) {
     const count=captures.length,arity=count-2;
     const names=declarations.slice(0,readAt+1).map(d=>d.id.name);
     if(names.includes('$array')&&names.includes('$index')&&names.includes('$p'+arity)&&names.includes('$p'+(arity+1))) {
      report.blocks.push({arity,captures:captures.map(d=>({name:d.id.name,expression:source.slice(d.init.start,d.init.end)})),
       prologue:source.slice(inner.body[0].start,inner.body[readAt].end),
       sourceSha256:hash(source.slice(n.start,n.end))});
     }
    }
   }
  }
  for(const [key,v] of Object.entries(n)){if(key==='start'||key==='end')continue;if(Array.isArray(v))v.forEach(visit);else if(v&&typeof v==='object')visit(v);}
 }
 visit(tree);assert.ok(report.blocks.length>0,'actual inlined read block found');
 const selected=report.blocks.find(b=>b.arity===3);
 assert.ok(selected,'two-prefix inlined read block exists');
 assert.equal(selected.captures[2].expression,'null','erased source argument remains erased');
 const expressions=['$p0()','$p1()','null','$handle()','$offset()'];
 const scaffold='{'+selected.captures.map((c,i)=>'const '+c.name+'='+expressions[i]+';').join('')+
  '{'+selected.prologue+'return consume($p0,$p1,$p3,$p4);}}';
 report.observer={source:scaffold,sha256:hash(scaffold),selected};
 function run(actual,scenario) {
  const events=[],raw=[7,11];
  const storage=new Proxy(raw,{get(t,k,r){if(k==='length'||/^\d+$/.test(String(k)))events.push('read:'+String(k));if(scenario==='read-throw'&&k==='0')throw Error('read sentinel');return Reflect.get(t,k,r)},set(t,k,v,r){events.push('write:'+String(k)+':'+v);return Reflect.set(t,k,v,r)}});
  const handle={array:storage};
  const consume=(a,b,h,v)=>{events.push('consumer');assert.equal(h,handle);if(scenario==='consumer-write'||scenario==='aliases')h.array[0]=99;return scenario==='unused'?a+b:[a,b,v,h===handle]};
  const arraydata=h=>{events.push('arraydata');assert.equal(h,handle);if(scenario==='arraydata-throw')throw Error('arraydata sentinel');return h.array};
  function prefix(i){events.push('prefix:'+i);if(scenario==='prefix-'+i)storage[0]=i===0?13:17;if(scenario==='prefix-throw'&&i===1)throw Error('prefix sentinel');return i+3;}
  function harg(){events.push('handle');if(scenario==='handle-write')storage[0]=23;return handle;}
  function offset(){events.push('index');if(scenario==='index-write')storage[0]=29;return scenario==='wrap'?129:0;}
  const invoke=actual?new Function('arraydata','consume','$p0','$p1','$handle','$offset',scaffold):
   (arraydata,consume,p0,p1,harg,offset)=>{const a=p0(),b=p1(),h=harg(),i=offset(),xs=arraydata(h),v=xs[Number(i)%xs.length];return consume(a,b,h,v);};
  try{const value=invoke(arraydata,consume,()=>prefix(0),()=>prefix(1),harg,offset);return {value,events,storage:raw.slice()};}
  catch(error){return {error:error.message,events,storage:raw.slice()};}
 }
 for(const scenario of ['plain','prefix-0','prefix-1','handle-write','index-write','consumer-write','aliases','wrap','unused','read-throw','arraydata-throw','prefix-throw']) {
  const baseline=run(false,scenario),actual=run(true,scenario);assert.deepEqual(actual,baseline,scenario);
  if(scenario==='unused')assert.ok(actual.events.includes('read:0'));
  if(scenario.endsWith('-throw'))assert.ok(!actual.events.includes('consumer'));
  if(scenario==='consumer-write')assert.equal(actual.value[2],7);
  report.cases.push({scenario,baseline,actual});
 }
 const captured=run(true,'consumer-write').value[2],early=run(true,'prefix-0').value[2];
 assert.equal(captured,7);assert.equal(early,13);
 report.negative.push({kind:'deferred-read',correct:captured,wrong:99},{kind:'read-before-prefix',correct:early,wrong:7});
 for(const i of report.inputs)assert.deepEqual(identity(i.file),i);
 report.complete=report.pass=true;
} catch(error) {report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({pass:report.pass,complete:report.complete,blocks:report.blocks.length,cases:report.cases.length,error:report.error}));
