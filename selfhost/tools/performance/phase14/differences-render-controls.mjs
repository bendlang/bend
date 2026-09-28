import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [attemptArg,outputArg]=process.argv.slice(2),out=path.resolve(outputArg);
fs.mkdirSync(out);
const attempt=await verifyAttempt(path.resolve(attemptArg));
const upstream=path.join(attempt.config.upstream,'bend2/bend.ts');
const K=(await import(pathToFileURL(attempt.api.file))).default,U=await import(pathToFileURL(upstream));
const inputs=[import.meta.filename,attempt.api.file,upstream,process.execPath].map(identity);
const report={kind:'phase14-checker-span-render-controls',complete:false,pass:false,inputs,scope:'Public diagnostic_render of genuine checked B1 derivative versus pinned err_show; synthetic DSpan inputs do not claim parser origin coverage.',rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const nil={$:'Nil'},trail={$:'Con',head:{$:'KTerm',tag:'Witness',name:'',id:0,quant:0,kids:nil,removed:nil},tail:nil};
const cases=[
 ['none',null,0,0],['empty','',0,0],['ascii','hello',1,4],['zero','hello',2,2],['line-end','hello',5,5],['reversed','hello',4,1],['first-newline','first\nsecond\nthird',2,12],['second-line','first\nsecond\nthird',7,10],['last-line','first\nsecond\nthird',14,18],['trailing-newline','one\n',4,4],['blank-line','one\n\nthree',4,4],['tabs','\t x\tfoo',4,7],['two-tabs','a\t\tx',3,4],['supplementary-before','a😀b',3,4],['supplementary-selected','a😀b',1,3],['supplementary-split','a😀b',2,3],['surrogate-high','a\ud800b',2,3],['surrogate-low','a\udc00b',1,2],['multi-digit-lines','\n'.repeat(9)+'abcd\nlast',10,12],['huge-end','short',2,100],['crlf','first\r\nsecond\r\n',8,100],['no-name',null,0,0,''],['note','a\nb\nc',2,3,'main','Note: exact.'],['message-only','alpha',0,2,'main','',false]
];
try{
 for(const [label,source,begin,end,name='main',note='',observed=true] of cases){
  const span=source===null?{$:'DNoSpan'}:{$:'DSpan',source,begin,end};
  const diagnostic={$:'DDiagnostic',expected:{$:'DText',text:'expected'},observed:{$:'DText',text:'observed'},has_observed:observed,context:nil,definition:name,span,note,trail};
  const got=K.diagnostic_render({$:'DResult',error:'nonempty',book:nil,diagnostic});
  const err=U.Err(U.book_nil(),{$:'Emp'},'expected',observed?'observed':undefined,source===null?undefined:{file:{str:source,ns:'',al:{}},beg:begin,end},name||undefined,note||undefined);
  const expected=U.err_show(err);report.rows.push({label,source,begin,end,expected,got,pass:got===expected});save();
 }
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(r=>r.pass);save();assert.equal(report.pass,true);
}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}
console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:report.rows.length,failed:report.rows.filter(r=>!r.pass).map(r=>r.label)}));
