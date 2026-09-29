import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [beforeArg,afterArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const before=await verifyAttempt(path.resolve(beforeArg)),after=await verifyAttempt(path.resolve(afterArg));
async function view(file,name){
  const source=fs.readFileSync(file,'utf8');
  for(const symbol of ['$f_lex$','$f_lex_indexed$','$dg_width$'])assert(source.includes('function '+symbol+'('));
  const target=path.join(out,name+'.mjs');
  fs.writeFileSync(target,source+`
let widthCalls=0;
const originalWidth=$dg_width$;
$dg_width$=function(...xs){widthCalls++;return originalWidth(...xs);};
export const lex=run_lib((...xs)=>run_loop($f_lex$(...xs)),5);
export const lexIndexed=run_lib((...xs)=>run_loop($f_lex_indexed$(...xs)),2);
export const resetWidth=()=>{widthCalls=0;};
export const getWidth=()=>widthCalls;
`);
  const mod=await import(pathToFileURL(target));return {...mod.default,...mod};
}
const B=await view(before.api.file,'baseline'),C=await view(after.api.file,'candidate');
const input=path.resolve('selfhost/build/phase16/parser-controls-input-04/controls.json');
const gapFile=path.resolve('selfhost/build/phase16/wave2-frontend-01/behavior-differences.json');
const inputs=[import.meta.filename,input,gapFile,before.api.file,after.api.file,after.base.file,process.execPath].map(identity);
const cases=JSON.parse(fs.readFileSync(input)).cases.concat([
  {label:'whole-base',source:fs.readFileSync(after.base.file,'utf8')},
  {label:'ascii-words',source:'abc XYZ 12 1e+2 2e-3 a.b _x\n'},
  {label:'quotes-astral',source:'def main() -> String: "a😀b\\n\\u{1F600}"\n'},
  {label:'comments-crlf',source:'# 😀\r\ndef main() -> U32:\r\n\t123 # end😀'},
  {label:'unclosed',source:'def main() -> String: "abc'},
]);
for(const row of JSON.parse(fs.readFileSync(gapFile)).differences.filter(r=>r.lane==='parse')){
  const file=path.join(after.config.upstream,'tests',row.id);inputs.push(identity(file));
  cases.push({label:'partial-'+row.id,source:fs.readFileSync(file,'utf8')});
}
const array=xs=>{const result=[];while(xs.$==='Con'){result.push(xs.head);xs=xs.tail;}assert.equal(xs.$,'Nil');return result;};
const report={complete:false,pass:false,inputs,rows:[],scope:'Copied checked API instrumentation; complete token/tree equality against the parent, no production image edits or timing claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
  for(const {label,source} of cases){
    const row={label,pass:false,indexed:[]};report.rows.push(row);
    B.resetWidth();C.resetWidth();
    assert.deepEqual(array(C.lex(source,1,0,0,{$:'Nil'})),array(B.lex(source,1,0,0,{$:'Nil'})));
    assert.equal(B.getWidth(),0);assert.equal(C.getWidth(),0);
    assert.deepEqual(C.f_parse(source),B.f_parse(source));
    for(const start of [1,4097]){
      B.resetWidth();C.resetWidth();
      const old=array(B.lexIndexed(start,source)),candidate=array(C.lexIndexed(start,source));
      assert.deepEqual(candidate,old);
      const counts={start,before:B.getWidth(),after:C.getWidth(),tokens:old.length};
      assert(counts.after<=counts.before);
      if(label==='ascii-words'){assert(counts.before>0);assert.equal(counts.after,0);}
      row.indexed.push(counts);
      assert.deepEqual(C.f_parse_indexed(start,source),B.f_parse_indexed(start,source));
    }
    row.pass=true;save();
  }
  inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
