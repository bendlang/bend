#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const [candidateArg,parentArg,selectionArg,outArg]=process.argv.slice(2),candidate=path.resolve(candidateArg),parent=path.resolve(parentArg),selectionFile=path.resolve(selectionArg),out=path.resolve(outArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:path.resolve(file),sha256:sha(fs.readFileSync(file))});
const report={kind:'phase17-raw-group-lowered-book-boundary',started:new Date().toISOString(),complete:false,pass:false,inputs:[identity(import.meta.filename),identity(selectionFile)],controls:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const test=async(name,fn)=>{try{report.controls.push({name,pass:true,evidence:await fn()});}catch(e){report.controls.push({name,pass:false,error:String(e.stack??e)});}save();};
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'}),located=(name,file,text,begin)=>({$:'FLocatedSource',source:{$:'FSource',name,path:file,text},begin,end:begin+text.length+1});
const census=root=>{let nodes=0;const groups=[],stack=[root];while(stack.length){const x=stack.pop();if(!x||typeof x!=='object')continue;nodes++;if(x.tag==='FGroup'){assert.equal(x.kids.$,'Con');assert.equal(x.kids.tail.$,'Nil');groups.push({begin:x.originBegin,end:x.originEnd,childTag:x.kids.head.tag,childBegin:x.kids.head.originBegin,childEnd:x.kids.head.originEnd});}for(const y of Object.values(x))if(y&&typeof y==='object')stack.push(y);}return{nodes,groups};};
const firstDifference=(a,b)=>{const queue=[{a,b,path:'$'}];while(queue.length){const x=queue.pop();if(x.a===x.b)continue;if(!x.a||!x.b||typeof x.a!=='object'||typeof x.b!=='object')return{path:x.path,parent:x.a,candidate:x.b};const ak=Object.keys(x.a),bk=Object.keys(x.b);if(JSON.stringify(ak)!==JSON.stringify(bk))return{path:x.path,parentKeys:ak,candidateKeys:bk};for(const k of ak)queue.push({a:x.a[k],b:x.b[k],path:x.path+'.'+k});}return null;};
try{
 const attempts=await Promise.all([candidate,parent].map(async dir=>{const a=JSON.parse(fs.readFileSync(path.join(dir,'attempt.json'))),W=await import(pathToFileURL(path.join(a.snapshot.root,'tools/development/workflow.mjs')));await W.verifyAttempt(dir);report.inputs.push(identity(path.join(dir,'attempt.json')),identity(a.api.file));return{a,W,K:(await import(pathToFileURL(a.api.file))).default,dir};}));
 const [current,old]=attempts,baseFile=current.a.base.file,baseText=fs.readFileSync(baseFile,'utf8');report.inputs.push(identity(baseFile));assert.equal(baseText,fs.readFileSync(old.a.base.file,'utf8'));
 const base=located('Base',baseFile,baseText,1),loaded=attempts.map(x=>x.K.f_load_graph('Base',list([base])));for(const b of loaded)assert.equal(b.error,'');
 await test('Base raw projection is byte-identical and has no FGroup',()=>{const a=old.K.f_parse_indexed(1,baseText),b=current.K.f_parse_indexed(1,baseText);assert.deepEqual(b,a);assert.equal(census(b).groups.length,0);return{sha256:sha(JSON.stringify(b)),...census(b)};});
 await test('Base lowered book is byte-identical and has no FGroup',()=>{assert.deepEqual(loaded[0].book,loaded[1].book);assert.equal(census(loaded[0].book).groups.length,0);return{sha256:sha(JSON.stringify(loaded[0].book))};});
 const files=[...new Map(JSON.parse(fs.readFileSync(selectionFile)).cases.map(x=>[x.file,x])).values()];
 for(const row of files){const file=path.resolve(row.file),text=fs.readFileSync(file,'utf8'),name=path.basename(file,'.bend'),begin=base.end;report.inputs.push(identity(file));
  const a=old.K.f_parse_indexed(begin,text),b=current.K.f_parse_indexed(begin,text),ac=census(a),bc=census(b);
  fs.writeFileSync(path.join(out,name+'-raw.json'),JSON.stringify({parent:a,candidate:b,census:{parent:ac,candidate:bc}},null,2)+'\n');
  await test('raw wrapper invariant '+name,()=>{assert.equal(ac.groups.length,0);for(const g of bc.groups){assert(['Local','Parallel','Match'].includes(g.childTag));assert(g.begin>0&&g.end>=g.begin);assert(g.childBegin>0&&g.childEnd>=g.childBegin);}if(['local','nested-local','parallel','nested-parallel','local-argument','local-lambda-body','local-namespace','nested-local-namespace','local-annotated','local-type'].includes(name))assert(bc.groups.length>0);if(['scalar-literal','nested-scalar','scalar-tuple','nested-tuple','grouped-scalar-lambda','group-type','family-arg','bound-pattern','bound-marked'].includes(name)){assert.equal(bc.groups.length,0);assert.deepEqual(b,a);}return{parent:ac,candidate:bc,parentRawSha256:sha(JSON.stringify(a)),candidateRawSha256:sha(JSON.stringify(b))};});
  const sources=list([located('main',file,text,begin),base]),books=attempts.map((x,i)=>x.K.f_load_graph_seed('main',sources,baseFile,baseText,loaded[i].book));
  await test('no marker escapes lowering '+name,()=>{for(const x of books)if(!x.error)assert.equal(census(x.book).groups.length,0);return{parentError:books[1].error,candidateError:books[0].error,parentBookSha256:sha(JSON.stringify(books[1].book)),candidateBookSha256:sha(JSON.stringify(books[0].book))};});
  if(!books[0].error&&!books[1].error)await test('complete successful lowered book equality '+name,()=>{const diff=firstDifference(books[1].book,books[0].book);if(diff)fs.writeFileSync(path.join(out,name+'-lowered-difference.json'),JSON.stringify({firstDifference:diff,parent:books[1].book,candidate:books[0].book},null,2)+'\n');assert.deepEqual(diff,null);return{sha256:sha(JSON.stringify(books[0].book))};});
 }
 for(const x of attempts)await x.W.verifyAttempt(x.dir);for(const x of report.inputs)assert.equal(identity(x.file).sha256,x.sha256);report.complete=true;report.pass=report.controls.every(x=>x.pass);
}catch(e){report.error=String(e.stack??e);}report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,count:report.controls.length,failed:report.controls.filter(x=>!x.pass).map(x=>x.name),error:report.error}));if(!report.pass)process.exitCode=1;
