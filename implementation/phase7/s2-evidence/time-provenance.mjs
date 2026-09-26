// Serial paired microbenchmark of the three affected public origin routes.
// Run with taskset -c 0 node --stack-size=4096 --expose-gc SCRIPT OLD NEW OUT.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [oldFile,newFile,out]=process.argv.slice(2);
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs=[oldFile,newFile,import.meta.filename,process.execPath].map(identity);
const api=[(await import(pathToFileURL(oldFile))).default,(await import(pathToFileURL(newFile))).default];
const nil={$:'Nil'},list=items=>items.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const text='type Flag is Data:\n  On{}\n  Off{}\n'+Array.from({length:60},(_,i)=>`def item${i}() -> Flag:\n  On{}\n`).join('')+'def missing() -> Flag:\n  Unknown\n';
const sources=list([{$:'FSource',name:'/timing/main.bend',path:'/timing/main.bend',text}]);
const traces=api.map(k=>k.f_load_graph_trace('/timing/main.bend',sources));
assert.deepEqual(traces[0],traces[1]);assert.equal(traces[0].result.error,'');
const workloads={all:i=>api[i].f_load_origins('/timing/main.bend',sources),filtered:i=>api[i].f_load_origins_for('/timing/main.bend',sources,'missing'),trace:i=>api[i].f_loaded_origins_for(traces[i],'missing')};
const report={scope:'Warm in-process public provenance calls on one frozen 61-definition source; no whole-compiler/TS ratio.',inputs,node:process.version,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(l=>l.startsWith('Cpus_allowed_list:')),fixture:{text,sourceSha256:createHash('sha256').update(text).digest('hex')},rows:[],complete:false};
assert.equal(report.affinity.split(':')[1].trim(),'0');
const save=()=>fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n');save();
let sink;
for(const [name,call] of Object.entries(workloads)){
  assert.deepEqual(call(0),call(1),'exact result before timing '+name);
  for(let j=0;j<20;j++){sink=call(0);sink=call(1);}
  const start=performance.now();for(let j=0;j<5;j++)sink=call(0);
  const iterations=Math.max(5,Math.min(2000,Math.ceil(200/((performance.now()-start)/5))));
  const samples=[];
  for(let round=0;round<4;round++)for(const i of round%2?[1,0]:[0,1]){
    global.gc();const cpu=process.cpuUsage(),begin=performance.now();
    for(let j=0;j<iterations;j++)sink=call(i);
    const milliseconds=performance.now()-begin,used=process.cpuUsage(cpu);
    samples.push({round,variant:i?'candidate':'baseline',iterations,milliseconds,perCallMs:milliseconds/iterations,cpuMs:(used.user+used.system)/1000});
  }
  const median=values=>{const s=values.toSorted((a,b)=>a-b);return (s[1]+s[2])/2;};
  const before=median(samples.filter(r=>r.variant==='baseline').map(r=>r.perCallMs)),after=median(samples.filter(r=>r.variant==='candidate').map(r=>r.perCallMs));
  report.rows.push({name,samples,baselineMs:before,candidateMs:after,ratio:after/before,regressionGuardPass:after/before<=1.05});save();
}
assert.ok(sink);for(const item of inputs)assert.deepEqual(identity(item.file),item);
report.complete=true;report.peakProcessRssKiB=process.resourceUsage().maxRSS;report.memoryScope='Both APIs share one process; peak RSS is recorded, not a comparative memory result.';save();
console.log(JSON.stringify({complete:report.complete,rows:report.rows.map(({name,ratio,regressionGuardPass})=>({name,ratio,regressionGuardPass}))}));
