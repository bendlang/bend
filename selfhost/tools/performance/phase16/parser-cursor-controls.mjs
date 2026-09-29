import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [beforeArg,afterArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));
const before=await verifyAttempt(path.resolve(beforeArg)),after=await verifyAttempt(path.resolve(afterArg));
async function view(file,name){const source=fs.readFileSync(file,'utf8');assert(source.includes('function $f_lex$('));const target=path.join(out,name+'.mjs');fs.writeFileSync(target,source+'\nexport const cursorControls={f_lex:run_lib($f_lex$,5)'+(name==='candidate'?',f_lex_indexed:run_lib($f_lex_indexed$,2)':'')+'};\n');const mod=await import(pathToFileURL(target));return {...mod.default,...mod.cursorControls};}
const B=await view(before.api.file,'baseline'),C=await view(after.api.file,'candidate');
const input=path.resolve('selfhost/build/phase16/parser-controls-input-04/controls.json');
const inputs=[import.meta.filename,input,before.api.file,after.api.file,process.execPath].map(identity);
const cases=JSON.parse(fs.readFileSync(input,'utf8')).cases.concat([
 {label:'cursor-comment-astral',source:'# 😀\ndef main() -> U32:\n  0 # another 😀\n'},
 {label:'cursor-quoted-newline',source:'def main() -> String:\n  "a\nb😀"\n'},
 {label:'cursor-tabs-crlf',source:'\t# hi\r\ndef main() -> U32:\r\n\t0\r\n'},
 {label:'cursor-split',source:'def main() -> A<B<C>>:\n  ++x\n'},
 {label:'cursor-comment-eof',source:'def main() -> U32:\n  0 # EOF😀'},
 {label:'cursor-whitespace-only',source:' \t\n# 😀\n  '},
 {label:'cursor-unclosed-string',source:'def main() -> String:\n "hello'}]);
const report={complete:false,pass:false,inputs,rows:[]};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const array=xs=>{const a=[];while(xs.$==='Con'){a.push(xs.head);xs=xs.tail;}assert.equal(xs.$,'Nil');return a;};
const erase=x=>Array.isArray(x)?x.map(erase):x&&typeof x==='object'?Object.fromEntries(Object.entries(x).filter(([k])=>!['originBegin','originEnd','begin','end','previousEnd'].includes(k)).map(([k,v])=>[k,erase(v)])):x;
try {
 for(const {label,source} of cases){const row={label,pass:false};report.rows.push(row);
  const old=array(B.f_lex(source,1,0,0,{$:'Nil'})),legacy=array(C.f_lex(source,1,0,0,{$:'Nil'}));assert.deepEqual(erase(legacy),old);assert(legacy.every(t=>t.begin===0&&t.end===0&&t.previousEnd===0));
  const rawOld=B.f_parse(source),rawLegacy=C.f_parse(source);assert.deepEqual(erase(rawLegacy),erase(rawOld));
  for(const start of [1,4097]){const tokens=array(C.f_lex_indexed(start,source));const malformed=old.at(-1)?.f_kind===3;const visible=malformed?tokens:tokens.slice(0,-1);assert.deepEqual(erase(visible),old);let previous=start;
   for(const t of tokens){assert(t.begin>=start&&t.end>=t.begin&&t.end<=start+source.length);assert.equal(t.previousEnd,previous);if(t.f_kind===3)continue;
    if(t.text==='<eof>'){assert.equal(t.begin,start+source.length);assert.equal(t.end,t.begin);assert.equal(t.f_line,0);assert.equal(t.f_col,0);continue;}
    const text=({'>>op':'>>','>op':'>','+bind':'+'})[t.text]??t.text;assert.equal(source.slice(t.begin-start,t.end-start),text);if(t.text!=='\n')previous=t.end;
   }
   assert.deepEqual(erase(C.f_parse_indexed(start,source)),erase(rawLegacy));
  }
  row.pass=true;row.tokens=old.length;save();
 }
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;save();
}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
