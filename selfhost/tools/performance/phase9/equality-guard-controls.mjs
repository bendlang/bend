// Bounded operation/semantic screen for P9-006; no compiler throughput claim.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL,fileURLToPath} from 'node:url';

const directory=path.resolve(process.argv[2]);
const root=path.resolve(process.argv[3]);
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'),bytes:fs.statSync(file).size});
const read=file=>fs.readFileSync(file,'utf8');
const start=performance.now(),deadline=start+20000;
const candidate=await import(pathToFileURL(path.join(directory,'equality.mjs')));
const previous=await import(pathToFileURL(path.join(directory,'equality-original.mjs')));
const parent=path.join(root,'selfhost/build/phase9/integrated-02/api.mjs');
const bootstrap=parent+'.bootstrap.json';
const source=read(parent),old=previous.transformEquality(source),next=candidate.transformEquality(source);
const report={kind:'phase9-current-equality-guard-screen',complete:false,pass:false,started:new Date().toISOString(),
  inputs:[identity(parent),identity(bootstrap),identity(path.join(directory,'equality.mjs')),identity(path.join(directory,'equality-original.mjs')),identity(fileURLToPath(import.meta.url))],
  scope:'Primitive UTF-16 equality and unchanged non-string fallback with standard built-ins; bounded same-process operation screen, concurrent with other development, not compiler throughput.',
  deadlineMs:20000,seed:0x50e90006,counts:{},operation:[]};
fs.copyFileSync(fileURLToPath(import.meta.url),path.join(directory,'equality-guard-controls.mjs'));
let checks=0;
const checkTime=()=>assert.ok(performance.now()<deadline,'Bounded 20-second screen deadline exceeded');
try {
  assert.equal(next.stats.version,3);assert.equal(old.stats.version,2);
  assert.deepEqual(candidate.transformEquality(source,2),old);
  assert.deepEqual(candidate.transformEquality(source,3),next);
  for(const version of [0,1,4,'2',null])assert.throws(()=>candidate.transformEquality(source,version));
  const legacy=read(path.join(root,'selfhost/build/phase7/s4/attempt-b02/api.mjs'));
  assert.deepEqual(candidate.transformEquality(legacy),previous.transformEquality(legacy));
  assert.throws(()=>candidate.transformEquality(legacy,2));
  candidate.verifyEqualityDerivation(path.join(root,'selfhost/build/phase9/integrated-02/equality/api.mjs.derivation.json'));
  const derived=await candidate.deriveEquality({api:parent,bootstrapReport:bootstrap,outputDirectory:path.join(directory,'derived')});
  candidate.verifyEqualityDerivation(derived.report);
  assert.equal(read(derived.api),next.source);
  report.lineage={version1Exact:true,version2Exact:true,version2RecordedReplay:true,version3RecordedReplay:true,derived:identity(derived.api),report:identity(derived.report)};
  const modules=[];
  for(const [name,body] of [['original',source],['version2',old.source],['version3',next.source]]) {
    const file=path.join(directory,name+'-exposed.mjs');
    fs.writeFileSync(file,body+'\nexport const equality=(a,b)=>run_loop($String$eq$(a,b));\n',{flag:'wx'});
    modules.push(await import(pathToFileURL(file)));
  }
  const functions=modules.map(m=>m.equality);
  const compare=(a,b)=>{
    const expected=a===b;
    for(let index=0;index<functions.length;index++)assert.equal(functions[index](a,b),expected,'UTF-16 equality mismatch in variant '+index);
    if((++checks&16383)===0)checkTime();
  };
  let before=checks;
  for(let code=0;code<=0xffff;code++) {
    const s=String.fromCharCode(code),other=String.fromCharCode(code^1);
    compare(s,s);compare(s,other);compare('',s);compare(s,'');
  }
  report.counts.singleCodeUnitPairs=checks-before;
  before=checks;
  for(let high=0xd800;high<=0xdbff;high++)for(let low=0xdc00;low<=0xdfff;low++) {
    const a=String.fromCharCode(high,low),b=String.fromCharCode(high,low^1);
    compare(a,a);compare(a,b);
  }
  report.counts.validSurrogatePairs=checks-before;
  before=checks;
  const alphabet=['\0','a','é','\ud7ff','\ud800','\udbff','\udc00','\udfff','\ue000','\uffff'];
  const short=['',...alphabet,...alphabet.flatMap(a=>alphabet.map(b=>a+b))];
  for(const a of short)for(const b of short)compare(a,b);
  report.counts.representativeShortPairs=checks-before;
  let seed=report.seed;
  const random=()=>{seed^=seed<<13;seed^=seed>>>17;seed^=seed<<5;return seed>>>0;};
  before=checks;
  for(let i=0;i<10000;i++) {
    let a='';const length=random()%49;
    for(let j=0;j<length;j++)a+=String.fromCharCode(random()&0xffff);
    let b=a;
    if(i%3===0)b=a+String.fromCharCode(random()&0xffff);
    else if(i%3===1&&a.length){const at=random()%a.length;b=a.slice(0,at)+String.fromCharCode(a.charCodeAt(at)^1)+a.slice(at+1);}
    compare(a,b);
  }
  report.counts.seededFuzzPairs=checks-before;
  before=checks;
  for(const n of [1,16,128,512])for(const tail of ['','x','\ud800','\udc00','🙂','🙂\ud800']) {
    const prefix='a🙂\ud800'.repeat(n);
    compare(prefix+tail,prefix+tail);compare(prefix+tail,prefix+tail+'x');compare(prefix+tail,prefix+tail.slice(0,-1));
  }
  report.counts.commonPrefixPairs=checks-before;
  const observe=(fn,make)=>{
    const events=[],args=make(events);let outcome;
    try{outcome={value:fn(...args)};}catch(error){outcome={error:String(error)};}
    return {events,outcome};
  };
  const object=(events,label,value,fail)=>new Proxy(new String(value),{get(target,key){events.push(label+':'+String(key));if(key===fail)throw Error(label+': demanded '+String(key));const result=Reflect.get(target,key,target);return typeof result==='function'?function(...args){events.push(label+':call:'+String(key));return Reflect.apply(result,target,args);}:result;}});
  const cases=[
    e=>[object(e,'a','a'),'a'],e=>['a',object(e,'b','a')],
    e=>[object(e,'a','a','codePointAt'),'x'],e=>['',object(e,'b','a','codePointAt')],
    e=>[object(e,'a','x\ud800'),object(e,'b','y\ud800')],
    e=>[object(e,'a','\ud800'),object(e,'b','\ud800')],
    e=>[object(e,'a','a','slice'),object(e,'b','a')],
    ...[null,undefined,0,1,true,false,Symbol('s'),{},[],()=>0].flatMap(value=>[e=>[value,'a'],e=>['a',value]])
  ];
  report.fallback=cases.map((make,index)=>{
    const observations=functions.map(fn=>observe(fn,make));
    assert.deepEqual(observations[1],observations[0]);assert.deepEqual(observations[2],observations[0]);
    return {index,pass:true,observation:observations[0]};
  });
  report.counts.fallbackCases=cases.length;
  report.counts.primitivePairs=checks;
  const pairs={
    compilerTags:Array.from({length:256},(_,i)=>['Type|Lam|App|Ref|Ctor|Absent'.split('|')[i%6],i%3?'Type|Lam|App|Ref|Ctor|Absent'.split('|')[i%6]:'Missing']),
    identifiers:Array.from({length:256},(_,i)=>['compiler.namespace.function_'+i,i%3?'compiler.namespace.function_'+i:'compiler.namespace.other_'+i]),
    unicode:Array.from({length:256},(_,i)=>['λ.日本語.🙂.name_'+i,i%3?'λ.日本語.🙂.name_'+i:'λ.日本語.🙂.other_'+i]),
    longPrefixes:Array.from({length:256},(_,i)=>['source/'.repeat(64)+i,i%3?'source/'.repeat(64)+i:'source/'.repeat(64)+(i+1)]),
    malformed:Array.from({length:256},(_,i)=>['a\ud800prefix_'+i,i%3?'a\ud800prefix_'+i:'a\ud800different_'+i])
  };
  for(const [workload,values] of Object.entries(pairs)) {
    const iterations=100000;
    const run=(variant,count)=>{let result=0;const fn=functions[variant],start=performance.now();for(let i=0;i<count;i++){const pair=values[i&255];result+=fn(pair[0],pair[1])?1:0;}return {ms:performance.now()-start,result};};
    run(1,10000);run(2,10000);
    for(let block=0;block<4;block++)for(const variant of [1,2,2,1]) {
      checkTime();const observation=run(variant,iterations);
      const expected=Math.floor(iterations/256)*values.filter(([a,b])=>a===b).length+values.slice(0,iterations%256).filter(([a,b])=>a===b).length;
      assert.equal(observation.result,expected);
      report.operation.push({workload,block,version:variant+1,iterations,...observation});
    }
  }
  report.operationSummary=Object.keys(pairs).map(workload=>{
    const median=rows=>{const values=rows.map(x=>x.ms).sort((a,b)=>a-b);return (values[values.length/2-1]+values[values.length/2])/2;};
    const v2=median(report.operation.filter(x=>x.workload===workload&&x.version===2)),v3=median(report.operation.filter(x=>x.workload===workload&&x.version===3));
    return {workload,version2MedianMs:v2,version3MedianMs:v3,version2OverVersion3:v2/v3};
  });
  checkTime();
  for(const before of report.inputs)assert.deepEqual(identity(before.file),before,'Changed input');
  report.pass=true;report.complete=true;
} catch(error) {report.error=String(error.stack??error);throw error;}
finally {
  report.wallMs=performance.now()-start;report.finished=new Date().toISOString();
  fs.writeFileSync(path.join(directory,'screen.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
  console.log(JSON.stringify({complete:report.complete,pass:report.pass,counts:report.counts,operationSummary:report.operationSummary,wallMs:report.wallMs}));
}
