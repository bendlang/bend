import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
const [beforeArg,afterArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));const before=await verifyAttempt(path.resolve(beforeArg)),after=await verifyAttempt(path.resolve(afterArg));assert.equal(before.config.upstream,after.config.upstream);const upstream=path.join(after.config.upstream,'bend2/bend.ts'),U=await import(pathToFileURL(upstream));
async function api(attempt,label){const view=path.join(out,label+'.mjs');fs.writeFileSync(view,fs.readFileSync(attempt.api.file,'utf8')+'\nexport const declarationControls={f_tops:run_lib((...xs)=>run_loop($f_tops$(...xs)),4),fpe_finish_indexed:run_lib((...xs)=>run_loop($fpe_finish_indexed$(...xs)),3),f_lex_indexed:run_lib((...xs)=>run_loop($f_lex_indexed$(...xs)),2)};\n');const x=await import(pathToFileURL(view));return {...x.default,...x.declarationControls};}
const B=await api(before,'baseline'),C=await api(after,'candidate'),inputs=[import.meta.filename,before.api.file,after.api.file,upstream,process.execPath].map(identity),nil={$:'Nil'};
const controls=[
 ['fresh-typed','def f() -> Type:\n  Type\n'],
 ['open-law-fill','law f:\n  Type\ndef f():\n  Type\n'],
 ['open-law-unsafe-fill','law f:\n  Type\n@unsafe\ndef f():\n  Type\n'],
 ['closed-body','def f() -> Type:\n  Type\ndef f():\n  Type\n'],
 ['closed-body-before-bad-telescope','def f() -> Type:\n  Type\ndef f(@):\n  Type\n'],
 ['closed-body-before-missing-paren','def f() -> Type:\n  Type\ndef f : Type\n'],
 ['foreign-fill','law f:\n  Type\ndef f():\n  import "./unused.js"\n'],
 ['closed-foreign','law f:\n  Type\ndef f():\n  import "./unused.js"\ndef f():\n  Type\n'],
 ['closed-foreign-before-bad-telescope','law f:\n  Type\ndef f():\n  import "./unused.c"\ndef f(@):\n  Type\n'],
 ['unknown-missing-arrow','def fresh(x,y):\n  x\n'],
 ['unknown-missing-arrow-eof','def fresh(x)'],
 ['law-fill-arrow','law f:\n  Type\ndef f() -> Type:\n  Type\n'],
 ['ordinary-u32-name','law U32:\n  Type\ndef U32():\n  Type\n'],
 ['real-keyword-name','law Type:\n  Type\n'],
 ['native-claim-refill','def f():\n  Type\n',{seed:'law f:\n  Type\n',native:true}],
 ['ordinary-claim-refill','def f():\n  Type\n',{seed:'law f:\n  Type\n',native:false}],
];
const report={kind:'phase16-parser-declaration-controls',complete:false,pass:false,inputs,rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
function ref(source,options){const b=U.book_nil();if(options){U.parse_book(b,'',options.seed,'',{});b.tlds.f.b=options.native;}try{U.parse_book(b,'',source,'',{});return '';}catch(e){return U.err_show(e);}}
function parse(A,source,start,options){if(!options)return start===0?A.f_parse(source):A.f_parse_indexed(start,source);const book=A.f_parse(options.seed).book;book.head.native=options.native;return A.fpe_finish_indexed(start,source,A.f_tops(A.f_lex_indexed(start,source),book,nil,{$:'False'}));}
function erase(x){if(Array.isArray(x))return x.map(erase);if(x&&typeof x==='object')return Object.fromEntries(Object.entries(x).filter(([k])=>k!=='originBegin'&&k!=='originEnd').map(([k,v])=>[k,erase(v)]));return x;}
try{for(const [label,source,options] of controls)for(const start of options?[1,4097]:[0,1,4097]){const b=parse(B,source,start,options),c=parse(C,source,start,options),r=ref(source,options),sameAcceptance=(b.error==='')===(c.error===''),exact=c.error===r;let sameSuccessTree=true;if(!c.error)try{assert.deepEqual(erase(c),erase(b));}catch{sameSuccessTree=false;}const row={label,start,source,options,baseline:b.error,candidate:c.error,reference:r,exact,sameAcceptance,sameSuccessTree,pass:exact&&sameSuccessTree};report.rows.push(row);save();}inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(x=>x.pass);save();assert.equal(report.pass,true);}catch(e){report.error=String(e.stack??e);save();process.exitCode=1;}console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,failed:report.rows.filter(x=>!x.pass).map(x=>[x.label,x.start]),error:report.error}));
