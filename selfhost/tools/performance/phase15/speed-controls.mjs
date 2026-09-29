// Finite independent lookup semantics and observable demand-order controls.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
const [beforeArg,afterArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);
const before=(await import(pathToFileURL(path.resolve(beforeArg)))).default,after=(await import(pathToFileURL(path.resolve(afterArg)))).default;
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const atom={$:'KTerm',tag:'Absent',name:'',id:0,quant:0,kids:nil,removed:nil};
const def=(name,value=1,kind='Def')=>({$:'KDef',name,kind,arity:value,templates:0,typ:atom,value:atom,ctors:nil,native:false,unsafe:false});
const missing=def('',0,'Absent');
const cases=[];const add=(name,run)=>cases.push([name,run]);
for(const names of [[],['a'],['a','b','c'],['dup','other','dup'],['','a',''],['costarring','liquid'],['__proto__','constructor','α','🦀','a\0b']]){
 const raw=list(names.map((n,i)=>def(n,i+1)));
 for(const key of [...new Set(names),'absent'])for(const cached of [false,true])add(JSON.stringify({names,key,cached}),k=>k.lookup(cached?k.book_cached(raw,77):raw,key));
}
add('noncanonical definition kind still matches',k=>k.lookup(list([def('a',2,'Other')]),'a'));
add('Absent-kind with nonempty name still matches',k=>k.lookup(list([def('a',2,'Absent')]),'a'));
add('empty raw name first wins',k=>k.lookup(list([def('',3),def('',7)]),''));
add('cache sentinel wins before matching own name',k=>{const c=k.book_cached(list([def('target',42)]),99).head;return k.lookup(list([{...c,name:'target'},def('target',5)]),'target')});
add('mid-list cache is consulted',k=>{const c=k.book_cached(list([def('target',42)]),99).head;return k.lookup(list([def('first',7),c,def('target',5)]),'target')});
add('mid-list cache miss does not search tail',k=>{const c=k.book_cached(nil,99).head;return k.lookup(list([def('first',7),c,def('target',5)]),'target')});
add('cached full-hash collision preserves exact key',k=>{assert.equal(k.index_hash('costarring',2166136261),k.index_hash('liquid',2166136261));return ['costarring','liquid','absent'].map(n=>k.lookup(k.book_cached(list([def('costarring',2),def('liquid',3)]),0),n))});
add('null book throws',k=>k.lookup(null,'a'));add('undefined book throws',k=>k.lookup(undefined,'a'));
add('malformed head throws',k=>k.lookup(list([null]),'a'));add('malformed tail after miss throws',k=>k.lookup({$:'Con',head:def('other'),tail:null},'a'));
add('malformed tail after hit is not traversed',k=>k.lookup({$:'Con',head:def('a'),tail:null},'a'));
add('wrong list tag retains projection behavior',k=>k.lookup({$:'Other',head:def('a'),tail:nil},'a'));
for(const key of ['\ud800','x\udfff','🦀',''])add('name comparison '+JSON.stringify(key),k=>k.lookup(list([def(key,1),def('other',2)]),key));
add('head and tail projection precede kind', (k,events)=>{const d=def('wanted',8);for(const field of ['kind','name']){const value=d[field];Object.defineProperty(d,field,{get(){events.push(field);return value}})}const book={$:'Con'};Object.defineProperty(book,'head',{get(){events.push('head');return d}});Object.defineProperty(book,'tail',{get(){events.push('tail');return nil}});return k.lookup(book,'wanted')});
add('kind failure precedes name comparison',(k,events)=>{const d=def('wanted');Object.defineProperty(d,'kind',{get(){events.push('kind');throw Error('kind-first')}});Object.defineProperty(d,'name',{get(){events.push('name');throw Error('name-later')}});return k.lookup(list([d]),'wanted')});
add('cache kind leaves own name and tail undemanded',(k,events)=>{const c=k.book_cached(list([def('wanted',4)]),0).head;Object.defineProperty(c,'name',{get(){events.push('name');throw Error('sentinel name')}});return k.lookup({$:'Con',head:c,tail:null},'wanted')});
add('ordinary miss reads names in declaration order',(k,events)=>{const ds=['a','b','wanted','later'].map((name,i)=>{const d=def(name,i);Object.defineProperty(d,'kind',{get(){events.push('kind:'+name);return 'Def'}});Object.defineProperty(d,'name',{get(){events.push('name:'+name);return name}});return d});return k.lookup(list(ds),'wanted')});
add('ordinary hit leaves later fields undemanded',(k,events)=>{const d=def('later');Object.defineProperty(d,'kind',{get(){events.push('later');throw Error('later forced')}});return k.lookup(list([def('wanted'),d]),'wanted')});
add('10000 definitions missing remains stack-safe',k=>k.lookup(list(Array.from({length:10000},(_,i)=>def('key'+i,i))),'missing'));
add('10000 definitions final hit remains stack-safe',k=>k.lookup(list(Array.from({length:10000},(_,i)=>def('key'+i,i))),'key9999'));
function observe(k,run){const events=[];try{return {ok:true,value:run(k,events),events}}catch(e){return {ok:false,name:e.name,message:e.message,events}}}
const report={kind:'phase15-lookup-source-demand-controls',complete:false,pass:false,scope:'Paired checked source components; finite raw-data/getter and source-structure controls, not B1, universal host-object or stack equivalence.',inputs:[import.meta.filename,beforeArg,afterArg,process.execPath].map(identity),rows:[]};
for(const [name,run]of cases){const a=observe(before,run),b=observe(after,run);let pass=true;try{assert.deepEqual(b,a)}catch{pass=false}report.rows.push({name,before:a,after:b,pass});}
report.inputs.forEach(verifyIdentity);report.complete=true;report.pass=report.rows.every(x=>x.pass);report.checks=report.rows.length;
fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({checks:report.checks,pass:report.pass,failures:report.rows.filter(x=>!x.pass).map(x=>x.name)}));if(!report.pass)process.exitCode=1;
