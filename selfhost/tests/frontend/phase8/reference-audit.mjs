// Source-level gate for fixture assumptions. This is not the compiler adapter or
// a performance result: it calls the immutable reference's load/check APIs only.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [upstream,selectionFile,output]=process.argv.slice(2);
if(!upstream||!selectionFile||!output)throw Error('Usage: reference-audit.mjs UPSTREAM SELECTION NEW_OUTPUT');
if(fs.existsSync(output))throw Error('Output already exists');
const identify=file=>({file:fs.realpathSync(file),sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const bend=path.join(upstream,'bend2/bend.ts'),base=path.join(upstream,'bend2/base.bend');
const inputs=[identify(bend),identify(base),identify(import.meta.filename),identify(selectionFile)];
const B=await import(pathToFileURL(bend));
const document=JSON.parse(fs.readFileSync(selectionFile,'utf8')),cases=document.cases??document;
const report={kind:'phase8-reference-fixture-assumptions',started:new Date().toISOString(),node:process.version,inputs,scope:'Direct immutable upstream book_load/book_valid only; no CLI verdict, compiler execution, output equivalence or performance claim.',rows:[]};
for(const test of cases){
 const file=path.resolve(path.dirname(selectionFile),test.file),book=B.book_nil();let phase='parse',error=null;
 try{await B.book_load(book,file,'',new Map());if(test.lanes.includes('check')){phase='check';B.book_valid(book);}}
 catch(caught){error=caught;}
 for(const lane of test.lanes){
  const failure=error!==null&&(phase==='parse'||lane==='check');
  const actual={accepted:!failure,phase:failure?phase:lane};
  report.rows.push({id:test.id,lane,input:identify(file),expected:{accepted:test.accept,phase:test.rejectPhase},actual,expectationMatches:actual.accepted===test.accept&&(!failure||actual.phase===test.rejectPhase),diagnostic:failure?(error?.$==='Err'?B.err_show(error):String(error)):null});
 }
}
report.changedInputs=inputs.filter(item=>identify(item.file).sha256!==item.sha256);
report.finished=new Date().toISOString();report.complete=report.changedInputs.length===0;
fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({output,complete:report.complete,observations:report.rows.length,mismatches:report.rows.filter(row=>!row.expectationMatches).map(row=>({id:row.id,lane:row.lane,actual:row.actual,diagnostic:row.diagnostic}))}));
