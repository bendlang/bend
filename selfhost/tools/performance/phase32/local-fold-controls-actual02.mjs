// Separate BigInt fold oracle, complete storage events and public fallback.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [dirArg,outArg]=process.argv.slice(2),dir=path.resolve(dirArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifest=JSON.parse(fs.readFileSync(path.join(dir,'derive.json'))),variants=Object.keys(manifest.variants),files=variants.map(v=>manifest.variants[v].file);
const report={kind:'phase32-local-fold-controls-actual02',complete:false,pass:false,inputs:[import.meta.filename,path.join(dir,'derive.json'),...files].map(identity),predecessor:{file:'selfhost/tools/performance/phase32/local-fold-controls.mjs',sha256:'1d73eb4319620075075ddc2ba9faf32aa6de19849005e203e4b782ab578e1505'},instrumentation:[],oracle:[],state:[],boundaries:[],negative:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function oracle(n,seed,late=false){const mask=0xffffffffn,a=Array(128).fill(BigInt(seed)),events=[['new',1,128,seed]];let acc=0n;
 for(let i=0;i<n;i++){const v=a[i%128];events.push(['get',1,i,Number(v)]);acc=(acc+v)&mask;if(!late){a[i%128]=(acc^BigInt(i))&mask;events.push(['set',1,i,Number(a[i%128])])}}
 return {value:Number(acc),array:a.map(Number),events};
}
function instrument(text,variant){
 const edit=(a,b)=>{assert.equal(text.split(a).length,2,a);text=text.replace(a,b)};
 edit('return {array:Array(size).fill(v)}}',"const h={array:Array(size).fill(v)};$LCheckHandles.push(h);$LCheckEvents.push(['new',$LCheckHandles.length,size,v]);return h}");
 edit('function arrayget(a,i){const xs=arraydata(a);return [a,xs[Number(i)%xs.length]]}',"function arrayget(a,i){const xs=arraydata(a),v=xs[Number(i)%xs.length];$LCheckEvents.push(['get',$LCheckHandles.indexOf(a)+1,Number(i),v]);return [a,v]}");
 if(text.includes('function $L32_read(a,i){'))edit('function $L32_read(a,i){const xs=arraydata(a);return xs[Number(i)%xs.length]}',"function $L32_read(a,i){const xs=arraydata(a),v=xs[Number(i)%xs.length];$LCheckEvents.push(['get',$LCheckHandles.indexOf(a)+1,Number(i),v]);return v}");

 // Actual typed bridges read inline; observe that exact read without creating a
 // tuple or changing its position before consumer writes. Reject unknown shape.
 const bridgeCount=(text.match(/function \$R(?:_\d+)+\$get\(/g)||[]).length;
 let actualReadCount=0;
 text=text.replace(/const \$data=arraydata\(\$array\);const (\$p\d+)=\$data\[Number\(\$index\)%\$data\.length\];/g,(before,value)=>{
  actualReadCount++;
  return before+"$LCheckEvents.push(['get',$LCheckHandles.indexOf($array)+1,Number($index),"+value+"]);";
 });
 assert.equal(actualReadCount,bridgeCount,'every actual bridge has one observed canonical read');
 report.instrumentation.push({variant,actualBridges:bridgeCount,actualReads:actualReadCount,prototypeReadHelper:text.includes('function $L32_read(a,i){')});
 edit('function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;return a}',"function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;$LCheckEvents.push(['set',$LCheckHandles.indexOf(a)+1,Number(i),v]);return a}");
 return 'const $LCheckHandles=[],$LCheckEvents=[];\n'+text+'\nexport const localCheck={handles:$LCheckHandles,events:$LCheckEvents,reset(){ $LCheckHandles.length=0;$LCheckEvents.length=0; }};\n';
}
try{
 const modules=[];for(const p of files)modules.push(await import(pathToFileURL(p)));
 for(const n of [0,1,2,7,32,64,128,129,130,257])for(const seed of [0,1,17,4294967295]){
  const expected=oracle(n,seed).value,results=modules.map(m=>m.default.bench(n,seed));for(const r of results)assert.equal(r,expected);report.oracle.push({args:[n,seed],expected,results});
 }
 {const expected=oracle(4096,17).value;assert.equal(expected,2339999928);const results=modules.map(m=>m.default.bench(4096,17));for(const r of results)assert.equal(r,expected);report.oracle.push({args:[4096,17],expected,results})}
 for(let i=0;i<modules.length-1;i++){
  const file=path.join(out,variants[i]+'-instrumented.mjs');fs.writeFileSync(file,instrument(fs.readFileSync(files[i],'utf8'),variants[i]),{flag:'wx'});const m=await import(pathToFileURL(file));
  for(const n of [0,1,130,257]){m.localCheck.reset();const expected=oracle(n,17),value=m.default.bench(n,17);assert.equal(value,expected.value);assert.equal(m.localCheck.handles.length,1);assert.deepEqual(m.localCheck.handles[0].array,expected.array);assert.deepEqual(m.localCheck.events,expected.events);report.state.push({variant:variants[i],args:[n,17],value,events:expected.events,array:expected.array})}
 }
 for(const name of ['bench','fold.loop','fold.cell','fold.step','fold.finish','Array.get','Array.set']){
  const observations=[];for(const m of modules.slice(0,-1)){const f=m.G[name],old=f.code,events=[];try{f.code=()=>{events.push(name);throw Error('mutation:'+name)};try{observations.push({value:m.default.bench(2,17),events})}catch(e){observations.push({error:e.message,events})}}finally{f.code=old}}
  for(const o of observations.slice(1))assert.deepEqual(o,observations[0]);report.boundaries.push({name,observations});
 }
 for(const [n,seed]of [[130,17],[257,1],[257,4294967295]]){const correct=oracle(n,seed).value,late=oracle(n,seed,true).value;assert.equal(correct===late,seed===4294967295);report.negative.push({n,seed,correct,late,distinguishes:correct!==late})}
 assert.ok(report.instrumentation.some(x=>x.actualBridges>0),'cohort includes an actual typed fusion bridge');
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,state:report.state.length,boundaries:report.boundaries.length,error:report.error}));
