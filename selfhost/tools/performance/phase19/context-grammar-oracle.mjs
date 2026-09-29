#!/usr/bin/env node
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{pathToFileURL}from'node:url';import{createHash}from'node:crypto';
const[planArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const sha=x=>createHash('sha256').update(x).digest('hex'),id=file=>({file:path.resolve(file),sha256:sha(fs.readFileSync(file))});
const report={complete:false,pass:false,inputs:[id(import.meta.filename),id(planArg)],rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));save();
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const project=t=>{if(t===null||typeof t!=='object')return t;return Object.fromEntries(Object.entries(t).map(([k,v])=>[k,k==='s'?{begin:v.beg,end:v.end}:Array.isArray(v)?v.map(project):project(v)]));};
try{
 const plan=JSON.parse(fs.readFileSync(planArg)),m=JSON.parse(fs.readFileSync(path.join(plan.parentAttempt,'attempt.json'))),W=await import(pathToFileURL(path.join(m.snapshot.root,'tools/development/workflow.mjs')));await W.verifyAttempt(plan.parentAttempt);
 const upstream=path.join(m.config.upstream,'bend2/bend.ts');report.inputs.push(id(upstream),id(plan.priorFile),id(m.api.file),id(path.join(plan.parentAttempt,'attempt.json')));
 const B=await import(pathToFileURL(upstream)),original=fs.readFileSync(m.api.file),suffix='\nexport const __grammarOracle = {f_lex_indexed:run_lib((a,b)=>run_loop($f_lex_indexed$(a,b)),2),f_expr:run_lib((a,b)=>run_loop($f_expr$(a,b)),2),fpe_render:run_lib((a,b)=>run_loop($fpe_render$(a,b)),2)};\n',ext=path.join(out,'baseline-extension.mjs');
 fs.writeFileSync(ext,Buffer.concat([original,Buffer.from(suffix)]));assert(fs.readFileSync(ext).subarray(0,original.length).equals(original));report.extension={production:id(m.api.file),probe:id(ext),prefixUnchanged:true};const mod=await import(pathToFileURL(ext)),K=mod.default,P=mod.__grammarOracle;
 const prior=fs.readFileSync(plan.priorFile,'utf8'),book=B.book_nil();B.parse_book(book,'',prior,'',{});
 const loaded=K.f_load_graph('prior',list([{$:'FLocatedSource',source:{$:'FSource',name:'prior',path:plan.priorFile,text:prior},begin:1,end:prior.length+2}]));assert.equal(loaded.error,'');
 fs.writeFileSync(path.join(out,'prior-book.json'),JSON.stringify(loaded.book)+'\n');report.priorBook=id(path.join(out,'prior-book.json'));
 for(const c of plan.cases){
  const h={book,dir:'',str:c.header,pos:0,stk:[],frs:0,ns:c.namespace,al:c.aliases},tele=B.parse_tele(h,')');assert.equal(h.pos,c.header.length);
  const seed={parameters:tele.map(x=>({name:x[1],id:x[2],quantity:x[0].$,span:{begin:x[4].beg,end:x[4].end}})),stack:h.stk.map(x=>[...x]),next:h.frs};
  const p={book,dir:'',str:c.text,pos:0,stk:h.stk.map(x=>[...x]),frs:h.frs,ns:c.namespace,al:c.aliases},state=()=>({next:p.frs,stack:p.stk.map(x=>[...x]),cursor:p.pos}),row={id:c.id,seed,supported:c.supported,status:'pending'};
  try{row.term=project(B.parse_term(p));row.state=state();row.status='success';}
  catch(e){assert.equal(e.$,'Err');row.status='error';row.failure={expected:e.exp,observed:e.obs,span:{begin:e.spn.beg,end:e.spn.end},raw:B.err_show(e),state:state()};}
  if(c.id.includes('error')||c.id==='syntax-before-later-alias'||c.id==='nested-alias-first'){
   const raw=P.f_expr({$:'FInput',tokens:P.f_lex_indexed(c.sourceBegin,c.text),context:{$:'FCursorContext',serial:0}},0);
   row.rawParent={result:raw.term.tag,diagnostic:raw.term.tag==='Error'?P.fpe_render(c.text,raw.term):null,term:raw.term};
  }
  report.rows.push(row);save();
 }
 assert.equal(report.rows.length,plan.cases.length);const a=report.rows.find(x=>x.id==='alias-first-error'),b=report.rows.find(x=>x.id==='shadow-exposes-later-error');assert.equal(a.status,'error');assert.equal(b.status,'error');assert.notEqual(a.failure.raw,b.failure.raw);assert.notEqual(a.rawParent.diagnostic,a.failure.raw);assert.equal(b.rawParent.diagnostic,b.failure.raw);
 await W.verifyAttempt(plan.parentAttempt);for(const x of report.inputs)assert.equal(id(x.file).sha256,x.sha256);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));if(!report.pass)process.exitCode=1;
