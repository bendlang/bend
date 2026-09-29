import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [baselineArg,candidateArg,controlsArg,outputArg]=process.argv.slice(2),out=path.resolve(outputArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));
const baseline=await verifyAttempt(path.resolve(baselineArg)),candidate=await verifyAttempt(path.resolve(candidateArg));
assert.equal(baseline.config.upstream,candidate.config.upstream);
const upstream=path.join(candidate.config.upstream,'bend2/bend.ts');
const B=(await import(pathToFileURL(baseline.api.file))).default,C=(await import(pathToFileURL(candidate.api.file))).default,U=await import(pathToFileURL(upstream));
const inputs=[import.meta.filename,baseline.api.file,candidate.api.file,upstream,controlsArg,process.execPath].map(identity);
const report={kind:'phase16-public-parser-controls',complete:false,pass:false,inputs,scope:'Public f_parse versus unchanged pinned parse_book. Exact complete diagnostics, acceptance and baseline successful book/import equality; inherited gaps remain explicit.',rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
  for(const {label,source,requireExact=false} of JSON.parse(fs.readFileSync(controlsArg,'utf8')).cases){
    const before=B.f_parse(source),after=C.f_parse(source);let reference='';
    try{U.parse_book(U.book_nil(),'',source,'',{});}catch(e){reference=U.err_show(e);}
    const row={label,source,requireExact,baseline:before.error,candidate:after.error,reference,exactReference:after.error===reference,baselineExact:before.error===reference,acceptedByBaseline:before.error==='',acceptedByCandidate:after.error==='',acceptedByReference:reference==='',bookImportsUnchanged:false};
    try{assert.deepEqual({...after,error:''},{...before,error:''});row.bookImportsUnchanged=true;}catch(e){row.bookError=String(e);}
    row.pass=row.acceptedByCandidate===row.acceptedByReference&&row.acceptedByCandidate===row.acceptedByBaseline&&(!row.baselineExact||row.exactReference)&&(!requireExact||row.exactReference)&&row.bookImportsUnchanged;
    report.rows.push(row);save();
  }
  inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(r=>r.pass);report.exactReferenceCount=report.rows.filter(r=>r.exactReference).length;save();assert.equal(report.pass,true);
}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}
console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:report.rows.length,exactReferenceCount:report.exactReferenceCount,failed:report.rows.filter(r=>!r.pass).map(r=>r.label),remainingDifferences:report.rows.filter(r=>!r.exactReference).map(r=>r.label)}));
