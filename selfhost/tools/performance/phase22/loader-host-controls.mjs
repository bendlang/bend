import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [sourceArg,outArg]=process.argv.slice(2),source=fs.realpathSync(sourceArg),out=path.resolve(outArg);fs.mkdirSync(out);
const inputs=[import.meta.filename,path.join(import.meta.dirname,'loader-host-controls-worker.mjs'),path.join(import.meta.dirname,'loader-host-mock-api.mjs'),path.join(source,'manifest.json'),path.join(source,'project/tools/typed-driver.mjs')].map(identity);
for(const n of ['loader-host-controls-worker.mjs','loader-host-mock-api.mjs'])fs.copyFileSync(path.join(import.meta.dirname,n),path.join(out,n));
const fixtures=path.join(out,'fixtures');fs.mkdirSync(fixtures);
const files={'base.bend':'# mock Base\n','leaf.bend':'# mock valid\n','absolute.bend':'# mock valid\n','later.bend':'# mock valid\n','reject.bend':'# mock-reject\n','main.bend':'# mock-import ./leaf.bend A\n# mock-import ./leaf-link.bend B\n','reject-main.bend':'# mock-import ./reject.bend R\n# mock-import ./missing.bend Missing\n','checkup.bend':`import Base\nimport ./leaf.bend as L\nnot valid parent body !!!\n  import ./leaf.bend as Repeat\nimport ./leaf.bend as L # ignored trailing comment\nimport ./leaf.bend as 9invalid\nimport ./leaf.bend\nimport ./leaf.bend as α\nimport ./reject.bend as Fail\nimport ${path.join(fixtures,'absolute.bend')} as Absolute\n\timport ./later.bend as Later  \n`};
for(const [name,text]of Object.entries(files))fs.writeFileSync(path.join(fixtures,name),text,{flag:'wx'});fs.symlinkSync('leaf.bend',path.join(fixtures,'leaf-link.bend'));
inputs.push(...Object.keys(files).map(n=>identity(path.join(fixtures,n))),identity(path.join(out,'loader-host-controls-worker.mjs')),identity(path.join(out,'loader-host-mock-api.mjs')));
const report={kind:'phase22-loader-host-protocol-probe',complete:false,pass:false,inputs,fixtureSymlink:{path:path.join(fixtures,'leaf-link.bend'),target:'leaf.bend'},scope:'Host-only mocks; no compiler build/execution/performance claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 report.syntax=await supervise(process.execPath,['--check',path.join(source,'project/tools/typed-driver.mjs')],{directory:path.join(out,'syntax'),timeoutMs:30000,env:process.env});requireExecution(report.syntax);
 const result=path.join(out,'result.json');report.execution=await supervise('taskset',['-c','0',process.execPath,path.join(out,'loader-host-controls-worker.mjs'),path.join(source,'project/tools/typed-driver.mjs'),path.join(out,'loader-host-mock-api.mjs'),fixtures,result],{directory:path.join(out,'process'),timeoutMs:60000,env:process.env});requireExecution(report.execution);
 const r=JSON.parse(fs.readFileSync(result));assert.ok(r.complete&&r.pass);report.result=identity(result);inputs.forEach(verifyIdentity);report.complete=report.pass=true;
}catch(e){report.error={name:e.name,message:e.message,stack:e.stack};}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));process.exitCode=report.pass?0:1;
