// Read-only datatype checkpoint census; mismatches are preserved observations.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [attemptArg,outArg]=process.argv.slice(2);
const attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const w=await import(pathToFileURL(path.join(attempt,'snapshot/tools/development/workflow.mjs')));
const m=await w.verifyAttempt(attempt),a=(await import(pathToFileURL(m.api.file))).default;
const pin=path.resolve('selfhost/.bootstrap/upstream-phase8/bend2/bend.ts');
const B=await import(pathToFileURL(pin));
const head='type T is Data:\n',ctor='  C{}\n';
const cases=[
 ['indented',head+ctor],['unindented',head+'C{}\n'],['same-line','type T is Data: C{}\n'],
 ['empty-eof',head],['next-def',head+ctor+'def main() -> Type: Type\n'],
 ['next-type',head+ctor+'type U is Data:\n  D{}\n'],['next-law',head+ctor+'law proof: Type\n'],
 ['next-decorator',head+ctor+'@unsafe\ndef main() -> Type: Type\n'],
 ['import-after-type',head+ctor+'import Base\n'],['import-no-constructors',head+'import Base\n'],
 ['indented-import',head+ctor+'  import Base\n'],['reserved-import-braces',head+'  import{}\n'],
 ['reserved-return',head+ctor+'return\n'],['reserved-return-braces',head+'  return{}\n'],
 ['reserved-Type',head+ctor+'Type\n'],['reserved-for',head+ctor+'for\n'],
 ['name-no-brace',head+ctor+'D\n'],['name-wrong-brace',head+ctor+'D()\n'],
 ['invalid-dotted-name',head+'  C..D{}\n'],['punctuation',head+ctor+')\n'],
 ['duplicate-constructor',head+ctor+'  C{}\n'],['comment-unindented',head+'# astral 😀\nC{}\n']
].map(([name,source])=>({name,source}));
fs.writeFileSync(path.join(out,'cases.json'),JSON.stringify(cases,null,2)+'\n');
const inputs=[import.meta.filename,pin,m.api.file,path.join(attempt,'attempt.json'),path.join(out,'cases.json')].map(w.identity);
const report={kind:'phase20-readonly-type-checkpoint-census',complete:false,conformanceClaim:false,api:m.api,inputs,rows:[]};
const list=xs=>{const r=[];for(let p=xs;p.$==='Con';p=p.tail)r.push(p.head);return r;};
for(const c of cases){
 let expected='',book=B.book_nil();
 try{B.parse_book(book,'',c.source,'',{});}catch(e){assert.equal(e.$,'Err',String(e.stack??e));expected=B.err_show(e);}
 const candidate=a.f_parse(c.source),error=candidate.error;
 const row={...c,expected,candidate:error,referenceAccept:!expected,candidateAccept:!error,exact:expected===error};
 if(!expected&&!error){row.referenceConstructors=Object.keys(book.ctrs);row.candidateBook=candidate.book;}
 report.rows.push(row);
}
inputs.forEach(w.verifyIdentity);await w.verifyAttempt(attempt);
report.complete=true;report.count=report.rows.length;report.exact=report.rows.filter(x=>x.exact).length;
report.acceptanceDifferences=report.rows.filter(x=>x.referenceAccept!==x.candidateAccept).map(x=>x.name);
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({complete:report.complete,count:report.count,exact:report.exact,acceptanceDifferences:report.acceptanceDifferences}));
