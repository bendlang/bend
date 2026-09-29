// Same checked image, raw grammar and ordered loading; frozen pin strings govern candidates.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const [mode,attemptArg,planArg,outArg,oracleArg]=process.argv.slice(2);assert(['baseline','candidate'].includes(mode));
const attempt=fs.realpathSync(attemptArg),planFile=fs.realpathSync(planArg),out=path.resolve(outArg);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const w=await import(pathToFileURL(path.join(attempt,'snapshot/tools/development/workflow.mjs'))),m=await w.verifyAttempt(attempt),plan=JSON.parse(fs.readFileSync(planFile)),tsFile=path.join(plan.upstream,'bend2/bend.ts'),hostFile=path.join(m.snapshot.root,'tools/typed-driver.mjs');
for(const k of Object.keys(process.env))if(k.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(k))delete process.env[k];Object.assign(process.env,{BEND_TYPED_API:m.api.file,BEND_BASE:m.base.file,BEND_TYPED_RUNTIME:m.runtime.file});
const a=(await import(pathToFileURL(m.api.file))).default,B=await import(pathToFileURL(tsFile)),H=await import(pathToFileURL(hostFile)),oracle=oracleArg?JSON.parse(fs.readFileSync(oracleArg)):null;
if(mode==='candidate')assert(oracle?.complete&&oracle.mode==='baseline');
const inputs=[import.meta.filename,planFile,path.join(attempt,'attempt.json'),m.api.file,m.base.file,tsFile,hostFile,...plan.inputs.map(x=>x.file),...oracleArg?[oracleArg]:[]].map(w.identity);for(const x of plan.inputs)assert.equal(w.identity(x.file).sha256,x.sha256);
const report={kind:'phase20-constructor-checkpoint-gate',mode,complete:false,pass:false,api:m.api,inputs,rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const r=[];for(let p=xs;p.$==='Con';p=p.tail)r.push(p.head);return r;};
const err=e=>{assert.equal(e.$,'Err',String(e.stack??e));return B.err_show(e);};
const compare=row=>{
 const old=oracle?.rows.find(x=>x.route===row.route&&x.name===row.name);
 if(oracle){assert(old);assert.equal(row.expected,old.expected,'frozen pinned diagnostic');}
 row.referenceAccept=row.expected==='';row.candidateAccept=row.candidate==='';row.exact=row.expected===row.candidate;
 if(mode==='candidate')assert.equal(row.candidate,row.expected,'exact pinned diagnostic');
 row.pass=true;
};
try{
 for(const c of JSON.parse(fs.readFileSync(plan.rawCases))){const row={name:c.name,route:'raw'};report.rows.push(row);try{
  const book=B.book_nil();let expected='';try{B.parse_book(book,'',c.source,'',{});}catch(e){expected=err(e);}const p=a.f_parse(c.source);Object.assign(row,{expected,candidate:p.error});
  if(!expected&&!p.error){row.referenceConstructors=Object.values(book.ctrs).map(x=>[x.k,x.n]);row.candidateConstructors=array(p.book).flatMap(d=>array(d.ctors).map(x=>[x.name,x.arity]));assert.deepEqual(row.candidateConstructors,row.referenceConstructors,'successful constructor inventory');}
  compare(row);
 }catch(e){row.pass=false;row.error=e.stack??String(e);}save();}
 for(const c of plan.cases){let expected='';try{await B.book_load(B.book_nil(),c.main,'',new Map());}catch(e){expected=err(e);}assert.equal(!expected,c.referenceAccept,'frozen loaded reference acceptance');
  for(const route of ['supplied','host']){const row={name:c.name,route,expected};report.rows.push(row);try{
   if(route==='supplied'){let next=1;const sources=c.files.map(f=>{const file=path.join(c.directory,f),text=fs.readFileSync(file,'utf8'),source={$:'FLocatedSource',source:{$:'FSource',name:file,path:file,text},begin:next,end:next+text.length+1};next=source.end;return source;});row.candidate=a.f_load_graph(c.main,list(sources)).error;}
   else{const read=fs.readFileSync,reads=[];try{fs.readFileSync=function(file,...args){if(typeof file==='string'&&file.startsWith(c.directory+'/'))reads.push(path.relative(c.directory,file));return read.call(fs,file,...args);};row.candidate=H.discoverSources(a,c.main).loadTrace.result.error;}catch(e){assert.equal(e.phase,'parse',String(e.stack??e));row.candidate=e.message;}finally{fs.readFileSync=read;}row.hostReads=reads;assert.deepEqual(reads,c.expectedReads,'ordered fixture reads');}
   compare(row);
  }catch(e){row.pass=false;row.error=e.stack??String(e);}save();}
 }
 inputs.forEach(w.verifyIdentity);await w.verifyAttempt(attempt);report.complete=true;report.pass=report.rows.every(x=>x.pass);report.count=report.rows.length;report.exact=report.rows.filter(x=>x.exact).length;report.acceptanceDifferences=report.rows.filter(x=>x.referenceAccept!==x.candidateAccept).map(x=>({name:x.name,route:x.route}));
}catch(e){report.error=e.stack??String(e);}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,count:report.count,exact:report.exact,failed:report.rows.filter(x=>!x.pass).map(x=>({name:x.name,route:x.route,error:x.error})),error:report.error}));if(!report.pass)process.exitCode=1;
