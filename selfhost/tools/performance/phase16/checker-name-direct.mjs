import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
const root=path.resolve(import.meta.dirname,'../../../..');
const out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const apiFiles=['checker-build-04','checker-build-05'].map(n=>path.join(root,'selfhost/build/phase16',n,'equality/api.mjs'));
const ts=path.join(root,'selfhost/.bootstrap/upstream-phase8/bend2/bend.ts');
const controls=path.join(root,'selfhost/build/phase16/checker-name-controls-01/direct.json');
const cases=JSON.parse(fs.readFileSync(controls,'utf8'));
const inputs=[import.meta.filename,process.execPath,ts,controls,...apiFiles,...cases.map(x=>x.file)].map(identity);
const report={kind:'phase16-template-name-direct-controls',complete:false,inputs,rows:[]};
try{
 const B=await import(pathToFileURL(ts)),apis=[];
 for(const file of apiFiles)apis.push((await import(pathToFileURL(file))).default);
 const names=book=>{const out=[];for(let p=book;p.$==='Con';p=p.tail)if(/~\d+$/.test(p.head.name))out.push(p.head.name);return out.sort();};
 for(const c of cases){
  const source=fs.readFileSync(c.file,'utf8'),book=B.book_nil();
  B.parse_book(book,path.dirname(c.file),source,'',{});B.book_valid(book);
  const reference=Object.keys(book.tlds).filter(k=>/~\d+$/.test(k)).sort();
  assert.deepEqual(reference,c.expectedInstances.slice().sort());
  const results=[];
  for(const api of apis){const parsed=api.f_parse(source);assert.equal(parsed.error,'');assert.equal(api.check_book(parsed.book),'');const result=api.specialize_book(parsed.book);assert.equal(api.specialized_error(result),'');results.push(names(api.specialized_book(result)));}
  assert.deepEqual(results[1],reference);
  report.rows.push({name:c.name,reference,baseline:results[0],candidate:results[1],baselineExact:JSON.stringify(results[0])===JSON.stringify(reference),candidateExact:true});
 }
 assert.equal(report.rows.filter(r=>r.baselineExact).length,3);
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
