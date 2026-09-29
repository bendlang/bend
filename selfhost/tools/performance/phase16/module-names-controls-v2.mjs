import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';

const [beforeArg,afterArg,selectionArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const inputs=[import.meta.filename,process.execPath,selectionArg].map(identity);
const report={complete:false,pass:false,inputs,rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const term=(tag,name='',kids=[],begin=0,end=0,id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:begin,originEnd:end});
const ref=n=>term('Ref',n),text=s=>({$:'DText',text:s}),expr=t=>({$:'DTerm',term:t});
const digest=x=>createHash('sha256').update(JSON.stringify(x)).digest('hex');
async function control(name,fn){try{const evidence=await fn();report.rows.push({name,pass:true,evidence});}catch(e){report.rows.push({name,pass:false,error:String(e.stack??e)});}save();}

try{
 const states=[];
 for(const arg of[beforeArg,afterArg]){
  const dir=path.resolve(arg),m=await verifyAttempt(dir);inputs.push(identity(path.join(dir,'attempt.json')),m.api);
  process.env.BEND_TYPED_API=m.api.file;process.env.BEND_TYPED_RUNTIME=m.runtime.file;process.env.BEND_BASE=m.base.file;process.env.BEND_UPSTREAM=m.config.upstream;
  const H=await import(pathToFileURL(path.join(m.snapshot.root,'tools/typed-driver.mjs'))),K=await H.loadApi();states.push({dir,m,H,K});
 }
 const [B,C]=states;
 const source=(name,path,text,begin)=>({$:'FLocatedSource',source:{$:'FSource',name,path,text},begin,end:begin+text.length+1});
 const trace={$:'FLoadTrace',result:{$:'FResult',book:list([]),error:'',imports:list([])},
  sources:list([source('a','/a.bend','abc\n',1),source('b','/b.bend','xyz\n',11)]),
  done:list([term('Loaded','/a.bend',[ref('owner'),term('Import','dep',[term('Alias','M')])]),term('Loaded','/b.bend',[ref('other'),term('Import','dep',[term('Alias','N')])])])};
 const aSpan={$:'DSpan',source:'abc\n',begin:1,end:2},bSpan={$:'DSpan',source:'xyz\n',begin:1,end:2};
 const located=term('Ref','site',[],2,3),inB=term('Ref','site',[],12,13);
 const result=(expected=expr(ref('dep.value')),observed=expr(ref('owner.local')),span=aSpan,trail=[located],context=[])=>({$:'DResult',error:'controlled error',book:list([]),diagnostic:{$:'DDiagnostic',expected,observed,has_observed:true,context:list(context),definition:'owner.wrong',span,note:'',trail:list(trail)}});
 const render=r=>C.K.diagnostic_render_loaded(r,trace);
 await control('owned interval selects aliases and own namespace',()=>{const s=render(result());assert(s.includes('expected : M.value'));assert(s.includes('observed : local'));assert(s.includes('Location: wrong'));return s;});
 await control('different owned interval selects its own alias',()=>{const s=render(result(expr(ref('dep.value')),text('observed'),bSpan,[inB]));assert(s.includes('expected : N.value'));return s;});
 await control('prelocated mismatch keeps canonical context',()=>{const r=result(expr(ref('dep.value')),text('observed'),bSpan,[located]);const s=render(r);assert.equal(s,C.K.diagnostic_render(r));return s;});
 await control('absent span keeps canonical context',()=>{const r=result(expr(ref('dep.value')),text('observed'),{$:'DNoSpan'},[located]);const s=render(r);assert.equal(s,C.K.diagnostic_render(r));return s;});
 await control('unowned range falls through to owned range',()=>{const s=render(result(expr(ref('dep.value')),text('observed'),aSpan,[term('Ref','bad',[],100,101),located]));assert(s.includes('expected : M.value'));return s;});
 await control('own Nil is not builtin list sugar',()=>{const s=render(result(expr(term('Ctr','owner.Nil'))));assert(s.includes('expected : Nil{}'));assert(!s.includes('expected : []'));return s;});
 await control('builtin Nil remains list sugar',()=>{const s=render(result(expr(term('Ctr','Nil'))));assert(s.includes('expected : []'));return s;});
 await control('removed constructor uses file names',()=>{const s=render(result(expr(term('ADT','owner.Tree',[],0,0,0,0,['owner.Empty']))));assert(s.includes('expected : Tree<> - Empty{}'));return s;});
 await control('global shadow compares displayed name',()=>{const ctx=[term('Bind','M.value',[term('Typ','',[term('Qua','',[],0,0,0,1)])],0,0,1,1)];const s=render(result(expr(ref('dep.value')),text('observed'),aSpan,[located],ctx));assert(s.includes('expected : M.value^'));return s;});
 await control('file context adds no binder depth',()=>{const t=term('Lam','x',[term('Var','x',[],0,0,1)],0,0,2,1);const ctx=[term('Bind','x',[term('Typ','',[term('Qua','',[],0,0,0,1)])],0,0,1,1)];const r=result(expr(t),text('observed'),aSpan,[located],ctx);const actual=render(r),old=C.K.diagnostic_render(r);assert.equal(actual.split('\n').find(x=>x.startsWith('- expected')),old.split('\n').find(x=>x.startsWith('- expected')));return actual;});
 for(const row of JSON.parse(fs.readFileSync(selectionArg)).cases){
  const file=row.file??path.join(B.m.config.upstream,'tests',row.id);inputs.push(identity(file));
  await control('complete loaded book unchanged '+row.id,()=>{
   const ds=[];for(const state of states){const g=state.H.discoverSources(state.K,file);for(const f of g.files??[])if(typeof f==='string'&&fs.existsSync(f))inputs.push(identity(f));const loaded=state.K.f_load_graph_trace(g.main,g.sources);assert.equal(loaded.result.error,'');ds.push(digest(loaded.result));}assert.equal(ds[0],ds[1]);return{sha256:ds[0]};
  });
 }
 for(const state of states)await verifyAttempt(state.dir);inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(r=>r.pass);
}catch(e){report.error=String(e.stack??e);}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,failed:report.rows.filter(r=>!r.pass).map(r=>r.name),error:report.error}));if(!report.pass)process.exitCode=1;
