import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../../../..'),build=path.resolve(process.argv[2]),out=path.resolve(process.argv[3]);fs.mkdirSync(out);
const w=await import(pathToFileURL(path.join(build,'snapshot/tools/development/workflow.mjs'))),m=await w.verifyAttempt(build),cache=w.validatedCache(path.join(m.snapshot.root,'build/typed/cache'),m.api.file,m.base.file);
const controls=path.join(root,'selfhost/build/phase16/checker-key-json-controls-01/direct.json'),cases=JSON.parse(fs.readFileSync(controls)),tsFile=path.join(root,'selfhost/.bootstrap/upstream-phase8/bend2/bend.ts'),hostFile=path.join(m.snapshot.root,'tools/typed-driver.mjs');
Object.assign(process.env,{BEND_TYPED_API:m.api.file,BEND_BASE:m.base.file,BEND_TYPED_RUNTIME:m.runtime.file});
const inputs=[import.meta.filename,controls,m.api.file,m.base.file,cache.file,tsFile,hostFile,...cases.map(c=>c.file),path.join(root,'design/phase16/checker-canonical-memo-json.md')].map(w.identity);
const report={kind:'phase16-canonical-memo-instances',complete:false,inputs,rows:[]};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const a=(await import(pathToFileURL(m.api.file))).default,B=await import(pathToFileURL(tsFile)),host=await import(pathToFileURL(hostFile)),seed={...JSON.parse(fs.readFileSync(cache.file)),sourceText:fs.readFileSync(m.base.file,'utf8')};
 for(const c of cases){
  const row={name:c.name,expected:c.expectedInstances.slice().sort()};report.rows.push(row);
  try{
   const b=B.book_nil();await B.book_load(b,c.file,'',new Map());B.book_valid(b);const predicate=n=>c.prefix?n.startsWith(c.prefix+'~'):/~\d+$/.test(n);row.reference=Object.keys(b.tlds).filter(predicate).sort();assert.deepEqual(row.reference,row.expected);
   const graph=host.discoverSources(a,c.file,{seed}),loaded=a.f_load_graph_seed(graph.main,graph.sources,seed.sourcePath,seed.sourceText,seed.book);assert.equal(loaded.error,'');assert.equal(a.check_book(loaded.book),'');
   const spec=a.specialize_book(loaded.book);assert.equal(a.specialized_error(spec),'');const names=[];for(let p=a.specialized_book(spec);p.$==='Con';p=p.tail)if(predicate(p.head.name))names.push(p.head.name);row.candidate=names.sort();row.exact=JSON.stringify(row.candidate)===JSON.stringify(row.reference);
  }catch(e){row.error=e?.$==='Err'?B.err_show(e):e.stack??String(e);}
  save();
 }
 inputs.forEach(w.verifyIdentity);report.complete=true;report.differences=report.rows.filter(r=>!r.exact).map(r=>r.name);report.pass=report.differences.length===0;if(!report.pass)process.exitCode=1;
}catch(e){report.error=e.stack??String(e);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,differences:report.differences,error:report.error}));
