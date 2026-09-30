import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [planFile,resultFile,role]=process.argv.slice(2),p=JSON.parse(fs.readFileSync(planFile));
assert.ok(['baseline','compact'].includes(role));
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:hash(fs.readFileSync(file)),bytes:fs.statSync(file).size});
const verify=()=>{for(const x of p.inputs)assert.equal(identity(x.file).sha256,x.sha256,x.file)};
const report={kind:p.kind,complete:false,pass:false,role,plan:identity(planFile),rows:[],node:process.version,args:process.execArgv};
const save=()=>fs.writeFileSync(resultFile,JSON.stringify(report,null,2)+'\n');
const observe=result=>{const {code,...observation}=result;return {observation,output:typeof code==='string'?{sha256:hash(code),bytes:Buffer.byteLength(code)}:null}};
save();
try{
 verify();const v=p.baseline;
 process.env.BEND_TYPED_API=v.api.file;process.env.BEND_TYPED_RUNTIME=v.runtime.file;process.env.BEND_BASE=v.base.file;
 const D=await import(pathToFileURL(v.driver.file)),original=await D.loadApi();
 for(const c of p.cases){
  let file=c.source?.file;
  if(c.text){file=c.path;fs.writeFileSync(file,fs.readFileSync(c.text.file));fs.writeFileSync(path.join(path.dirname(file),'dep.bend'),c.dependency)}
  let book=null,value=null;const stats={calls:0,computations:0,reused:0};
  const selected=role==='compact'?{...original,j_stops:argument=>{
   stats.calls++;
   if(stats.calls===1){book=argument;value=original.j_stops(argument);stats.computations++;return value}
   assert.equal(stats.calls,2,'Only the known second stop call may be reused');
   assert.equal(argument,book,'Stop-set reuse requires identical context book');stats.reused++;return value;
  }}:original;
  const started=performance.now(),actual=observe(await D.inspect(file,{mode:'library',api:selected})),requestMs=performance.now()-started;
  if(role==='compact')assert.equal(stats.calls,actual.observation.status==='ok'?2:0,'Expected stop-set entry phase');
  report.rows.push({id:c.id,role,source:identity(file),...actual,requestMs,stops:role==='compact'?stats:null,maxRssKiB:process.resourceUsage().maxRSS});save();
 }
 verify();report.complete=true;report.pass=true;
}catch(error){report.error=String(error?.stack??error);process.exitCode=1}
report.maxRssKiB=process.resourceUsage().maxRSS;save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
