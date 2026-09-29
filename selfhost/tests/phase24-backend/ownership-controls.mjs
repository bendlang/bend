// Direct book controls preserve shared emitter ownership precedence and exact names.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [attemptArg,outArg]=process.argv.slice(2),attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg);
const {verifyAttempt,identity,verifyIdentity}=await import(pathToFileURL(path.join(attempt,'snapshot/tools/development/workflow.mjs')));
const m=await verifyAttempt(attempt),{default:api}=await import(pathToFileURL(m.api.file));
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const term=tag=>({$:'KTerm',tag,name:'',id:0,quant:1,kids:list([]),removed:list([]),originBegin:0,originEnd:0});
const def=(name,kind='Def',tag='Foreign',ctors=[],native=false)=>({$:'KDef',name,kind,arity:0,templates:0,typ:term('Typ'),value:term(tag),ctors:list(ctors),native,unsafe:true});
const type=(name,ctor)=>def(name,'ADT','Absent',[def(ctor,'Ctr','Absent')]);
const collision=name=>name+' names both a constructor and a foreign def: name one apart';
const cases=[
 ['empty',[],''],
 ['foreign-only',[def('Tick')],''],
 ['constructor-only',[type('T','Tick')],''],
 ['collision',[type('T','Tick'),def('Tick')],collision('Tick')],
 ['foreign-before-type',[def('Tick'),type('T','Tick')],collision('Tick')],
 ['qualified-distinct',[type('T','Left.Tick'),def('Right.Tick')],''],
 ['case-distinct',[type('T','tick'),def('Tick')],''],
 ['ordinary-definition',[type('T','Tick'),def('Tick','Def','Ctr')],''],
 ['reserved-name-first',[type('T','Tick'),def('Tick'),type('IO','User')],'IO is a name the compiler encodes itself: name yours apart'],
 ['first-foreign-error',[type('T','First'),type('U','Second'),def('Second'),def('First')],collision('Second')],
 ['base-foreign-collision',[type('T','Tick'),def('Tick','Def','Foreign',[],true)],collision('Tick')],
];
const report={kind:'phase24-emission-ownership-controls',api:m.api,inputs:[identity(import.meta.filename),identity(path.join(attempt,'attempt.json'))],rows:[],pass:false};
try {for(const [name,book,expected] of cases){const actual=api.driver_emit_owned(list(book));report.rows.push({name,actual,expected,pass:actual===expected});assert.equal(actual,expected,name);}await verifyAttempt(attempt);report.inputs.forEach(verifyIdentity);report.pass=true;}
catch(e){report.error=String(e.stack);process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,rows:report.rows.length,error:report.error}));
