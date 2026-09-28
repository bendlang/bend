import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {verifyAttempt,identity,verifyIdentity,validatedCache} from '../../tools/development/workflow.mjs';
import {supervise,requireExecution} from '../../tools/development/process.mjs';
const [attemptArg,outArg]=process.argv.slice(2),attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg);fs.mkdirSync(out);
const m=await verifyAttempt(attempt),boot=JSON.parse(fs.readFileSync(m.bootstrapReport.file));
const worker=path.join(out,'worker.mjs');fs.copyFileSync(new URL('../../tools/performance/phase8/check-worker.mjs',import.meta.url),worker);
const files=[fileURLToPath(import.meta.url),worker,process.execPath,boot.source,path.join(attempt,'attempt.json'),m.api.file,m.base.file,m.runtime.file,m.bootstrapReport.file,...m.artifacts.map(x=>x.file),...m.snapshot.sources.map(x=>x.frozen.file)];
files.push(validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file).file);
for(const f of ['bend.ts','comp.ts','main.ts','base.bend'])files.push(path.join(m.config.upstream,'bend2',f));
const inputs=[...new Set(files)].map(identity),report={kind:'phase9-compact-nat-full-source-preflight',scope:'Concurrent correctness preflight, not a controlled speed comparison; ordinary checking and unsafe trust reporting, no emission',started:new Date().toISOString(),complete:false,pass:false,source:identity(boot.source),inputs,rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(const variant of ['typescript','candidate']){
  inputs.forEach(verifyIdentity);const workdir=path.join(out,variant+'-work');fs.mkdirSync(workdir);
  const request={variant,source:boot.source,api:m.api.file,base:m.base.file,runtime:m.runtime.file,upstream:m.config.upstream,workdir,timeoutMs:285000,adapter:path.join(m.snapshot.root,'tools/conformance/adapters',variant==='typescript'?'upstream.mjs':'typed.mjs'),inputs};
  const q=path.join(out,variant+'.request.json'),o=path.join(out,variant+'.result.json');fs.writeFileSync(q,JSON.stringify(request,null,2)+'\n');
  const execution=await supervise('taskset',['-c','3',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,q,o],{directory:path.join(out,variant+'-process'),env:process.env,timeoutMs:285000});
  const observation=fs.existsSync(o)?JSON.parse(fs.readFileSync(o)):null;report.rows.push({variant,execution,observation});save();requireExecution(execution);if(!observation?.pass)throw Error('Type/trust preflight failed');
 }
 report.unsafeDefinitionSetsAgree=JSON.stringify([...report.rows[0].observation.result.unsafeDefinitions].sort())===JSON.stringify([...report.rows[1].observation.result.unsafeDefinitions].sort());
 if(!report.unsafeDefinitionSetsAgree)throw Error('Unsafe definition set differs');
 inputs.forEach(verifyIdentity);await verifyAttempt(attempt);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1;}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));
