import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
const root=path.resolve(import.meta.dirname,'../../../..'),out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const pin=path.join(root,'selfhost/.bootstrap/upstream-phase8'),ts=path.join(pin,'bend2/bend.ts'),base=path.join(pin,'bend2/base.bend'),fixture=path.join(pin,'tests/comptime/err_grow_double.bend');
const apiFiles=['05','06'].map(v=>path.join(root,`selfhost/build/phase16/checker-key-probe-build-${v}/equality/api.mjs`));
const inputs=[import.meta.filename,process.execPath,ts,base,fixture,...apiFiles].map(identity);
const sha=s=>crypto.createHash('sha256').update(s).digest('hex');
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const array=xs=>{const a=[];for(;xs.$==='Con';xs=xs.tail)a.push(xs.head);return a;};
const report={kind:'phase16-memo-key-length-boundary',complete:false,inputs,implementations:[]};
const raw={};
function findCall(t,name,local){
 if(!t||typeof t!=='object')return;
 const tag=local?t.tag:t.$;
 if(tag==='App'){
  const args=[];let h=t;
  while((local?h.tag:h.$)==='App'){const kids=local?array(h.kids):null;args.unshift(local?kids[1]:h.x);h=local?kids[0]:h.f;}
  if((local?h.tag:h.$)==='Ref'&&(local?h.name:h.k)===name)return args;
 }
 if(local){for(const child of array(t.kids||{$:'Nil'})){const found=findCall(child,name,true);if(found)return found;}}
 else for(const [k,v] of Object.entries(t))if(k!=='s'){for(const child of Array.isArray(v)?v:[v]){const found=findCall(child,name,false);if(found)return found;}}
}
function count(t,local,counts={}){
 const tag=local?t.tag:t.$;if(typeof tag!=='string')return counts;counts[tag]=(counts[tag]||0)+1;
 const kids=local?array(t.kids):Object.entries(t).filter(([k])=>k!=='s').flatMap(([,v])=>Array.isArray(v)?v:[v]).filter(v=>v&&typeof v==='object'&&v.$);
 for(const child of kids)count(child,local,counts);return counts;
}
try{
 const B=await import(pathToFileURL(ts)),book=B.book_nil();await B.book_load(book,fixture,'',new Map());const originalMain=book.tlds.main,originalGrow=book.tlds.grow;
 let error;try{B.book_valid(book);}catch(e){error=e;}
 assert.equal(error?.$,'Err');assert.equal(error.def,'grow~9');
 const stored=Object.entries(book.tmps.grow).map(([key,name])=>({name,key})).sort((a,b)=>Number(a.name.split('~').at(-1))-Number(b.name.split('~').at(-1)));
 let arg=B.term_higher(findCall(B.term_lower(originalMain.v),'grow',false)[0]);const sequence=[];
 for(let i=0;i<13;i++){
  const lower=B.term_lower(arg),key=B.term_key(lower);sequence.push({level:i,key,counts:count(lower,false)});
  if(i<stored.length)assert.equal(key,stored[i].key);
  if(key.length>32768)break;
  const body=B.term_lower(B.term_apply(originalGrow.v,arg));const next=findCall(body,'grow',false);assert.ok(next?.length);arg=B.term_higher(next[0]);
 }
 assert.ok(sequence.at(-1).key.length>32768);
 raw.typescript={stored,sequence};report.implementations.push({name:'typescript',error:B.err_show(error),stored:stored.length,firstOverLimit:sequence.at(-1).level,sequence:sequence.map(({level,key,counts})=>({level,utf16Length:key.length,bytes:Buffer.byteLength(key),sha256:sha(key),counts}))});
 for(let apiIndex=0;apiIndex<apiFiles.length;apiIndex++){
  const api=(await import(pathToFileURL(apiFiles[apiIndex]))).default;
  const sources=list([{$:'FSource',name:fixture,path:fixture,text:fs.readFileSync(fixture,'utf8')},{$:'FSource',name:'Base',path:base,text:fs.readFileSync(base,'utf8')}]);
  const parsed=api.f_load_graph(fixture,sources);assert.equal(parsed.error,'');assert.equal(api.check_book(parsed.book),'');
  const defs=array(parsed.book),grow=defs.find(d=>d.name==='grow'),main=defs.find(d=>d.name==='main');
  const initial=api.sp_initial(api.sp_canonical(parsed.book,list([])),api.norm_max_book(parsed.book));
  const state=api.sp_definitions(parsed.book,initial);
  const stored=array(state.memo).filter(m=>m.template==='grow').map(m=>({name:m.name,key:m.key,active:m.active})).sort((a,b)=>Number(a.name.split('~').at(-1))-Number(b.name.split('~').at(-1)));
  let arg=findCall(main.value,'grow',true)[0],fresh=initial.fresh;
  const increment=Math.max(api.norm_max_term(grow.typ),api.norm_max_term(grow.value))+1,sequence=[];
  for(let i=0;i<13;i++){
   const key=api.sp_keys(list([arg]));assert.equal(key,api.term_key(arg));const bendLength=api.sp_len(key);
   sequence.push({level:i,key,bendLength,counts:count(arg,true)});
   if(i<stored.length)assert.equal(key,stored[i].key);
   if(bendLength>32768)break;
   const body=api.sp_apply_template(api.sp_shift(grow.value,fresh),list([arg]));fresh+=increment;
   const next=findCall(body,'grow',true);assert.ok(next?.length);arg=next[0];
  }
  assert.ok(sequence.at(-1).bendLength>32768);
  const name=apiIndex===0?'ordinal-only-05':'scoped-key-06';raw[name]={stored,sequence};report.implementations.push({name,error:state.error.error,stored:stored.length,firstOverLimit:sequence.at(-1).level,sequence:sequence.map(({level,key,bendLength,counts})=>({level,utf16Length:key.length,bendLength,bytes:Buffer.byteLength(key),sha256:sha(key),counts}))});
 }
 inputs.forEach(verifyIdentity);report.complete=true;
 report.pass=report.implementations.length===3;
}catch(error){report.error=error.stack||String(error);process.exitCode=1;}
fs.writeFileSync(path.join(out,'raw-keys.json'),JSON.stringify(raw,null,2)+'\n');
report.rawKeys=identity(path.join(out,'raw-keys.json'));
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({complete:report.complete,pass:report.pass,implementations:report.implementations.map(x=>({name:x.name,stored:x.stored,firstOverLimit:x.firstOverLimit})),error:report.error}));
