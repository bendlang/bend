// Isolated compiler controls for one reviewed generated API. No source rewriting.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const [requestFile,resultFile]=process.argv.slice(2),request=JSON.parse(fs.readFileSync(requestFile));
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const verify=()=>{for(const x of request.inputs)assert.equal(hash(x.file),x.sha256,'Changed input: '+x.file)};
verify();
for(const name of Object.keys(process.env))if(name.startsWith('BEND_')||name==='NODE_OPTIONS')delete process.env[name];
Object.assign(process.env,{BEND_TYPED_API:request.api,BEND_TYPED_RUNTIME:request.runtime,BEND_BASE:request.base,BEND_TYPED_TRACE:''});
const driver=await import(pathToFileURL(request.driver));
const report={variant:request.variant,complete:false,pass:false,node:process.version,rows:[]};
const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n');save();
try{
 await driver.prepareBase();
 const inspector=await driver.createPersistentInspector();
 for(const [index,test]of request.cases.entries()){
  const work=path.join(request.workdir,String(index));fs.mkdirSync(work);
  const begin=performance.now();let result;
  if(test.lane==='check')result=await inspector.inspect(test.file,{mode:'check',timeoutMs:30000});
  else{
   const compiled=await driver.inspect(test.file,{mode:'compile',timeoutMs:30000});
   if(compiled.status!=='ok')result=compiled;
   else{
    const file=path.join(work,'program.mjs');fs.writeFileSync(file,compiled.code);
    const child=spawnSync(process.execPath,['--stack-size=4096','--max-old-space-size=4096',file],{cwd:work,timeout:30000,encoding:'utf8',maxBuffer:2**20});
    fs.writeFileSync(path.join(work,'stdout'),child.stdout??'');fs.writeFileSync(path.join(work,'stderr'),child.stderr??'');
    result={status:child.status===0?'ok':'error',phase:'runtime',checked:true,typeAccepted:true,exitCode:child.status,signal:child.signal,error:child.error?.message??null,stdout:child.stdout??'',stderr:child.stderr??'',emittedSha256:hash(file)};
   }
  }
  const accepted=result.typeAccepted===true;
  const pass=test.lane==='js'?result.status==='ok'&&result.stdout===test.expected:accepted===test.accept&&(!test.rejectPhase||result.phase===test.rejectPhase);
  report.rows.push({id:test.id,lane:test.lane,pass,requestMs:performance.now()-begin,result});save();
 }
 verify();report.complete=true;report.pass=report.rows.every(x=>x.pass);
}catch(error){report.error=String(error.stack??error)}
report.maxRssKiB=process.resourceUsage().maxRSS;save();assert.equal(report.pass,true,'Selected compiler controls failed');
