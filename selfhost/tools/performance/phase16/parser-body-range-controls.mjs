import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [attemptArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));const attempt=await verifyAttempt(path.resolve(attemptArg)),upstream=path.join(attempt.config.upstream,'bend2/bend.ts'),code=fs.readFileSync(attempt.api.file,'utf8'),view=path.join(out,'candidate.mjs');fs.writeFileSync(view,code+'\nexport const bodyRanges={f_expr:run_lib((...xs)=>run_loop($f_expr$(...xs)),2),f_body:run_lib((...xs)=>run_loop($f_body$(...xs)),1),f_lex_indexed:run_lib((...xs)=>run_loop($f_lex_indexed$(...xs)),2)};\n');const mod=await import(pathToFileURL(view)),C={...mod.default,...mod.bodyRanges},U=await import(pathToFileURL(upstream)),inputs=[import.meta.filename,attempt.api.file,upstream,process.execPath].map(identity);
const list=x=>{let a=[];while(x.$==='Con'){a.push(x.head);x=x.tail;}return a;};const report={complete:false,pass:false,inputs,rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
function reference(source){const book=U.book_nil();U.parse_book(book,'','type Box is Type:\n  Mk{value: Type}\ntype M<q,A:Type> is Type:\n  W{value:A}\n','',{});return {book,dir:'',str:source,pos:0,stk:[],frs:0,ns:'',al:{}};}
function compare(label,source,candidate,ref,start){const a=[candidate.originBegin-start,candidate.originEnd-start],b=[ref.s.beg,ref.s.end];report.rows.push({label,source,candidate:a,reference:b,pass:JSON.stringify(a)===JSON.stringify(b)});assert.deepEqual(a,b);save();}
try{
 const start=8193;
 for(const [label,source]of [['do-bind','do Box<>:\n  x : Type <- Mk{Type}\n  return x'],['do-header','do M<Type>:\n  x : Type <- W{Type}\n  return x'],['do-semicolon','do Box<>:\n  x : Type <- Mk{Type}; return x'],['do-final','do Box<>:\n  Mk{Type}']]){
  const p=reference(source),r=U.parse_term(p),c=C.f_expr(C.f_lex_indexed(start,source),0).term;compare(label,source,c,r,start);
  if(label!=='do-final'){const cs=list(c.kids),xs=U.term_unapply(r)[1];compare(label+'-continuation',source,cs[3],xs.at(-1),start);compare(label+'-return',source,list(cs[3].kids)[0],xs.at(-1).f,start);if(label==='do-header')compare(label+'-implicit-quantity-header',source,cs[0],xs[0],start);}
 }
 const match='match x:\n  case Mk{v}:\n    v\n';compare('whole-match',match,C.f_body(C.f_lex_indexed(start,match)).term,U.parse_body(reference(match)),start);
 const erased='-x = y\nx';const er=C.f_body(C.f_lex_indexed(start,erased)).term,rr=U.parse_body(reference(erased));compare('erased-name',erased,list(er.kids)[0],rr.k[0],start);
 const law='law bad:\n  exs x: Type\n  Type\n',cb=list(C.f_parse_indexed(start,law).book)[0],book=U.book_nil();U.parse_book(book,'',law,'',{});const rt=U.term_lower(book.tlds.bad.T,0),ct=cb.typ;compare('law-exists-head',law,list(list(ct.kids)[0].kids)[0],U.term_unapply(rt)[0],start);
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(r=>r.pass);save();
}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
