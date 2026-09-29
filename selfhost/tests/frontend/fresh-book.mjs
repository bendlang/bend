// Declaration-list breadth and nested constructor books must not use host stack.
import assert from 'node:assert/strict';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const project=path.resolve(import.meta.dirname,'../..');
const module=await import(pathToFileURL(process.env.BEND_FRONT_API||path.join(project,'build/fresh-book.mjs')));
// Run the same regression against either bootstrap or self-generated libraries.
const {convertCompilerAbi}=await import('../../tools/typed-driver.mjs');
const fields={Nil:[],Con:['head','tail'],KTerm:['tag','name','id','quant','kids','removed','originBegin','originEnd'],KLambda:['name','id','quant','kids','removed','originBegin','originEnd','quantityPresent'],KDef:['name','kind','arity','templates','typ','value','ctors','native','unsafe'],FFreshDefs:['defs','next']};
const convert=(value,encode)=>convertCompilerAbi(value,encode,fields,module.ctor);
const api=module.G?{f_fresh_defs:(...args)=>convert(module.default.f_fresh_defs(...convert(args,true)),false)}:module.default;
const nil={$:'Nil'},list=a=>a.reduceRight((tail,head)=>({$:'Con',head,tail}),nil),array=x=>{let a=[];for(;x.$==='Con';x=x.tail)a.push(x.head);return a};
const term=(tag,id=0,kids=[])=>(tag==='Lam'?{$:'KLambda',name:'x',id,quant:1,kids:list(kids),removed:nil,originBegin:0,originEnd:0,quantityPresent:true}:{$:'KTerm',tag,name:'x',id,quant:1,kids:list(kids),removed:nil,originBegin:0,originEnd:0});
const leaf=term('Typ'),typ=term('All',77,[leaf,term('Var',77)]),body=term('Lam',77,[term('Var',77)]);
const def=(name,ctors=nil)=>({$:'KDef',name,kind:'Def',arity:1,templates:0,typ,value:body,ctors,native:false,unsafe:false});
function reference(book,next){function t(x,env){let xs=array(x.kids);if(x.tag==='Var')return {...x,id:env.get(x.id)??x.id};if(x.tag==='All'){let id=next++,a=t(xs[0],env),e=new Map(env);e.set(x.id,id);return {...x,id,kids:list([a,t(xs[1],e)])}}if(x.$==='KLambda'){let id=next++,e=new Map(env);e.set(x.id,id);return {...x,id,kids:list([t(xs[0],e)])}}return {...x,kids:list(xs.map(k=>t(k,env)))}}function defs(ds){return list(array(ds).map(d=>({...d,typ:t(d.typ,new Map()),value:t(d.value,new Map()),ctors:defs(d.ctors)})))}let out=defs(book);return {$:'FFreshDefs',defs:out,next}}
const small=list([def('outer',list([def('first'),def('second',list([def('nested')]))])),def('tail')]);
assert.deepEqual(api.f_fresh_defs(small,100),reference(small,100),'types, values, constructors, then following declaration allocation order');
const count=20000;let large=nil;for(let i=count-1;i>=0;i--)large={$:'Con',head:def('d'+i),tail:large};let r=api.f_fresh_defs(large,1);assert.equal(r.next,count*2+1);let i=0;for(let p=r.defs;p.$==='Con';p=p.tail,i++){assert.equal(p.head.name,'d'+i);assert.equal(p.head.typ.id,i*2+1);assert.equal(p.head.value.id,i*2+2)}assert.equal(i,count);
let nested=nil;for(let i=0;i<12000;i++)nested=list([def('nested'+i,nested)]);r=api.f_fresh_defs(nested,1);assert.equal(r.next,24001);let depth=0;for(let p=r.defs;p.$==='Con';p=p.head.ctors)depth++;assert.equal(depth,12000);
console.log('exact type/value/constructor allocation; 20,000 declarations; 12,000 nested constructor books: pass');
