#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const [candidateArg,parentArg,outArg]=process.argv.slice(2),candidate=path.resolve(candidateArg),parent=path.resolve(parentArg),out=path.resolve(outArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:path.resolve(file),sha256:sha(fs.readFileSync(file))});
const report={kind:'phase16-contextual-supplied-source-controls',complete:false,pass:false,inputs:[identity(import.meta.filename)],controls:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const test=async(name,fn)=>{try{report.controls.push({name,pass:true,evidence:await fn()});}catch(e){report.controls.push({name,pass:false,error:String(e.stack??e)});}save();};
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'}),array=xs=>{const out=[];while(xs.$==='Con'){out.push(xs.head);xs=xs.tail;}assert.equal(xs.$,'Nil');return out;};
const raw=(name,file,text)=>({$:'FSource',name,path:file,text});
const located=(s,begin)=>({$:'FLocatedSource',source:s,begin,end:begin+s.text.length+1});
const cases=[
 ['base-u32-before-syntax',{'main.bend':'import Base\ndef U32( !!!\n'}],
 ['base-string-eq-before-syntax',{'main.bend':'import Base\ndef String.eq( !!!\n'}],
 ['base-native-io',{'main.bend':'import Base\ndef IO.bind(~A):\n  A\n'}],
 ['imported-law-fill',{'dep.bend':'law f:\n  for x: Type\n  Type\n','main.bend':'import ./dep.bend as D\ndef D.f(x):\n  x\n'}],
 ['imported-law-annotated',{'dep.bend':'law f:\n  for x: Type\n  Type\n','main.bend':'import ./dep.bend as D\ndef D.f(x) -> Type:\n  x\n'}],
 ['imported-law-marked',{'dep.bend':'law f:\n  for x: Type\n  Type\n','main.bend':'import ./dep.bend as D\ndef D.f(+x: Type):\n  x\n'}],
 ['imported-law-template-marker',{'dep.bend':'law f:\n  for ~A: Type\n  A\n','main.bend':'import ./dep.bend as D\ndef D.f(~A):\n  A\n'}],
 ['imported-law-template-missing',{'dep.bend':'law f:\n  for ~A: Type\n  A\n','main.bend':'import ./dep.bend as D\ndef D.f():\n  Type\n'}],
 ['imported-completed',{'dep.bend':'def f() -> Type:\n  Type\n','main.bend':'import ./dep.bend as D\ndef D.f( !!!\n'}],
 ['imported-foreign',{'dep.bend':'def f() -> Type:\n  import "foreign.js"\n','main.bend':'import ./dep.bend as D\ndef D.f( !!!\n'}],
 ['alias-missing-before-syntax',{'dep.bend':'','main.bend':'import ./dep.bend as D\ndef D.f( !!!\n'}],
 ['alias-missing-before-no-arrow',{'dep.bend':'','main.bend':'import ./dep.bend as D\ndef D.f():\n  Type\n'}],
 ['law-collision',{'main.bend':'import Base\nlaw U32:\n  Kind\n'}],
 ['type-collision',{'main.bend':'import Base\ntype U32 is Data:\n  New{}\n'}],
 ['constructor-collision',{'main.bend':'import Base\ntype Other is Data:\n  Zero{}\n'}],
 ['dependency-body-before-later-header',{'dep.bend':'def bad( !!!\n','main.bend':'import ./dep.bend as D\nimport invalid\ndef later( !!!\n'}],
 ['dependency-body-before-main-body',{'dep.bend':'def bad( !!!\n','main.bend':'import ./dep.bend as D\ndef later( ???\n'}],
 ['comments-offset',{'dep.bend':'law f:\n  Type\n','main.bend':'# 😀 header\n\nimport ./dep.bend as D\n# body comment\ndef D.f() -> Type:\n  Type\n'}],
 ['same-file-aliases',{'dep.bend':'law f:\n  Type\n','main.bend':'import ./dep.bend as D\nimport ./dep.bend as E\ndef E.f():\n  Type\n'}],
 ['module-own-bare-law',{'dep.bend':'law f:\n  Type\ndef f():\n  Type\n','main.bend':'import ./dep.bend as D\n'}],
 ['late-import',{'dep.bend':'','main.bend':'def f() -> Type:\n  Type\nimport ./dep.bend as D\n'}],
 ['unsafe-import',{'dep.bend':'','main.bend':'@unsafe\nimport ./dep.bend as D\n'}],
];
fs.writeFileSync(path.join(out,'frozen-cases.json'),JSON.stringify(cases,null,2)+'\n');report.inputs.push(identity(path.join(out,'frozen-cases.json')));
try{
 const attempts=await Promise.all([candidate,parent].map(async dir=>{const a=JSON.parse(fs.readFileSync(path.join(dir,'attempt.json'))),W=await import(pathToFileURL(path.join(a.snapshot.root,'tools/development/workflow.mjs')));await W.verifyAttempt(dir);report.inputs.push(identity(path.join(dir,'attempt.json')),identity(a.api.file));return{a,W,K:(await import(pathToFileURL(a.api.file))).default,dir};}));
 const [{a,K},old]=attempts;assert.equal(K.compiler_load_abi(),1);
 const upstream=path.resolve(a.config?.upstream??'selfhost/.bootstrap/upstream-phase8'),U=await import(pathToFileURL(path.join(upstream,'bend2/bend.ts'))),baseText=fs.readFileSync(a.base.file,'utf8');report.inputs.push(identity(a.base.file),identity(path.join(upstream,'bend2/bend.ts')));
 for(const [name,text] of [['empty',''],['ordinary','def f() -> Type:\n  Type\n'],['comments','# 😀\n\n'],['local-law','law f:\n  for x: Type\n  Type\ndef f(x):\n  x\n'],['partial','def f( !!!\n'],['imports','import Base\nimport ./dep.bend as D\ndef f() -> Type:\n  Type\n']])for(const start of[0,4097])await test('legacy full projection '+name+' @'+start,()=>{const actual=start?K.f_parse_indexed(start,text):K.f_parse(text),expected=start?old.K.f_parse_indexed(start,text):old.K.f_parse(text);assert.deepEqual(actual,expected);return{sha256:sha(JSON.stringify(actual))};});
 await test('complete legacy Base projection',()=>{const expected=sha(JSON.stringify(old.K.f_parse_indexed(1,baseText))),actual=sha(JSON.stringify(K.f_parse_indexed(1,baseText)));assert.equal(actual,expected);return{sha256:actual};});
 const base=located(raw('Base',a.base.file,baseText),1),baseResult=K.f_load_graph('Base',list([base]));assert.equal(baseResult.error,'');
 for(const [name,files]of cases){
  const dir=path.join(out,'fixtures',name);fs.mkdirSync(dir,{recursive:true});for(const [name,text]of Object.entries(files)){const file=path.join(dir,name);fs.writeFileSync(file,text);report.inputs.push(identity(file));}
  await test('contextual '+name,async()=>{let expected='';try{await U.book_load(U.book_nil(),path.join(dir,'main.bend'),'',new Map());}catch(e){assert.equal(e.$,'Err',String(e.stack??e));expected=U.err_show(e);}
   let next=base.end;const sources=Object.entries(files).map(([name,text])=>{const s=located(raw(name==='main.bend'?'main':name.slice(0,-5),path.join(dir,name),text),next);next=s.end;return s;});sources.push(base);
   const actual=K.f_load_graph_seed('main',list(sources),a.base.file,baseText,baseResult.book);assert.equal(actual.error,expected);return{expected,actual:actual.error,events:array(actual.book).length};});
 }
 for(const start of[0,4097])await test('header valid prefix deferred failure @'+start,()=>{const text='# 😀\nimport Base\nimport wrong\ndef bad( !!!\n',s=raw('main','/main.bend',text),h=K.f_source_header(start?located(s,start):s);assert.equal(array(h.imports).length,1);assert.equal(h.line,4);assert.equal(h.offset,text.indexOf('def bad'));assert.equal(h.body,'def bad( !!!\n');assert.match(h.error,/an import/);return h;});
 await test('trusted parsed source reused without contextual reparse',()=>{const text='def impossible( !!!\n',parsed={$:'FResult',book:{$:'Nil'},error:'caller diagnostic',imports:{$:'Nil'}},source={$:'FParsedSource',name:'main',path:'/main.bend',text,parsed};const h=K.f_source_header(source);assert.equal(h.error,'');const c=K.f_complete_source(source,'',h,list([source]),{$:'FGraph',book:{$:'Nil'},error:'',done:{$:'Nil'}},'/');assert.deepEqual(c.parsed,parsed);assert.equal(c.graph.error,'caller diagnostic');return{error:c.graph.error};});
 await test('shared completion and raw loader agree',()=>{const source=located(raw('main','/main.bend','def f() -> Type:\n  Type\n'),4097),sources=list([source]),h=K.f_source_header(source),c=K.f_complete_source(source,'',h,sources,{$:'FGraph',book:{$:'Nil'},error:'',done:{$:'Nil'}},'/'),trace=K.f_graph_trace(c.graph,sources);assert.deepEqual(trace,K.f_load_graph_trace('main',sources));return{sha256:sha(JSON.stringify(trace))};});
 for(const item of attempts)await item.W.verifyAttempt(item.dir);for(const input of report.inputs)assert.equal(identity(input.file).sha256,input.sha256);
 report.complete=true;report.pass=report.controls.every(x=>x.pass);
}catch(e){report.error=String(e.stack??e);}report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,count:report.controls.length,failed:report.controls.filter(x=>!x.pass).map(x=>x.name),error:report.error}));if(!report.pass)process.exitCode=1;
