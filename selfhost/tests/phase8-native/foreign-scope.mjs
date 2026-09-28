// Preserve an upstream/candidate source-emission comparison, before and after
// separating reachable foreign definitions from identifier-resolution context.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const project=path.resolve(import.meta.dirname,'../..'),upstream=path.join(project,'.bootstrap/upstream-phase8');
const output=path.resolve(process.argv[2]);fs.mkdirSync(output,{recursive:false});
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const fixture=path.join(import.meta.dirname,'fixtures/unused_namespace.bend');
const candidate=path.resolve(process.env.BEND_PHASE8_PROJECT);
const inputs=[fixture,...['tags_left.bend','tags_right.bend','tags.c','tags.js'].map(n=>path.join(import.meta.dirname,'fixtures',n)),...['bend.ts','comp.ts','base.bend'].map(n=>path.join(upstream,'bend2',n)),path.join(candidate,'tools/typed-driver.mjs'),process.env.BEND_TYPED_API,process.env.BEND_BASE];
const report={kind:'phase8-foreign-reachable-namespace-probe',started:new Date().toISOString(),node:process.version,inputs:inputs.map(file=>({file,sha256:sha(file)})),complete:false};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');save();
for(const name of ['unused_namespace.bend','tags_left.bend','tags_right.bend','tags.c','tags.js'])fs.copyFileSync(path.join(import.meta.dirname,'fixtures',name),path.join(output,name));
const B=await import(pathToFileURL(path.join(upstream,'bend2/bend.ts'))),C=await import(pathToFileURL(path.join(upstream,'bend2/comp.ts')));
try{const book=B.book_nil();await B.book_load(book,fixture,'',new Map());B.book_valid(book);if(book.hols!==0)throw Error('Unresolved holes');const source=C.compile_book(book),file=path.join(output,'reference.c');fs.writeFileSync(file,source);report.reference={status:'ok',source:{file,sha256:sha(file)}};}catch(error){report.reference={status:'error',diagnostic:String(error.stack||error)};}save();
const driver=await import(pathToFileURL(path.join(candidate,'tools/typed-driver.mjs')));
const result=await driver.inspect(fixture,{mode:'native'});
if(result.code){const file=path.join(output,'candidate.c');fs.writeFileSync(file,result.code);result.source={file,sha256:sha(file)};delete result.code;}
report.candidate=result;report.divergence=report.reference.status==='ok'&&result.status==='error'&&/two namespaces/.test(result.diagnostic);report.complete=true;report.finished=new Date().toISOString();save();console.log(JSON.stringify({output,reference:report.reference.status,candidate:result.status,divergence:report.divergence}));
