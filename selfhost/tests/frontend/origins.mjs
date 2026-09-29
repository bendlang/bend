// Isolated origin proof: actual source positions survive imports, beta
// substitution and global freshening; erased origins are not invented.
import assert from 'node:assert/strict';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const project=path.resolve(import.meta.dirname,'../..');
const {default:api}=await import(pathToFileURL(process.env.BEND_FRONT_API||path.join(project,'build/front-origins.mjs')));
const nil={$:'Nil'},list=a=>a.reduceRight((tail,head)=>({$:'Con',head,tail}),nil),array=x=>{const a=[];for(;x.$==='Con';x=x.tail)a.push(x.head);return a;};
const dep='# Unicode before the failing terms: 😀\ntype Flag is Data:\n  On{}\ntype OtherType is Data:\n  Other{}\ndef missing() -> Flag:\n  (x => x)(Missing)\ndef wrong() -> Flag:\n  Other{}\n';
const main='import ./dep.bend as D\ndef entry() -> D.Flag:\n  D.missing()\n';
const sources=list([{$:'FSource',name:'/origins/main.bend',path:'/origins/main.bend',text:main},{$:'FSource',name:'/origins/dep.bend',path:'/origins/dep.bend',text:dep}]);
const r=api.f_load_origins('/origins/main.bend',sources);assert.equal(r.result.error,'');
const unlocated=value=>Array.isArray(value)?value.map(unlocated):value&&typeof value==='object'?Object.fromEntries(Object.entries(value).filter(([k])=>!['originBegin','originEnd'].includes(k)).map(([k,v])=>[k,unlocated(v)])):value;
assert.deepEqual(unlocated(r.result),unlocated(api.f_load_graph('/origins/main.bend',sources)),'locations preserve the exact semantic graph');
const origins=array(r.origins),book=array(r.result.book);
assert.equal(origins.length,2);
assert.deepEqual(origins.map(o=>o.$),['DSourceOrigin','DSourceOrigin']);
for(const o of origins){assert.ok(o.begin>0);assert.equal(o.end-o.begin,o.source.length+1,'UTF16 source interval size');}
assert.ok(origins[0].end<=origins[1].begin,'source intervals do not overlap');
const terms=root=>{const out=[],todo=[root];while(todo.length){const t=todo.pop();if(!t||typeof t!=='object')continue;if(t.$==='KTerm')out.push(t);for(const v of Object.values(t))if(v&&typeof v==='object')todo.push(v);}return out;};
for(const [definition,name,text,token] of [['dep.missing','dep.Missing',dep,'Missing'],['dep.wrong','dep.Other',dep,'Other{}'],['entry','dep.missing',main,'D.missing']]){
 const owner=origins.find(o=>o.source===text),d=book.find(d=>d.name===definition);
 const found=terms(d.value).filter(t=>t.name===name);assert.equal(found.length,1,definition);const t=found[0];
 assert.equal(text.slice(t.originBegin-owner.begin,t.originEnd-owner.begin),token,definition+' exact token');
 assert.equal(t.originBegin-owner.begin,text.indexOf(token,definition==='dep.wrong'?text.indexOf('def wrong'):0),definition+' UTF16 offset');
}
// Interval provenance is source-owned, so the retained definition argument no
// longer filters records. This replaces the retired per-term DOrigin contract.
for(const name of ['dep.missing','dep.wrong','entry','not-a-definition'])assert.deepEqual(api.f_load_origins_for('/origins/main.bend',sources,name),r,'source intervals are independent of definition selection');
const raws=array(sources),located=(source,begin)=>({$:'FLocatedSource',source,begin,end:begin+source.text.length+1});
const overlap=api.f_load_origins('/origins/main.bend',list([located(raws[0],1),located(raws[1],2)]));
assert.equal(overlap.result.error,'overlapping source intervals');assert.deepEqual(overlap.origins,nil);
const changedAlias=api.f_load_origins('/origins/main.bend',list([located(raws[0],1),located({...raws[0],name:'alias'},1000)]));
assert.equal(changedAlias.result.error,'source alias ownership changed');assert.deepEqual(changedAlias.origins,nil);
console.log('semantic graph equality; imported beta-substituted reference; wrong constructor; qualified call; exact UTF16 token intervals; overlap and alias refusals: pass');
