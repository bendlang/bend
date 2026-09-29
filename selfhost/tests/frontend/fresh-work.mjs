// Compare alpha-renaming order and scopes with the original implementation,
// then traverse trees much deeper than the host call stack.
import assert from 'node:assert/strict';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const project=path.resolve(import.meta.dirname,'../..');
const {default:api}=await import(pathToFileURL(process.env.BEND_FRONT_API||path.join(project,'build/fresh-work.mjs')));
const nil={$:'Nil'},list=a=>a.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const term=(tag,name='',id=0,quant=1,kids=[],removed=[])=>(tag==='Lam'?{$:'KLambda',name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0,quantityPresent:true}:{$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
const v=id=>term('Var','v',id), app=(f,x)=>term('App','',0,1,[f,x]);
const array=x=>{const out=[];for(;x.$==='Con';x=x.tail)out.push(x.head);return out;};
const fresh=api.f_fresh_term||api.f_fresh_stack;
// Independent bounded reference preserves the former preorder allocation and
// lexical scoping rules. Deep cases below use only the Bend worklist routine.
function reference(root, first) {
  let next=first;
  function walk(t,env) {
    const kids=array(t.kids);
    if(t.tag==='Var')return env.has(t.id)?term('Var',t.name,env.get(t.id),t.quant):t;
    if(t.tag==='All') {const id=next++,a=walk(kids[0],env),inner=new Map(env);inner.set(t.id,id);return term('All',t.name,id,t.quant,[a,walk(kids[1],inner)]);}
    if(t.$==='KLambda') {const id=next++,inner=new Map(env);inner.set(t.id,id);return term('Lam',t.name,id,t.quant,[walk(kids[0],inner)]);}
    if(t.tag==='Let') {if(!kids.length)return term('Error','empty core let',0,0);const inner=new Map(env),out=[];for(const binding of kids.slice(0,-1)){const id=next++;out.push(term('Bind',binding.name,id,binding.quant,[walk(binding.kids.head,env)]));inner.set(binding.id,id)}return term('Let','',0,1,[...out,walk(kids.at(-1),inner)]);}
    return {...t,kids:list(kids.map(k=>walk(k,env)))};
  }
  const out=walk(root,new Map());return {$:'FFresh',term:out,next};
}
const cases=[
 term('All','x',90,0,[term('Typ','',0,0,[term('Qua','',0,2)]),term('Lam','x',90,2,[v(90)])]),
 term('Lam','outer',9,1,[term('Let','',0,1,[term('Bind','x',10,2,[v(9)]),term('Bind','y',11,0,[v(10)]),app(v(10),v(11))])]),
 term('ADT','Family',123,2,[term('Ctr','Payload',456,1,[v(77)])],['Removed']),
 term('Let','',0,1,[]),
];
for(let i=0;i<cases.length;i++)assert.deepEqual(fresh(cases[i],nil,100),reference(cases[i],100),'mixed case '+i);
let deep=term('Ctr','End');for(let i=0;i<50000;i++)deep=term('Ctr','Next',0,1,[deep]);
let output=fresh(deep,nil,1);assert.equal(output.next,1);let seen=0;for(let t=output.term;t.name==='Next';t=t.kids.head)seen++;assert.equal(seen,50000);
deep=v(99999);for(let i=0;i<12000;i++)deep=term('Lam','x',99999,1,[deep]);output=fresh(deep,nil,1);assert.equal(output.next,12001);let t=output.term;for(let i=1;i<=12000;i++){assert.equal(t.id,i);t=t.kids.head}assert.equal(t.id,12000);
const bindings=[];for(let i=0;i<15000;i++)bindings.push(term('Bind','b',i+50000,1,[term('Ctr','Unit')]));
output=fresh(term('Let','',0,1,[...bindings,v(64999)]),nil,1);assert.equal(output.next,15001);let rows=output.term.kids;for(let i=1;i<=15000;i++){assert.equal(rows.head.id,i);rows=rows.tail}assert.equal(rows.head.id,15000);
console.log('4 independent scope comparisons; 50,000 constructors; 12,000 shadowing binders; 15,000 parallel bindings: pass');
