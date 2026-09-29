#!/usr/bin/env node
import fs from 'node:fs'; import path from 'node:path'; import assert from 'node:assert/strict'; import {pathToFileURL} from 'node:url'; import {createHash} from 'node:crypto';
const [planArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const sha=x=>createHash('sha256').update(x).digest('hex'),id=file=>({file:path.resolve(file),sha256:sha(fs.readFileSync(file))});
const report={complete:false,pass:false,inputs:[id(import.meta.filename),id(planArg)],rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));save();
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const project=t=>{if(t===null||typeof t!=='object')return typeof t==='bigint'?String(t):t;return Object.fromEntries(Object.entries(t).map(([k,v])=>[k,k==='s'&&v?{begin:v.beg,end:v.end}:Array.isArray(v)?v.map(project):project(v)]));};
try{
 const plan=JSON.parse(fs.readFileSync(planArg)),m=JSON.parse(fs.readFileSync(path.join(plan.parentAttempt,'attempt.json'))),W=await import(pathToFileURL(path.join(m.snapshot.root,'tools/development/workflow.mjs')));await W.verifyAttempt(plan.parentAttempt);
 const upstream=path.join(m.config.upstream,'bend2/bend.ts'),B=await import(pathToFileURL(upstream));report.inputs.push(id(upstream),id(B.BASE_BEND),id(m.api.file),id(path.join(plan.parentAttempt,'attempt.json')));
 const base=B.book_nil();await B.book_load(base,B.BASE_BEND,'',new Map());const clone=()=>({...base,tlds:{...base.tlds},ctrs:{...base.ctrs},tmps:{...base.tmps},order:[...base.order]});
 const original=fs.readFileSync(m.api.file),suffix='\nexport const __rowOracle={f_lex_indexed:run_lib((a,b)=>run_loop($f_lex_indexed$(a,b)),2),f_body:run_lib(a=>run_loop($f_body$(a)),1),fpe_origin_render:run_lib((a,b,c)=>run_loop($fpe_origin_render$(a,b,c)),3),fpe_render:run_lib((a,b)=>run_loop($fpe_render$(a,b)),2)};\n',ext=path.join(out,'baseline-extension.mjs');fs.writeFileSync(ext,Buffer.concat([original,Buffer.from(suffix)]));assert(fs.readFileSync(ext).subarray(0,original.length).equals(original));report.extension={production:id(m.api.file),probe:id(ext),prefixUnchanged:true};const mod=await import(pathToFileURL(ext)),K=mod.default,P=mod.__rowOracle;
 const priorCache=new Map(),baseText=fs.readFileSync(B.BASE_BEND,'utf8');
 for(const c of plan.cases){
  report.inputs.push(id(c.file));const originalText=fs.readFileSync(c.file,'utf8'),view=originalText.split('\n').map(x=>x==='import Base'?'':x).join('\n'),at=view.indexOf('def '+c.target+'(');assert(at>=0);assert.equal(view.indexOf('def '+c.target+'(',at+1),-1);
  const prefix=view.slice(0,at),book=clone();B.parse_book(book,path.dirname(c.file)+'/',prefix,'',{});
  const p={book,dir:path.dirname(c.file)+'/',str:view,pos:at,stk:[],frs:0,ns:'',al:{}};assert(B.parse_word(p,'def'));const name=B.parse_name(p);assert.equal(name,c.target);assert.equal(B.parse_reso(p,name),name);assert.equal(B.parse_fresh(p,name),name);assert(!B.parse_take(p,'?'));B.parse_eat(p,'(');const tk=[],tele=B.parse_tele(p,')',tk);B.parse_skip(p);assert(B.parse_take(p,'->'));const type=B.parse_term(p);book.tlds[name]={$: 'Def',n:tele.length,x:tk.length,T:B.term_higher(B.tele_bind(tele,type)),v:null,m:''};B.parse_eat(p,':');
  const seed={parameters:tele.map(x=>({name:x[1],id:x[2],quantity:'Lone',span:{begin:x[4].beg,end:x[4].end}})),stack:p.stk.map(x=>[...x]),next:p.frs,bodyCursor:p.pos,headerBegin:at};
  const vars=tele.map(x=>({$:'PVar',k:x[1],i:x[2],q:B.Lone(),s:x[4]})),state=()=>({next:p.frs,stack:p.stk.map(x=>[...x]),cursor:p.pos});
  const row={id:c.id,supported:c.supported,seed,sourceView:view,original:id(c.file),status:'pending',stage:'body'};
  try{const body=B.parse_body(p);row.body=project(body);row.bodyState=state();row.stage='flatten';const flat=B.body_flatten(body,vars,()=>p.frs++);row.term=project(flat);row.canonical=project(B.term_lower(B.term_higher(flat),0));row.state=state();row.status='success';}
  catch(e){if(e.$!=='Err')throw e;row.status='error';row.failure={expected:e.exp,observed:e.obs,span:{begin:e.spn.beg,end:e.spn.end},raw:B.err_show(e),state:state()};}
  const fullBook=clone();try{await B.book_load(fullBook,c.file,'',new Map([[B.BASE_BEND,'']]));row.fullFile={status:'success'};}catch(e){if(e.$!=='Err')throw e;row.fullFile={status:'error',diagnostic:B.err_show(e)};}
  assert.equal(row.fullFile.status,row.status,c.id);if(row.status==='error')assert.equal(row.fullFile.diagnostic,row.failure.raw,c.id);
  if(!priorCache.has(prefix)){
   const priorText='import Base\n'+prefix.slice(1),priorFile=path.join(out,'prior-'+priorCache.size+'.bend');fs.writeFileSync(priorFile,priorText);
   const loaded=K.f_load_graph('prior',list([{$:'FLocatedSource',source:{$:'FSource',name:'Base',path:B.BASE_BEND,text:baseText},begin:1,end:baseText.length+2},{$:'FLocatedSource',source:{$:'FSource',name:'prior',path:priorFile,text:priorText},begin:200001,end:200001+priorText.length+1}]));assert.equal(loaded.error,'');const bookFile=path.join(out,'prior-'+priorCache.size+'-book.json');fs.writeFileSync(bookFile,JSON.stringify(loaded.book)+'\n');priorCache.set(prefix,id(bookFile));
  }row.priorBook=priorCache.get(prefix);
  const tokens=P.f_lex_indexed(c.sourceBegin,view);let tail=tokens;while(tail.$==='Con'&&tail.head.begin<c.sourceBegin+seed.bodyCursor)tail=tail.tail;
  const raw=P.f_body({$:'FInput',tokens:tail,context:{$:'FCursorContext',serial:0}});row.rawParent={result:raw.term.tag,diagnostic:raw.term.tag==='Error'?(raw.term.originBegin?P.fpe_origin_render(view,c.sourceBegin,raw.term):P.fpe_render(view,raw.term)):null,term:raw.term};
  report.rows.push(row);save();
 }
 assert.equal(report.rows.length,plan.cases.length);for(const name of ['id-zero-bound-var','id-zero-qualified-ref','id-zero-computed-app','id-zero-constructor'])assert.equal(report.rows.find(x=>x.id==='context-row/'+name).seed.parameters[0].id,0);
 await W.verifyAttempt(plan.parentAttempt);for(const x of report.inputs)assert.equal(id(x.file).sha256,x.sha256);report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));if(!report.pass)process.exitCode=1;
