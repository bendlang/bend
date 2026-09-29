import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [componentsArg,outArg]=process.argv.slice(2),components=path.resolve(componentsArg),out=path.resolve(outArg);fs.mkdirSync(out);
const baseline=path.join(components,'baseline.mjs'),candidate=path.join(components,'candidate.mjs');
const report={kind:'phase15-lookup-operation-gates',complete:false,pass:false,inputs:[import.meta.filename,process.execPath,baseline,candidate,path.join(components,'report.json'),path.resolve(import.meta.dirname,'speed-controls.mjs'),path.resolve(import.meta.dirname,'../rapid/persistent-index.test.mjs'),path.resolve(import.meta.dirname,'../../compiler-abi.mjs')].map(identity),rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
try{assert.equal(JSON.parse(fs.readFileSync(path.join(components,'report.json'))).pass,true);
for(const[name,args]of [['demand',[path.resolve(import.meta.dirname,'speed-controls.mjs'),baseline,candidate,path.join(out,'demand.json')]],['persistent',[path.resolve(import.meta.dirname,'../rapid/persistent-index.test.mjs'),candidate,baseline]]]){const execution=await supervise('taskset',['-c','3',process.execPath,'--stack-size=4096','--max-old-space-size=4096',...args],{directory:path.join(out,name+'-process'),env:process.env,timeoutMs:90000});report.rows.push({name,execution});save();requireExecution(execution);}
const src=fs.readFileSync(candidate,'utf8'),start=src.indexOf('function $lookup$('),end=src.indexOf('\nfunction ',start+1);assert.ok(start>=0&&end>start);const emitted=src.slice(start,end);assert.ok(emitted.includes('for (;;) switch ($pc)'));assert.ok(!emitted.includes('run_tail('));assert.ok(!emitted.includes('=>'));assert.ok(!emitted.includes('"$JMP"'));report.codegen={loop:true,closures:0,messages:0,body:emitted};report.inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;}catch(e){report.error=e.stack;process.exitCode=1;}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));
