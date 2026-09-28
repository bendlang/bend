import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
const [upstream,baselineFile,candidateFile,output]=process.argv.slice(2);
const B=await import(pathToFileURL(path.resolve(upstream,'bend2/bend.ts')));
const baseline=await import(pathToFileURL(path.resolve(baselineFile))),candidate=await import(pathToFileURL(path.resolve(candidateFile)));
const list=xs=>xs.reduceRight((tail,head)=>({$: 'Con',head,tail}),{$:'Nil'});
const v=i=>({tag:'Var',name:'x',id:i,kids:[]});
const c=(name,...kids)=>({tag:'Ctr',name,id:0,kids});
const ann=x=>({tag:'Ann',name:'',id:0,kids:[x,c('TypeDummy')]});
const cell=(i,x)=>({tag:'Var',name:'x',id:i,kids:[x]});
const k=t=>({$:'KTerm',tag:t.tag,name:t.name,id:t.id,quant:1,kids:list(t.kids.map(k)),removed:list([])});
function u(t){if(t.tag==='Var')return B.Var(t.name,t.id,undefined,t.kids.length?u(t.kids[0]):undefined);if(t.tag==='Ann')return B.Ann(u(t.kids[0]),u(t.kids[1]));return B.Ctr(t.name,t.kids.map(u))}
const nat=n=>{let x=c('Zero');while(n--)x=c('Succ',x);return x};
function word(n){let x=c('WNil');for(let i=31;i>=0;i--)x=c('WCon',c((n>>>i)&1?'True':'False'),x);return c('U32',x)}
const str=s=>[...s].reduceRight((t,h)=>c('SCon',c('Chr',word(h.codePointAt(0))),t),c('SNil'));
const rows=[];
function observe(id,a,p,q=1,includeBaseline=true){const expected={LT:0,EQ:1,GT:2}[B.term_descend(q===0?B.None():q===1?B.Lone():B.Many(),u(a),u(p))];const got=candidate.p9Descent(q,k(a),k(p));const before=includeBaseline?baseline.p9Descent(q,k(a),k(p)):null;rows.push({id,q,expected,candidate:got,baseline:before,pass:got.value===expected&&!got.error})}
const leaf=c('Leaf'),x=v(0),y=v(1);
for(const [id,a,p] of [
 ['equal-var',x,x],['other-var',x,y],['empty-ctor',leaf,leaf],['other-head',leaf,c('Other')],
 ['wrong-arity',c('Pair',x),c('Pair',x,y)],['proper-tail',x,c('Pair',y,x)],
 ['failed-first-other-field',c('Pair',x,y),c('Pair',y,c('Pair',x,y))],
 ['failed-last-other-field',c('Pair',x,y),c('Pair',c('Pair',x,y),x)],
 ['ann-strip',ann(x),ann(c('Box',x))],['cell-strip',cell(9,x),c('Box',x)],
 ['erased-divergent-shape',c('A',x),y],['same-suffix',str('b'),str('ab')],
 ['equal-string',str('ab'),str('ab')],['increasing-string',str('abc'),str('ab')],
]){observe(id,a,p);observe(id+'-erased',a,p,0)}
let seed=0x93c72a11;const random=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n};
function tree(depth){if(!depth||random(4)===0)return random(2)?v(random(3)):c('K'+random(3));const n=random(3);return c('K'+random(3),...Array.from({length:n},()=>tree(depth-1)))}
for(let i=0;i<300;i++)observe('seeded-'+i,tree(3),tree(3),i%3);
for(const n of [4,8,12,16,32,64,128])for(const delta of [-1,0,1])observe('nat-'+n+'-'+delta,nat(n+delta),nat(n),1,true);
for(const [id,qs,args,cols,expected] of [
 ['lexicographic-equal-then-smaller',[1,1],[x,nat(2)],[x,nat(3)],true],
 ['lexicographic-larger-first',[1,1],[nat(4),nat(2)],[nat(3),nat(3)],false],
 ['lexicographic-erased-first',[0,1],[nat(4),nat(2)],[nat(3),nat(3)],true],
 ['lexicographic-all-equal',[1,1],[x,y],[x,y],false],
]){const terms=qs.map(q=>({$:'KTerm',tag:'Qua',name:'',id:0,quant:q,kids:list([]),removed:list([])}));const got=candidate.p9Spine(list(terms),list(args.map(k)),list(cols.map(k)));rows.push({id,expected,candidate:got,pass:got===expected})}
const report={purpose:'Structural parity and bounded call-count observations; concurrent runs are not controlled timing',seed:'0x93c72a11',count:rows.length,pass:rows.every(r=>r.pass),rows};
fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({count:report.count,pass:report.pass,failures:rows.filter(r=>!r.pass)}));if(!report.pass)process.exitCode=1;
