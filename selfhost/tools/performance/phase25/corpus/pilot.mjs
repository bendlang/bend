// Fixture-development check only, not a benchmark. Every attempted source retained.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const project=path.resolve(import.meta.dirname,'../../../../..');
const upstream=path.join(project,'selfhost/.bootstrap/upstream-phase23');
const B=await import(pathToFileURL(path.join(upstream,'bend2/bend.ts')));
const C=await import(pathToFileURL(path.join(upstream,'bend2/comp.ts')));
const cases=JSON.parse(fs.readFileSync(path.join(import.meta.dirname,'metadata.json'),'utf8'));
const out=path.join(import.meta.dirname,'pilot-evidence',process.argv[2]);
fs.mkdirSync(out,{recursive:true});
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-pilot.mjs'));
fs.copyFileSync(path.join(import.meta.dirname,'metadata.json'),path.join(out,'metadata.json'));
const rows=[];
for(const row of cases){
 const source=path.join(import.meta.dirname,path.basename(row.relativeFile));
 const text=fs.readFileSync(source,'utf8');
 fs.writeFileSync(path.join(out,row.id+'.bend'),text,{flag:'wx'});
 const record={id:row.id,sourceSha256:createHash('sha256').update(text).digest('hex')};
 try{
  const book=B.book_nil();await B.book_load(book,source,'',new Map());B.book_valid(book);
  if(book.hols)throw Error('Holes: '+book.hols);
  const code=C.js_lib(book,true);
  fs.writeFileSync(path.join(out,row.id+'.mjs'),code,{flag:'wx'});
  record.emittedSha256=createHash('sha256').update(code).digest('hex');
  record.pass=true;
 }catch(error){record.pass=false;record.error=error?.$==='Err'?B.err_show(error):String(error);}
 rows.push(record);fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({kind:'upstream-only-fixture-validity',performanceMeasurement:false,rows},null,2)+'\n');
 console.log(row.id,record.pass?'PASS':record.error);
}
if(rows.some(x=>!x.pass))process.exitCode=1;
