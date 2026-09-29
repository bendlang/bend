#!/usr/bin/env node
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{pathToFileURL}from'node:url';import{createHash}from'node:crypto';
const[aa,oo]=process.argv.slice(2),attempt=path.resolve(aa),out=path.resolve(oo);fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const hash=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex'),id=file=>({file:path.resolve(file),sha256:hash(file)}),report={kind:'phase16-contextual-constructor-resolution',complete:false,pass:false,inputs:[id(import.meta.filename),id(path.join(attempt,'attempt.json'))],controls:[]};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const rows=[
 ['local-ctor-shadows-far-law','law X:\n  Type\n','type T is Data:\n  other.X{}\ndef other.X():\n  Type\n'],
 ['local-ctor-before-bad-parameters','law X:\n  Type\n','type T is Data:\n  other.X{}\ndef other.X( !!!\n'],
 ['local-ctor-far-completed','def X() -> Type:\n  Type\n','type T is Data:\n  other.X{}\ndef other.X():\n  Type\n'],
 ['local-ctor-no-far-law','','type T is Data:\n  other.X{}\ndef other.X() -> Type:\n  Type\n'],
 ['far-law-no-local-ctor','law X:\n  Type\n','def other.X():\n  Type\n'],
 ['unrelated-local-ctor','law X:\n  Type\n','type T is Data:\n  Local{}\ndef other.X():\n  Type\n'],
 ['alias-ctor-before-fields','law X:\n  Type\n','import ./other.bend as O\ntype T is Data:\n  O.X{ !!!\n'],
 ['alias-ctor-valid-fields','law X:\n  Type\n','import ./other.bend as O\ntype T is Data:\n  O.X{}\n'],
];fs.writeFileSync(path.join(out,'frozen-cases.json'),JSON.stringify(rows,null,2)+'\n');report.inputs.push(id(path.join(out,'frozen-cases.json')));
try{const a=JSON.parse(fs.readFileSync(path.join(attempt,'attempt.json'))),W=await import(pathToFileURL(path.join(a.snapshot.root,'tools/development/workflow.mjs')));await W.verifyAttempt(attempt);process.env.BEND_TYPED_API=a.api.file;process.env.BEND_BASE=a.base.file;const H=await import(pathToFileURL(path.join(a.snapshot.root,'tools/typed-driver.mjs'))),K=await H.loadApi(),uf=path.resolve('selfhost/.bootstrap/upstream-phase8/bend2/bend.ts'),U=await import(pathToFileURL(uf));report.inputs.push(id(a.api.file),id(uf));
 for(const[name,other,dep]of rows){const dir=path.join(out,name);fs.mkdirSync(dir);for(const[f,text]of Object.entries({'other.bend':other,'dep.bend':dep,'main.bend':'import ./other.bend as O\nimport ./dep.bend as D\n'})){fs.writeFileSync(path.join(dir,f),text);report.inputs.push(id(path.join(dir,f)));}let expected='',actual='',exception=null;try{await U.book_load(U.book_nil(),path.join(dir,'main.bend'),'',new Map());}catch(e){assert.equal(e.$,'Err');expected=U.err_show(e);}try{const graph=H.discoverSources(K,path.join(dir,'main.bend'));actual=graph.loadTrace.result.error;}catch(e){if(e.phase!=='parse')exception=String(e.stack??e);actual=e.message;}report.controls.push({name,expected,actual,expectedAccepted:!expected,actualAccepted:!actual,pass:!exception&&actual===expected,exception});save();}
 await W.verifyAttempt(attempt);for(const input of report.inputs)assert.equal(hash(input.file),input.sha256);report.complete=true;report.pass=report.controls.every(x=>x.pass);
}catch(e){report.error=String(e.stack??e);}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,controls:report.controls.length,failed:report.controls.filter(x=>!x.pass).map(x=>({name:x.name,expectedAccepted:x.expectedAccepted,actualAccepted:x.actualAccepted})),error:report.error}));if(!report.pass)process.exitCode=1;
