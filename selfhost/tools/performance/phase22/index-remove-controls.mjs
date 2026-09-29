import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {isDeepStrictEqual as equal} from 'node:util';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [parentArg,candidateArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const extension='\nexport const __phase22Probe={remove:(a,b)=>run_loop($index_remove$(a,b)),put:(a,b)=>run_loop($book_put$(a,b)),cached:(a,b)=>run_loop($book_cached$(a,b)),hash:a=>run_loop($index_hash$(a,2166136261)),lookup:(a,b)=>run_loop($lookup$(a,b)),final:(a,b)=>run_loop($book_final_legacy$(a,b))};\n';
const inputs=[import.meta.filename,path.join(import.meta.dirname,'index-remove-controls-worker.mjs'),path.join(import.meta.dirname,'index-remove-controls-cases.json')].map(identity);
for(const x of inputs)fs.copyFileSync(x.file,path.join(out,path.basename(x.file)));
const report={kind:'phase22-index-remove-direct-paired',complete:false,pass:false,inputs,extension,scope:'Appended internal raw helper probes, original API prefixes unchanged; independent valid filter oracle and getter/error order; finite raw caller/stack histories.',lanes:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{for(const [label,arg]of [['parent',parentArg],['candidate',candidateArg]]){
  const attempt=fs.realpathSync(arg),manifestFile=path.join(attempt,'attempt.json'),a=JSON.parse(fs.readFileSync(manifestFile));
  const verifier=path.join(a.snapshot.root,'tools/development/workflow.mjs');const {verifyAttempt}=await import(pathToFileURL(verifier));await verifyAttempt(attempt);
  if(label==='parent')assert.equal(a.api.sha256,'44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0');
  const original=fs.readFileSync(a.api.file),probe=path.join(out,label+'-probe.mjs');fs.writeFileSync(probe,Buffer.concat([original,Buffer.from(extension)]),{flag:'wx'});
  assert.ok(fs.readFileSync(probe).subarray(0,original.length).equals(original));
  const result=path.join(out,label+'-result.json'),lane={label,attempt:identity(manifestFile),api:identity(a.api.file),probe:identity(probe),prefixBytes:original.length,unchangedPrefix:true,verifier:identity(verifier)};report.lanes.push(lane);save();
  lane.execution=await supervise('taskset',['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(out,'index-remove-controls-worker.mjs'),probe,path.join(out,'index-remove-controls-cases.json'),result],{directory:path.join(out,label+'-process'),env:process.env,timeoutMs:180000});
  requireExecution(lane.execution);lane.result=identity(result);lane.observations=JSON.parse(fs.readFileSync(result));assert.ok(lane.observations.complete&&lane.observations.pass);verifyIdentity(lane.probe);await verifyAttempt(attempt);save();
}
const a=report.lanes[0].observations.rows,b=report.lanes[1].observations.rows;assert.equal(a.length,b.length);
report.comparisons=a.map((x,i)=>{assert.equal(x.name,b[i].name);const improvement=x.category==='stack'&&x.actual.kind==='throw'&&b[i].actual.kind==='return'&&equal(b[i].actual,b[i].expected);return {name:x.name,category:x.category,exact:equal(x.actual,b[i].actual),stackImprovement:improvement,pass:equal(x.actual,b[i].actual)||improvement};});
inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.comparisons.every(x=>x.pass);
}catch(e){report.error={name:e.name,message:e.message,stack:e.stack};}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.comparisons?.length,error:report.error}));process.exitCode=report.pass?0:1;
