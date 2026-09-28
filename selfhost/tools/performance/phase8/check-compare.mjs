// Four serial fresh-process observations. Evidence is never relabeled a bootstrap.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt,identity,verifyIdentity,validatedCache} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [attemptArg,outArg,cpu='0',mode='measure']=process.argv.slice(2);
assert.match(cpu,/^\d+$/);assert.ok(['measure','preflight'].includes(mode));
const attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg),m=await verifyAttempt(attempt);
assert.equal(m.artifactKind,'checked-b1');fs.mkdirSync(out);
const bootstrap=JSON.parse(fs.readFileSync(m.bootstrapReport.file)),worker=path.join(out,'worker.mjs');
fs.copyFileSync(new URL('./check-worker.mjs',import.meta.url),worker);
const cache=validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
const paths=[worker,import.meta.filename,process.execPath,bootstrap.source,m.api.file,m.base.file,m.runtime.file,cache.file,...m.snapshot.sources.map(x=>x.frozen.file),...bootstrap.provenance.inputs.map(x=>x.file)];
const inputs=[...new Set(paths)].map(identity);
const report={kind:'phase8-full-source-check-cost',mode,started:new Date().toISOString(),complete:false,attempt:identity(path.join(attempt,'attempt.json')),source:identity(bootstrap.source),cache,inputs,policy:'Fresh processes; TypeScript checks Base; Bend uses its validated disk Base cache. Checking and trust reporting only, no emission.',rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const order=mode==='preflight'?['typescript','bend']:['typescript','bend','bend','typescript'];
 for(const [index,variant] of order.entries()){
  const prefix=path.join(out,String(index)+'-'+variant),workdir=prefix+'-work';fs.mkdirSync(workdir);
  const request={variant,source:bootstrap.source,api:m.api.file,base:m.base.file,runtime:m.runtime.file,upstream:m.config.upstream,adapter:path.join(m.snapshot.root,'tools/conformance/adapters',variant==='bend'?'typed.mjs':'upstream.mjs'),workdir,timeoutMs:600000,inputs};
  fs.writeFileSync(prefix+'.request.json',JSON.stringify(request,null,2)+'\n',{flag:'wx'});
  const execution=await supervise('taskset',['-c',cpu,process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,prefix+'.request.json',prefix+'.result.json'],{directory:prefix+'-process',env:process.env,timeoutMs:600000});
  const row={index,variant,execution,observation:fs.existsSync(prefix+'.result.json')?JSON.parse(fs.readFileSync(prefix+'.result.json')):null};report.rows.push(row);save();requireExecution(execution);assert.equal(row.observation.pass,true);
 }
 for(const item of inputs)verifyIdentity(item);await verifyAttempt(attempt);
 const bad=report.rows.map(r=>[...r.observation.result.unsafeDefinitions].sort());
 report.unsafeDefinitionSetsAgree=bad.every(x=>JSON.stringify(x)===JSON.stringify(bad[0]));
 assert.ok(report.unsafeDefinitionSetsAgree,'Trust-definition sets differ');
 report.complete=true;
 if(mode==='measure'){
  const mean=(rows,f)=>rows.reduce((s,r)=>s+f(r),0)/rows.length;
  report.variants=Object.fromEntries(['typescript','bend'].map(v=>{const rows=report.rows.filter(r=>r.variant===v);return [v,{samples:rows.length,meanRequestMs:mean(rows,r=>r.observation.requestMs),meanProcessWallMs:mean(rows,r=>r.execution.wallMs),maxRssKiB:Math.max(...rows.map(r=>r.observation.maxRssKiB))}]}));
  report.ratios={request:report.variants.bend.meanRequestMs/report.variants.typescript.meanRequestMs,process:report.variants.bend.meanProcessWallMs/report.variants.typescript.meanProcessWallMs};
 }
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
report.finished=new Date().toISOString();save();
