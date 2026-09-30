// Diagnostic order witnesses extracted from an actual checked bridge.
// The retained prologue is exact; only its consumer arm is replaced by an
// observer. Complete original-arm behavior is checked by the pair/fold tools.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';

const [moduleArg,outArg]=process.argv.slice(2),moduleFile=path.resolve(moduleArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const hash=text=>createHash('sha256').update(text).digest('hex');
const report={kind:'phase32-actual-bridge-prologue-order-controls',complete:false,pass:false,scope:'Exact bridge parameter list and first three declarations; observer replaces the original consumer arm. Diagnostic proof-boundary witnesses, not public hostile-input admission.',inputs:[import.meta.filename,moduleFile,moduleFile+'.json'].map(identity),bridges:[],cases:[],negative:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try{
 const receipt=JSON.parse(fs.readFileSync(moduleFile+'.json'));
 assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);
 assert.equal(identity(moduleFile).sha256,receipt.output.sha256);
 const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
 const parserModule={exports:{}};new Function('exports','module',parserSource)(parserModule.exports,parserModule);
 const acorn=parserModule.exports,text=fs.readFileSync(moduleFile,'utf8'),ast=acorn.parse(text,{ecmaVersion:'latest',sourceType:'module'});
 report.parser={version:acorn.version,embeddedSourceSha256:hash(parserSource)};
 const bridges=[];
 function walk(node){if(!node||typeof node!=='object')return;if(node.type==='FunctionDeclaration'&&/\$get$/.test(node.id?.name||''))bridges.push(node);for(const [key,value]of Object.entries(node)){if(key==='start'||key==='end')continue;if(Array.isArray(value)){for(const child of value)walk(child)}else if(value&&typeof value==='object')walk(value)}}
 walk(ast);assert.ok(bridges.length>0,'actual typed bridge emitted');
 for(const node of bridges){
  assert.ok(/^\$R(?:_\d+)+\$get$/.test(node.id.name));
  const params=node.params.map(p=>{assert.equal(p.type,'Identifier');return p.name});
  assert.deepEqual(params.slice(-3),['_t','$array','$index']);
  const count=params.length-3;assert.deepEqual(params.slice(0,count),Array.from({length:count},(_,i)=>'$p'+i));
  const handle='$p'+(count+1),value='$p'+(count+2);
  assert.ok(node.body.body.length>=3);
  const prologue=text.slice(node.body.body[0].start,node.body.body[2].end);
  assert.equal(prologue,'const '+handle+'=$array;const $data=arraydata($array);const '+value+'=$data[Number($index)%$data.length];');
  const original=text.slice(node.start,node.end);
  report.bridges.push({name:node.id.name,params,handle,value,prologue,original,originalSha256:hash(original)});
 }
 const selected=report.bridges.find(b=>b.params.length===5);
 assert.ok(selected,'fixture has a bridge with two ordinary prefix parameters');
 const observedBridge='function '+selected.name+'('+selected.params.join(',')+'){'+selected.prologue+'return consume($p0,$p1,'+selected.handle+','+selected.value+');}';
 report.observerBridge={source:observedBridge,sha256:hash(observedBridge),selected:selected.name};
 function run(kind,scenario){
  const events=[],raw=[7,11];
  const store=new Proxy(raw,{get(t,k,r){if(k==='length'||/^\d+$/.test(String(k)))events.push('read:'+String(k));if(scenario==='read-throw'&&k==='0')throw Error('read sentinel');return Reflect.get(t,k,r)},set(t,k,v,r){events.push('write:'+String(k)+':'+v);return Reflect.set(t,k,v,r)}});
  const handle={array:store};
  const consume=(a,b,h,v)=>{events.push('consumer');assert.equal(h,handle);if(scenario==='consumer-write'||scenario==='aliases')h.array[0]=99;return scenario==='unused'?a+b:[a,b,v,h===handle]};
  const arraydata=h=>{events.push('arraydata');assert.equal(h,handle);if(scenario==='arraydata-throw')throw Error('arraydata sentinel');return h.array};
  const invoke=kind==='actual'?new Function('arraydata','consume',observedBridge+';return '+selected.name)(arraydata,consume):
   (a,b,_t,h,i)=>{const xs=arraydata(h),tuple=[h,xs[Number(i)%xs.length]];return consume(a,b,tuple[0],tuple[1])};
  function prefix(which){events.push('prefix:'+which);if(scenario==='prefix-'+which)store[0]=which===0?13:17;return which+3}
  function erased(){events.push('erased');return null}
  function harg(){events.push('handle');if(scenario==='handle-write')store[0]=23;return handle}
  function iarg(){events.push('index');if(scenario==='index-write')store[0]=29;return scenario==='wrap'?129:0}
  try{
   const value=invoke(prefix(0),prefix(1),erased(),harg(),iarg());
   if(scenario==='separated-gets'){store[0]=41;const second=invoke(3,4,null,handle,0);return {value,second,events,store:raw.slice()}}
   return {value,events,store:raw.slice()};
  }catch(error){return {error:error.message,events,store:raw.slice()}}
 }
 for(const scenario of ['plain','prefix-0','prefix-1','handle-write','index-write','consumer-write','aliases','wrap','unused','separated-gets','read-throw','arraydata-throw']){
  const baseline=run('baseline',scenario),actual=run('actual',scenario);assert.deepEqual(actual,baseline,scenario);
  if(scenario==='consumer-write')assert.equal(actual.value[2],7);
  if(scenario==='prefix-0')assert.equal(actual.value[2],13);
  if(scenario==='unused')assert.ok(actual.events.includes('read:0'),'unused scalar still read');
  for(const event of ['prefix:0','prefix:1','erased','handle','index'])assert.equal(actual.events.filter(x=>x===event).length,1);
  if(scenario.endsWith('-throw'))assert.ok(!actual.events.includes('consumer'));
  report.cases.push({scenario,baseline,actual});
 }
 const captured=run('actual','consumer-write').value[2],h={array:[7,11]},late=()=>h.array[0];h.array[0]=99;
 assert.equal(captured,7);assert.equal(late(),99);report.negative.push({kind:'deferred-read',correct:captured,wrong:late()});
 const prefixCorrect=run('actual','prefix-0').value[2];assert.equal(prefixCorrect,13);assert.notEqual(prefixCorrect,7);report.negative.push({kind:'read-before-earlier-argument',correct:prefixCorrect,wrong:7});
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,bridges:report.bridges.length,cases:report.cases.length,error:report.error}));
