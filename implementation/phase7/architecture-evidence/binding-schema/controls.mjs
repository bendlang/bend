import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [apiFile,output]=process.argv.slice(2);
if(!apiFile||!output||fs.existsSync(output))throw Error('API and fresh output required');
const bytes=fs.readFileSync(apiFile),sha=b=>createHash('sha256').update(b).digest('hex');
const {default:api}=await import(pathToFileURL(path.resolve(apiFile)));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const array=xs=>{const out=[];for(;xs.$==='Con';xs=xs.tail)out.push(xs.head);return out};
const t=(tag,name='',id=0,quant=0,kids=[],removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed)});
const v=id=>t('Var','v'+id,id),atom=name=>t('Ctr',name),lam=(id,body)=>t('Lam','b',id,1,[body]);
const app=(f,x)=>t('App','',0,0,[f,x]);
const rows=[];
function test(name,fn){try{fn();rows.push({name,pass:true})}catch(error){rows.push({name,pass:false,error:String(error.stack??error)})}}
let seed=1729;
const random=n=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed%n};
function tree(depth){
  if(!depth)return random(2)?v(random(6)):atom('A'+random(3));
  const id=random(6);
  switch(random(6)){
    case 0:return lam(id,tree(depth-1));
    case 1:return t('All','p',id,random(3),[tree(depth-1),tree(depth-1)]);
    case 2:return t('Let','',0,1,[t('Bind','x',id,2,[tree(depth-1)]),t('Bind','y',id+1,0,[tree(depth-1)]),app(v(id),v(id+1))]);
    case 3:return app(tree(depth-1),tree(depth-1));
    case 4:return t('ADT','D',37,2,[tree(depth-1)],['Removed']);
    default:return t('Sub','map',id,2,[tree(depth-1)]);
  }
}
const fixtures=[
  ['shadow',lam(9,lam(9,v(9)))],
  ['dependent-domain',t('All','x',9,0,[lam(8,v(8)),app(v(9),v(8))])],
  ['parallel-scope',lam(7,t('Let','',0,1,[t('Bind','x',7,2,[v(7)]),t('Bind','y',8,1,[v(7)]),app(v(7),v(8))]))],
  ['empty-let',t('Let')],
  ['let-body-only',t('Let','strange',333,2,[v(4)],['R'])],
  ['var-payload',t('Var','x',9,2,[atom('Payload')],['R'])],
  ['lambda-metadata',t('Lam','x',9,2,[v(9),atom('Ignored')],['R'])],
  ['all-metadata',t('All','x',9,2,[v(4),v(9),atom('Ignored')],['R'])],
  ['empty-lambda',t('Lam','x',9,2)],
  ['open-beta',app(lam(9,v(9)),v(7))],
];
for(let i=0;i<150;i++)fixtures.push(['seeded-'+i,tree(3+random(2))]);
for(const [name,term] of fixtures){
  const inputBefore=sha(JSON.stringify(term));
  for(const env of [nil,list([t('Map','',9,0,[v(1001)])])]){
    test('fresh:'+name+':'+(env===nil?'empty':'supplied'),()=>assert.deepEqual(api.a3_fresh(term,env,100),api.f_fresh_term(term,env,100)));
  }
  for(const offset of [0,17,0xfffffff0])test('shift:'+name+':'+offset,()=>assert.deepEqual(api.a3_shift(term,offset),api.sp_shift(term,offset)));
  test('immutable:'+name,()=>assert.equal(sha(JSON.stringify(term)),inputBefore));
}
test('parallel independent expected result',()=>{
  const term=t('Let','',0,1,[t('Bind','x',7,2,[v(7)]),t('Bind','y',8,1,[v(7)]),app(v(7),v(8))]);
  const result=api.a3_fresh(term,nil,100),kids=array(result.term.kids);
  assert.equal(result.next,102);assert.equal(kids[0].id,100);assert.equal(kids[1].id,101);
  assert.equal(kids[0].kids.head.id,7);assert.equal(kids[1].kids.head.id,7);
  assert.equal(kids[2].kids.head.id,100);assert.equal(kids[2].kids.tail.head.id,101);
});
test('fresh deep constructors 50000',()=>{
  let term=atom('End');for(let i=0;i<50000;i++)term=t('Ctr','Next',0,0,[term]);
  for(const run of [api.f_fresh_term,api.a3_fresh]){let out=run(term,nil,1),n=0;assert.equal(out.next,1);for(let x=out.term;x.name==='Next';x=x.kids.head)n++;assert.equal(n,50000)}
});
test('fresh nested shadows 12000',()=>{
  let term=v(9);for(let i=0;i<12000;i++)term=lam(9,term);
  for(const run of [api.f_fresh_term,api.a3_fresh]){let out=run(term,nil,1);assert.equal(out.next,12001);let x=out.term;for(let i=1;i<=12000;i++){assert.equal(x.id,i);x=x.kids.head}assert.equal(x.id,12000)}
});
test('shift deep constructors 50000 independent expected',()=>{
  let term=v(9);for(let i=0;i<50000;i++)term=t('Ctr','Next',0,0,[term]);
  let out=api.a3_shift(term,17),n=0;for(;out.tag==='Ctr';out=out.kids.head)n++;
  assert.equal(n,50000);assert.equal(out.id,26);
});
test('fresh parallel breadth 15000',()=>{
  const fields=[];for(let i=0;i<15000;i++)fields.push(t('Bind','b',i+50000,1,[atom('Unit')]));
  const term=t('Let','',0,1,[...fields,v(64999)]);
  for(const run of [api.f_fresh_term,api.a3_fresh]){const out=run(term,nil,1);assert.equal(out.next,15001);const kids=array(out.term.kids);for(let i=0;i<15000;i++)assert.equal(kids[i].id,i+1);assert.equal(kids[15000].id,15000)}
});
const report={scope:'freshening and template-ID shift only; no substitution, checker, whole compiler or fixed-point claim',apiSha256:sha(bytes),harnessSha256:sha(fs.readFileSync(import.meta.filename)),seed:1729,fixtures:fixtures.length,pass:rows.every(x=>x.pass),rows};
assert.equal(sha(fs.readFileSync(apiFile)),report.apiSha256);
fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,rows:rows.length,failures:rows.filter(x=>!x.pass)}));
process.exitCode=report.pass?0:1;
