// Actual compiled constructor index compared with an independent authentic recursive parent.
import fs from 'node:fs';import {pathToFileURL} from 'node:url';import assert from 'node:assert/strict';
const [parentFile,candidateFile,casesFile,expectedFile,out]=process.argv.slice(2);
const parent=(await import(pathToFileURL(parentFile))).__ctorIndexProbe,candidate=(await import(pathToFileURL(candidateFile))).__ctorIndexProbe;
const cases=JSON.parse(fs.readFileSync(casesFile)),pubExpected=JSON.parse(fs.readFileSync(expectedFile));
const nil=()=>({$:'Nil'}),list=a=>a.reduceRight((tail,head)=>({$:'Con',head,tail}),nil());
const array=xs=>{const a=[];for(let p=xs;p.$==='Con';p=p.tail)a.push(p.head);return a;};
const term=(tag,name='',kids=[],begin=0,end=0)=>({$:'KTerm',tag,name,id:0,quant:1,kids:list(kids),removed:nil(),originBegin:begin,originEnd:end});
const miss=name=>({$:'KDef',name,kind:'Missing',arity:0,templates:0,typ:{...term('Absent'),quant:0},value:{...term('Absent'),quant:0},ctors:nil(),native:false,unsafe:false});
function forest(specs){const refs=new Map();function make(s){const i=refs.size,d={$:'KDef',name:s.name,kind:s.kind,arity:s.arity??i,templates:i%3,typ:term('Ref','type:'+s.id),value:term('Ref','value:'+s.id),ctors:nil(),native:i%2===1,unsafe:i%3===1};refs.set(s.id,d);d.ctors=list((s.children??[]).map(make));return d;}return {book:list(specs.map(make)),refs};}
const idOf=d=>d.kind==='Missing'?null:d.typ.name.slice(5);
const rows=[];
function check(name,category,fn){try{rows.push({name,category,pass:true,...fn()});}catch(e){rows.push({name,category,pass:false,error:{name:e?.name??typeof e,message:e?.message??String(e),stack:e?.stack}});}}
for(const c of cases.initial)check(c.name,'initial',()=>{
 let specs=c.forest;if(c.width)specs=Array.from({length:c.width},(_,i)=>({id:'wide'+i,name:'N'+i,kind:'Def',children:[]}));
 if(c.depth){let d={id:'deep-hit',name:'X',kind:'Ctr',children:[]};for(let i=0;i<c.depth;i++)d={id:'deep'+i,name:'N'+i,kind:'ADT',children:[d]};specs=[d];}
 const {book,refs}=forest(specs),tree=candidate.build(book),observations=[];
 if(c.collision)assert.equal(candidate.hash(c.collision[0]),candidate.hash(c.collision[1]),'fixture must hit a full hash collision');
 for(const q of c.queries??[{query:c.query,expected:c.expectedDeep?'deep-hit':c.expected}]){
  const before=parent.raw(q.query,book),after=candidate.find(q.query,tree),own=candidate.raw(q.query,book),expected=q.expected==null?miss(q.query):refs.get(q.expected);
  assert.deepEqual(before,expected,'independent expected parent');assert.deepEqual(after,before,'indexed value');assert.deepEqual(own,before,'raw helper retained');
  if(q.expected!=null){assert.equal(before,expected,'parent original definition identity');assert.equal(after,expected,'indexed original definition identity');assert.equal(own,expected,'candidate original definition identity');}
  observations.push({query:q.query,expectedId:q.expected??null,actualId:idOf(after),value:after,originalReference:q.expected==null?null:after===expected});
 }
 return {observations};
});
for(const c of cases.publication)check(c.name,'publication',()=>{
 const {book}=forest(c.forest),aliases=list(c.aliases.map(a=>term('Import',a.to,[term('Alias',a.from)])));
 let ps={$:'FParseScope',prior:book,index:parent.ordinary(list(array(book).reverse())),ns:c.ns,aliases};
 let cs={$:'FParseScope',prior:book,index:candidate.ordinary(list(array(book).reverse())),ctors:candidate.build(book),ns:c.ns,aliases};
 const states=[],snapshots=[];
 function inspect(stage){
  assert.deepEqual(cs.prior,ps.prior,'published prior');assert.deepEqual(cs.index,ps.index,'ordinary index');assert.deepEqual(cs.ns,ps.ns);assert.deepEqual(cs.aliases,ps.aliases);
  const observations=c.queries.map((name,i)=>{const a=candidate.find(name,cs.ctors),b=parent.raw(name,ps.prior),raw=candidate.raw(name,cs.prior);assert.deepEqual(a,b,'parent publication result');assert.deepEqual(a,raw,'current prior result');assert.equal(idOf(a),pubExpected[c.name][stage][i],'independent publication winner');if(a.kind!=='Missing')assert.equal(a,raw,'published definition reference');return {name,value:a,expectedId:pubExpected[c.name][stage][i]};});
  snapshots.push({scope:cs,bytes:JSON.stringify(cs),values:c.queries.map(n=>candidate.find(n,cs.ctors))});states.push({stage,observations});
 }
 inspect(0);
 for(let i=0;i<c.declarations.length;i++){
  const d=forest([c.declarations[i]]).book.head,old=cs;ps=parent.declare(d,ps);cs=candidate.declare(d,cs);
  assert.equal(cs.ctors===old.ctors,c.reuse[i],'exact ctor-index reuse policy');inspect(i+1);
  for(const snapshot of snapshots){assert.equal(JSON.stringify(snapshot.scope),snapshot.bytes,'old scope mutated');for(let j=0;j<c.queries.length;j++)assert.deepEqual(candidate.find(c.queries[j],snapshot.scope.ctors),snapshot.values[j],'old index lookup changed');}
 }
 return {states,oldScopesUnchanged:true};
});
for(const c of cases.patterns)check(c.name,'pattern',()=>{
 const {book}=forest(c.forest),p=term(c.tag,c.nameText,Array.from({length:c.fields},(_,i)=>term('Var','v'+i)),31,37),a=candidate.find(c.nameText,candidate.build(book)),b=parent.raw(c.nameText,book);
 const before=(c.tag==='Var'?parent.validVar:parent.validCtor)(p,b),after=(c.tag==='Var'?candidate.validVar:candidate.validCtor)(p,a);assert.deepEqual(after,before);assert.equal(after.$,c.expected);return {original:before,indexed:after};
});
check(cases.demand[0],'demand',()=>{
 const {book,refs}=forest([{id:'holder',name:'T',kind:'ADT',children:[{id:'child',name:'X',kind:'Ctr',children:[]}]}]);let reads=0;
 for(const d of refs.values())for(const key of ['typ','value','arity','templates','native','unsafe'])Object.defineProperty(d,key,{get(){reads++;throw new Error('unexpected payload read '+key);},enumerable:true});
 const tree=candidate.build(book);assert.equal(candidate.find('X',tree),refs.get('child'));assert.equal(candidate.find('missing',tree).kind,'Missing');assert.equal(reads,0);return {payloadReads:reads};
});
check(cases.demand[1],'demand',()=>{
 const {book,refs}=forest([{id:'holder',name:'T',kind:'ADT',children:[{id:'child',name:'X',kind:'Ctr',children:[]}]},{id:'other',name:'Y',kind:'Ctr',children:[]}]);let forbidden=false,reads=0;
 function guard(xs){let p=xs;while(p.$==='Con'){const h=p.head,t=p.tail;for(const [key,value] of [['$','Con'],['head',h],['tail',t]])Object.defineProperty(p,key,{get(){if(forbidden){reads++;throw new Error('original forest rewalk '+key);}return value;},enumerable:true});guard(h.ctors);p=t;}Object.defineProperty(p,'$',{get(){if(forbidden){reads++;throw new Error('original forest rewalk Nil');}return 'Nil';},enumerable:true});}
 guard(book);const tree=candidate.build(book);forbidden=true;assert.equal(candidate.find('X',tree),refs.get('child'));assert.equal(candidate.find('Y',tree),refs.get('other'));assert.equal(candidate.find('absent',tree).kind,'Missing');assert.equal(reads,0);return {postBuildOriginalListReads:reads};
});
const report={kind:'phase22-actual-constructor-index-controls',complete:true,pass:rows.every(r=>r.pass),resources:{execArgv:process.execArgv},counts:rows.reduce((o,r)=>(o[r.category]=(o[r.category]??0)+1,o),{}),rows};fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:true,pass:report.pass,cases:rows.length,failures:rows.filter(r=>!r.pass).map(r=>({name:r.name,error:r.error.message}))}));process.exitCode=report.pass?0:1;
