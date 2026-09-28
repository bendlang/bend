import fs from 'node:fs';import path from 'node:path';import vm from 'node:vm';import crypto from 'node:crypto';
import {supervise} from '../../development/process.mjs';
const project=path.resolve(import.meta.dirname,'../../..'),out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const hash=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const original=path.join(project,'src/back/js/test-layout.mjs'),text=fs.readFileSync(original,'utf8');
const fixtures=vm.runInNewContext(text.slice(text.indexOf('const wrap='),text.indexOf('const cases='))+'fixtures');
fixtures['nat-dynamic-open-array']=['def wrap(-T: Type, x: T) -> Array<T>:\n  ALeaf{x}\n\ndef keep(a: Array<U32>) -> Nat:\n  3n\n\ndef tail() -> Nat:\n  keep(wrap(U32, 3))\n\ndef main() -> Nat:\n  Succ{tail()}\n',true];
const cases=Object.entries(fixtures).map(([name,[source,error]])=>{const file=path.join(out,name+'.bend');fs.writeFileSync(file,'import Base\n\n'+source);return{name,file,expectedStatus:error?'error':'ok',expectedDiagnostic:error?'Error: an open Array element type':null}});
for(const [name,source,stdout,mode] of [
 ['nat-dynamic-tail','import Base\n\ndef tail(n: Nat) -> Nat:\n  n\n\ndef main() -> Nat:\n  Succ{tail(3n)}\n','4n\n','compile'],
 ['nat-explicit','import Base\n\ndef main() -> Nat:\n  Succ{Succ{Zero{}}}\n','2n\n','compile'],
 ['custom-nat-library','type Nat is Data:\n  Zero{}\n  Succ{pred: Nat}\n\ndef main() -> Nat:\n  3n\n',undefined,'library'],
]){const file=path.join(out,name+'.bend');fs.writeFileSync(file,source);cases.push({name,file,expectedStatus:name==='custom-nat-library'?'error':'ok',expectedDiagnostic:name==='custom-nat-library'?'Error: Nat is a name the compiler encodes itself: name yours apart':null,stdout,mode});}
for(const depth of [32,300]){const file=path.join(out,'nat-'+depth+'.bend');fs.copyFileSync(path.join(project,depth===300?'build/phase10/layout-candidate-counts-01/nat-300.bend':'build/phase10/layout-01/nat-32.bend'),file);cases.push({name:'nat-'+depth,file,expectedStatus:'ok',stdout:(depth+6)+'n\n'});}
const worker=path.join(out,'worker.mjs');fs.copyFileSync(path.join(import.meta.dirname,'layout-control-worker.mjs'),worker);
const variants={baseline:path.join(project,'build/phase9/integrated-03/equality/api.mjs'),candidate:path.resolve(process.argv[3]||path.join(project,'build/phase10/layout-candidate-01/attempt/equality/api.mjs'))};
const report={scope:'Selected checked-source exact layout errors and emitted-byte comparison; selected Nat programs execute their emitted JS. Concurrent development, not controlled timing.',inputs:[original,import.meta.filename,worker,process.execPath,path.join(project,'tools/typed-driver.mjs'),...cases.map(x=>x.file),...Object.values(variants),path.join(project,'dist/base.bend'),path.join(project,'src/runtime.mjs')].map(file=>({file,sha256:hash(file)})),rows:[]};
for(const row of cases.filter(row=>!process.argv[4]||process.argv[4].split(',').includes(row.name)))for(const [variant,api] of Object.entries(variants)){
 const directory=path.join(out,row.name+'-'+variant);fs.mkdirSync(directory);const request={...row,driver:path.join(project,'tools/typed-driver.mjs'),directory};const requestFile=path.join(directory,'request.json');fs.writeFileSync(requestFile,JSON.stringify(request,null,2));
 const result=await supervise('taskset',['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,requestFile],{env:{...process.env,BEND_TYPED_API:api,BEND_BASE:path.join(project,'dist/base.bend')},directory:path.join(directory,'process'),timeoutMs:60000});
 const resultFile=path.join(directory,'result.json');report.rows.push({...row,variant,execution:result,result:fs.existsSync(resultFile)?JSON.parse(fs.readFileSync(resultFile)):null});
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(row.name,variant,result.exitCode,result.timedOut);
}

report.pairs=[];
for(const name of new Set(report.rows.map(row=>row.name))){const rows=report.rows.filter(row=>row.name===name),[baseline,candidate]=rows;const observation=x=>({observation:x?.result?.observation,codeSha256:x?.result?.codeSha256,runtime:x?.result?.runtime});report.pairs.push({name,same:JSON.stringify(observation(baseline))===JSON.stringify(observation(candidate))});}
report.inputsUnchanged=report.inputs.every(input=>hash(input.file)===input.sha256);
report.pass=report.inputsUnchanged&&report.pairs.every(pair=>pair.same)&&report.rows.every(row=>row.result?.pass&&row.execution.exitCode===0&&!row.execution.error&&!row.execution.signal&&!row.execution.timedOut&&!row.execution.overflow);
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');if(!report.pass)process.exitCode=1;
