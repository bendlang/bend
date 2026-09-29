import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [beforeArg,afterArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const B=await verifyAttempt(path.resolve(beforeArg)),C=await verifyAttempt(path.resolve(afterArg));
const inputs=[import.meta.filename,B.api.file,C.api.file,process.execPath].map(identity);
const cases=[];
for(const name of ['checker-name-controls-01','checker-key-controls-03']){
 const file=path.resolve('selfhost/build/phase16',name,'direct.json');inputs.push(identity(file));
 cases.push(...JSON.parse(fs.readFileSync(file)));
}
const apis=[(await import(pathToFileURL(B.api.file))).default,(await import(pathToFileURL(C.api.file))).default];
const report={complete:false,pass:false,inputs,rows:[],scope:'Complete parsed and specialized books/errors must equal the unchanged parent; retained TS memo-identity differences are not claimed fixed.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const digest=x=>{const s=JSON.stringify(x);return{bytes:Buffer.byteLength(s),sha256:createHash('sha256').update(s).digest('hex')};};
try{
 for(const c of cases){
  inputs.push(identity(c.file));const text=fs.readFileSync(c.file,'utf8');const rows=[];
  for(const api of apis){
   const p=api.f_load_graph(c.file,{$:'Con',head:{$:'FSource',name:c.file,path:c.file,text},tail:{$:'Nil'}});
   assert.equal(p.error,'');assert.equal(api.check_book(p.book),'');
   rows.push({parsed:digest(p),specialized:digest(api.specialize_book(p.book))});
  }
  assert.deepEqual(rows[1],rows[0]);report.rows.push({name:c.name,pass:true,...rows[1]});save();
 }
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
