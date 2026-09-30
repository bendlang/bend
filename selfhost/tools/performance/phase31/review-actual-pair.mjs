// Independent actual-compiler full-pair value, storage and operation review.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';import {gzipSync} from 'node:zlib';
const [baselineArg,candidateArg,outArg]=process.argv.slice(2),files=[baselineArg,candidateArg].map(x=>path.resolve(x)),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const report={kind:'phase31-independent-actual-pair',complete:false,pass:false,node:process.version,
  scope:'Actual checked compiler modules; three full-pair values, one complete allocation-state and native schedule per side. No timing.',
  inputs:[import.meta.filename,...files,...files.map(x=>x+'.json')].map(identity),values:[],schedules:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review.mjs'));

function oracle(p,keep){
  const mask=0xffffffffn,events=[],arrays=[];
  const event=e=>{if(keep)events.push(e)};
  const alloc=size=>{const id=arrays.length;arrays.push(Array(size).fill(0));event(['allocate',id,size,0]);return id};
  const read=(id,j)=>{const x=arrays[id][j%arrays[id].length];event(['read',id,j,x]);return x};
  const write=(id,j,x)=>{arrays[id][j%arrays[id].length]=x;event(['write',id,j,x])};
  function stream(seed){const id=alloc(256);let s=seed;
    for(let k=0;k<256;k++){s=((s^(s<<13n))&mask);s=((s^(s>>17n))&mask);s=((s^(s<<5n))&mask);write(id,k,Number(s%4n))}return id}
  const seed=((BigInt(p)+1n)*2654435761n)&mask,a=stream(seed),b=stream((seed*340573321n)&mask);
  let prev=alloc(512);for(let k=0;k<=256;k++)write(prev,k,k);let cur=alloc(512);
  for(let i=0;i<256;i++){
    const x=read(a,i);write(cur,0,i+1);
    for(let j=0;j<256;j++){
      const y=read(b,j),diagonal=read(prev,j),upper=read(prev,j+1),left=read(cur,j);
      write(cur,j+1,Math.min(upper+1,left+1,diagonal+(x===y?0:1)));
    }
    const old=prev;prev=cur;cur=old;
  }
  const distance=read(prev,256),value=Number(((BigInt(distance)*2654435761n)&mask)^((BigInt(p)+1n)&mask));
  return {value,arrays,roles:[a,b,prev,cur],events};
}
function instrument(text){
  function edit(a,b){assert.equal(text.split(a).length,2,a);text=text.replace(a,b)}
  edit('return {array:Array(size).fill(v)}}',"const h={array:Array(size).fill(v)},id=$ReviewHandles.length;$ReviewHandles.push(h);$ReviewEvents.push(['allocate',id,size,v]);return h}");
  edit('function arrayget(a,i){const xs=arraydata(a);return [a,xs[Number(i)%xs.length]]}',"function arrayget(a,i){const xs=arraydata(a),v=xs[Number(i)%xs.length];$ReviewEvents.push(['read',$ReviewHandles.indexOf(a),Number(i),v]);return [a,v]}");
  edit('function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;return a}',"function arrayset(a,i,v){const xs=arraydata(a);xs[Number(i)%xs.length]=v;$ReviewEvents.push(['write',$ReviewHandles.indexOf(a),Number(i),v]);return a}");
  return 'const $ReviewHandles=[],$ReviewEvents=[];\n'+text+'\nexport const review={handles:$ReviewHandles,events:$ReviewEvents,reset(){ $ReviewHandles.length=0;$ReviewEvents.length=0; }};\n';
}
function saveEvents(name,events){const raw=Buffer.from(events.map(e=>JSON.stringify(e)+'\n').join('')),file=path.join(out,name+'.ndjson.gz');fs.writeFileSync(file,gzipSync(raw),{flag:'wx'});return {events:events.length,rawBytes:raw.length,rawSha256:sha(raw),compressed:identity(file)}}
try{
  const receipts=files.map(p=>JSON.parse(fs.readFileSync(p+'.json')));
  for(let i=0;i<files.length;i++){assert.equal(receipts[i].complete,true);assert.equal(receipts[i].observation.checked,true);assert.equal(identity(files[i]).sha256,receipts[i].output.sha256)}
  assert.equal(receipts[0].input.sha256,receipts[1].input.sha256,'same source fixture');
  const candidateText=fs.readFileSync(files[1],'utf8'),pairLine=candidateText.split('\n').find(x=>x.startsWith('G["pair"]=') );
  assert.ok(pairLine.includes('/* private scalar root */'));assert.ok(pairLine.includes('localGuard($guards)'));
  for(const name of ['Array.new','Array.get','Array.set','cell','row','dp','gen','init'])assert.ok(pairLine.includes(JSON.stringify(name)),name+' guarded');
  const modules=await Promise.all(files.map(p=>import(pathToFileURL(p))));
  for(const p of [0,17,0xffffffff]){const expected=oracle(p,false).value,actual=modules.map(m=>m.default.pair(p));for(const x of actual)assert.equal(x,expected);report.values.push({p,expected,actual})}
  const p=17,expected=oracle(p,true);assert.deepEqual(expected.roles,[0,1,2,3]);assert.equal(expected.events.length,328966);
  report.expectedSchedule=saveEvents('expected-p17',expected.events);report.expectedArrays=expected.arrays;
  for(let i=0;i<files.length;i++){
    const modulePath=path.join(out,(i?'candidate':'baseline')+'-instrumented.mjs');fs.writeFileSync(modulePath,instrument(fs.readFileSync(files[i],'utf8')),{flag:'wx'});
    const m=await import(pathToFileURL(modulePath));m.review.reset();const actual=m.default.pair(p),arrays=m.review.handles.map(h=>h.array);
    assert.equal(actual,expected.value);assert.deepEqual(arrays,expected.arrays);assert.deepEqual(m.review.events,expected.events);
    const counts={allocate:0,read:0,write:0};for(const e of m.review.events)counts[e[0]]++;
    assert.deepEqual(counts,{allocate:4,read:262401,write:66561});
    report.schedules.push({variant:i?'candidate':'baseline',p,value:actual,counts,arrays,instrumented:identity(modulePath),events:saveEvents(i?'candidate-p17':'baseline-p17',m.review.events)});
  }
  for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,values:report.values.length,schedules:report.schedules.length,error:report.error}));
