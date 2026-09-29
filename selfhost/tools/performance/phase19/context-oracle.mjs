#!/usr/bin/env node
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{pathToFileURL}from'node:url';import{createHash}from'node:crypto';
const[planArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const sha=x=>createHash('sha256').update(x).digest('hex'),id=file=>({file:path.resolve(file),sha256:sha(fs.readFileSync(file))});
const report={complete:false,pass:false,inputs:[id(import.meta.filename),id(planArg)],rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));save();
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const project=t=>{if(t===null||typeof t!=='object')return t;return Object.fromEntries(Object.entries(t).map(([k,v])=>[k,k==='s'?{begin:v.beg,end:v.end}:Array.isArray(v)?v.map(project):project(v)]));};
try{
 const plan=JSON.parse(fs.readFileSync(planArg)),m=JSON.parse(fs.readFileSync(path.join(plan.parentAttempt,'attempt.json'))),workflow=await import(pathToFileURL(path.join(m.snapshot.root,'tools/development/workflow.mjs')));await workflow.verifyAttempt(plan.parentAttempt);
 const upstream=path.join(m.config.upstream,'bend2/bend.ts');report.inputs.push(id(upstream),id(plan.priorFile),id(m.api.file),id(path.join(plan.parentAttempt,'attempt.json')));
 const B=await import(pathToFileURL(upstream)),K=(await import(pathToFileURL(m.api.file))).default,prior=fs.readFileSync(plan.priorFile,'utf8'),book=B.book_nil();B.parse_book(book,'',prior,'',{});
 const loaded=K.f_load_graph('prior',list([{$:'FLocatedSource',source:{$:'FSource',name:'prior',path:plan.priorFile,text:prior},begin:1,end:prior.length+2}]));assert.equal(loaded.error,'');
 fs.writeFileSync(path.join(out,'prior-book.json'),JSON.stringify(loaded.book)+'\n');report.priorBook=id(path.join(out,'prior-book.json'));report.upstreamMembers={tlds:Object.keys(book.tlds),constructors:Object.keys(book.ctrs)};
 for(const c of plan.cases){
  if(!c.supported){report.rows.push({id:c.id,status:'unsupported-control',expectedProbeStatus:'Unsupported',notConformance:true});continue;}
  const h={book,dir:'',str:c.header,pos:0,stk:[],frs:0,ns:c.namespace,al:c.aliases};const tele=B.parse_tele(h,')');assert.equal(h.pos,c.header.length);
  const seed={parameters:tele.map(x=>({name:x[1],id:x[2],quantity:x[0].$,type:project(x[3]),span:{begin:x[4].beg,end:x[4].end}})),stack:h.stk.map(x=>[...x]),next:h.frs,headerCursor:h.pos};
  const p={book,dir:'',str:c.text,pos:c.text.length,stk:h.stk.map(x=>[...x]),frs:h.frs,ns:c.namespace,al:c.aliases},span={file:p,beg:0,end:c.text.length},state=()=>({next:p.frs,stack:p.stk.map(x=>[...x]),cursor:p.pos}),row={id:c.id,seed,status:'pending'};
  let stage='first';try{row.first={term:project(B.parse_var(p,c.text,span)),state:state()};const depth=p.stk.length;stage='open';row.open={id:B.parse_open(p,c.text),state:state()};stage='inner';row.inner={term:project(B.parse_var(p,c.text,span)),state:state()};B.parse_close(p,depth);stage='after';row.after={term:project(B.parse_var(p,c.text,span)),state:state()};p.pos=0;row.rewound=state();row.status='success';}
  catch(e){assert.equal(e.$,'Err');row.status='error';row.failure={stage,expected:e.exp,observed:e.obs,span:{begin:e.spn.beg,end:e.spn.end},raw:B.err_show(e),state:state()};}
  report.rows.push(row);save();
 }
 assert.equal(report.rows.length,plan.cases.length);assert.equal(report.rows.filter(x=>x.status==='error').length,1);assert.equal(report.rows.find(x=>x.status==='error').id,'alias-ambiguous');
 await workflow.verifyAttempt(plan.parentAttempt);for(const x of report.inputs)assert.equal(id(x.file).sha256,x.sha256);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));if(!report.pass)process.exitCode=1;
