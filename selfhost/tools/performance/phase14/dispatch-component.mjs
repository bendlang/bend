import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [manifestArg,outArg]=process.argv.slice(2),out=path.resolve(outArg),m=JSON.parse(fs.readFileSync(manifestArg));
assert.equal(process.version,'v24.18.0');fs.mkdirSync(out);
const upstream=path.resolve('selfhost/.bootstrap/upstream-phase8'),modules=['term','index','normalize','graph'].map(x=>'src/core/'+x+'.bend');
const roots=['norm_eval_node','norm_eval','wnf','kt','atom','app','ann','kid','missing'];
const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];Object.assign(env,{BEND_UPSTREAM:upstream,BEND_BASE:path.join(upstream,'bend2/base.bend')});
const report={kind:'phase14-normalizer-checked-component-codegen',complete:false,pass:false,scope:'Upstream checked selected components, not checked B1 or timed samples.',cpu:'3',inputs:[identity(import.meta.filename),identity(process.execPath),identity(manifestArg),...['bend.ts','comp.ts','base.bend'].map(x=>identity(path.join(upstream,'bend2',x)))],variants:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
try{
 for(const [name,project] of [['baseline',m.baselineSourceRoot],['candidate',path.dirname(path.dirname(path.dirname(m.modified.file)))]] ){
  const source=path.join(out,name+'.bend'),api=path.join(out,name+'.mjs');const {assemble}=await import(pathToFileURL(path.join(project,'tools/assemble.mjs')));assemble(modules,source,{root:project});
  report.inputs.push(identity(source),...modules.map(x=>identity(path.join(project,x))),identity(path.join(project,'tools/assemble.mjs')),identity(path.join(project,'tools/stage0-library.mjs')));save();
  const row={name,source:identity(source)};report.variants.push(row);
  row.execution=await supervise('taskset',['-c','3',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(project,'tools/stage0-library.mjs'),source,api,...roots],{directory:path.join(out,name+'-build'),env,timeoutMs:90000});save();requireExecution(row.execution);
  row.api=identity(api);save();
 }
 report.inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));
