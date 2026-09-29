import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{pathToFileURL}from'node:url';
const[aa,oo]=process.argv.slice(2),attempt=path.resolve(aa),out=path.resolve(oo);fs.mkdirSync(out);
const W=await import(pathToFileURL(path.join(attempt,'snapshot/tools/development/workflow.mjs'))),m=await W.verifyAttempt(attempt),ts=path.resolve('selfhost/.bootstrap/upstream-phase8/bend2/bend.ts'),U=await import(pathToFileURL(ts)),K=(await import(pathToFileURL(m.api.file))).default;
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'}),inputs=[import.meta.filename,m.api.file,ts].map(W.identity),rows=[];
const source='type Z is Kind(&0):\n  Mk{}\ndef f() -> Z -> Z:\n  +x => x\n';fs.writeFileSync(path.join(out,'control.bend'),source);inputs.push(W.identity(path.join(out,'control.bend')));
for(const present of[false,true]){
 const book=U.book_nil();U.parse_book(book,'/',source,'',Object.create(null));assert.equal(book.tlds.f.v.$,'Lam');if(!present)delete book.tlds.f.v.q;
 let expected='';try{U.book_valid(book);}catch(e){assert.equal(e.$,'Err');expected=U.err_show(e);}
 const loaded=K.f_load_graph('main',list([{$:'FSource',name:'main',path:'/main.bend',text:source}]));assert.equal(loaded.error,'');let count=0;for(let xs=loaded.book;xs.$==='Con';xs=xs.tail)if(xs.head.name==='f'){assert.equal(xs.head.value.$,'KLambda');assert.equal(xs.head.value.quant,2);xs.head.value.quantityPresent=present;count++;}assert.equal(count,1);
 const actual=K.check_book(loaded.book);rows.push({present,expected,actual,referenceAccepted:!expected,candidateAccepted:!actual,primitiveMatch:!expected===!actual});
}
inputs.forEach(W.verifyIdentity);const report={kind:'phase16-lambda-optional-Many-semantics-witness',complete:true,inputs,rows,matched:rows.filter(x=>x.primitiveMatch).length};fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({complete:true,matched:report.matched,rows:rows.map(({present,referenceAccepted,candidateAccepted})=>({present,referenceAccepted,candidateAccepted}))}));
