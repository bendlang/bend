// Instrumented actual emitted Bend entries; counts only, never a timing sample.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [apiArg,outArg]=process.argv.slice(2),api=path.resolve(apiArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const before=identity(api);assert.equal(before.sha256,'ff876a357db2d44d3e1fbd37ab694a16d2fa0f47d60c9d500603e634c8c645f9');
let text=fs.readFileSync(api,'utf8');
const hooks={norm_exact:'function $norm_exact$(_a_0, _b_0) {',norm_exact_head:'function $norm_exact_head$(_a_0, _b_0) {',norm_cmp_quick:'function $norm_cmp_quick$(_a_0, _b_0) {'};
for(const [name,header]of Object.entries(hooks)){assert.equal(text.split(header).length,2);text=text.replace(header,header+`\n  phase11Counts[${JSON.stringify(name)}] = (phase11Counts[${JSON.stringify(name)}] ?? 0) + 1;`+(name==='norm_exact'?'\n  if (_a_0 === phase11A && _b_0 === phase11B) phase11Counts.initialPair = (phase11Counts.initialPair ?? 0) + 1;':''));}
text+='\nlet phase11Counts = {}, phase11A, phase11B;\nexport function observe(a,b) {phase11Counts={};phase11A=a;phase11B=b;const value=run_loop($compare$({$:"Nil"},a,b,false));return {value,counts:phase11Counts};}\n';
const derived=path.join(out,'instrumented.mjs');fs.writeFileSync(derived,text);const K=await import(pathToFileURL(derived));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',kids=[])=>({$:'KTerm',tag,name,id:0,quant:0,kids:list(kids),removed:nil});
const rows=[];for(const depth of [0,4,16,64,256]){
 let a=term('Ctr','Left'),b=term('Ctr','Right');for(let i=0;i<depth;i++){a=term('Ctr','Wrap',[a]);b=term('Ctr','Wrap',[b]);}
 a=term('App','',[term('Ref','opaque'),a]);b=term('App','',[term('Ref','opaque'),b]);
 const result=K.observe(a,b);assert.equal(result.value,false);assert.equal(result.counts.initialPair,2);const input=path.join(out,'input-'+depth+'.json');fs.writeFileSync(input,JSON.stringify({a,b})+'\n');rows.push({depth,input:identity(input),result});
}
assert.deepEqual(identity(api),before);const report={kind:'phase11-duplicate-initial-conversion-counts',scope:'Disposable instrumented view of actual checked B1 derivative. No timing, allocation, checked-component or B1 promotion claim.',inputs:[identity(import.meta.filename),identity(process.execPath),before],instrumented:identity(derived),cpu:2,hooks,rows,pass:true};fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:true,rows:rows.map(({depth,result})=>({depth,...result}))}));
