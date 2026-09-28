// Disposable generated-JS instrumentation: counts only, never timing evidence.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [componentArg,outputArg]=process.argv.slice(2),component=fs.realpathSync(componentArg),output=path.resolve(outputArg);
fs.mkdirSync(output,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const original=identity(component),script=identity(import.meta.filename);
const report={kind:'chronological-bound-counter',started:new Date().toISOString(),hypothesis:'Alpha-renamed law fills compare against an uncached seen book and repeatedly scan earlier bodies.',scope:'Derived instrumentation of checked component; explanatory counts only, not compiler provenance or timing.',original,script,rows:[]};
fs.writeFileSync(path.join(output,'plan.json'),JSON.stringify(report,null,2)+'\n');
const instrumentation=`
export const phase9Counts = {maxBooks:[], compareKinds:{}};
function phase9BookShape(book) {
  let definitions=0,termNodes=0;const ds=[],ts=[];
  for(let x=book;x.$==='Con';x=x.tail)ds.push(x.head);
  while(ds.length){const d=ds.pop();definitions++;ts.push(d.typ,d.value);for(let x=d.ctors;x.$==='Con';x=x.tail)ds.push(x.head);}
  while(ts.length){const t=ts.pop();termNodes++;for(let x=t.kids;x.$==='Con';x=x.tail)ts.push(x.head);}
  return {head:book.$==='Con'?book.head.kind:'Nil',definitions,termNodes};
}
`;
let source=fs.readFileSync(component,'utf8');
const hooks=[
  ['function $norm_max_book$(_book_0) {','phase9Counts.maxBooks.push(phase9BookShape(_book_0));'],
  ['function $compare$(_book_0, _a_0, _b_0, _le_0) {','const kind=_book_0.$===\"Con\"?_book_0.head.kind:\"Nil\";phase9Counts.compareKinds[kind]=(phase9Counts.compareKinds[kind]??0)+1;'],
];
for(const [head,body] of hooks){assert.equal(source.split(head).length,2,'Unique hook '+head);source=source.replace(head,head+'\n  '+body);}
const derived=path.join(output,'counted-component.mjs');fs.writeFileSync(derived,instrumentation+source);report.derived=identity(derived);report.hooks=hooks;
const {default:K}=await import(pathToFileURL(component));
const {default:C,phase9Counts}=await import(pathToFileURL(derived));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const t=(tag,name='',id=0,quant=0,kids=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:nil});
const typ=q=>t('Typ','',0,0,[t('Qua','',0,q)]),adt=t('ADT','Bool');
const d=(name,type,value=t('Absent'),arity=0,kind='Def',ctors=[])=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native:false,unsafe:false});
const bool=d('Bool',typ(2),t('Absent'),0,'ADT',[d('True',adt,t('Absent'),0,'Ctr'),d('False',adt,t('Absent'),0,'Ctr')]);
for(const size of [4,8,16]){
  const defs=[bool];
  for(let i=0;i<size;i++){
    const ty=id=>t('All','x',id,1,[adt,adt]);
    defs.push(d('f'+i,ty(100+3*i),t('Absent'),1));
    defs.push(d('f'+i,ty(101+3*i),t('Lam','x',10000+i,1,[t('Var','x',10000+i)]),1));
  }
  const book=list(defs),inputHash=createHash('sha256').update(JSON.stringify(book)).digest('hex');
  const ordinary=K.check_book(book);assert.equal(ordinary,'');phase9Counts.maxBooks.length=0;phase9Counts.compareKinds={};
  const counted=C.check_book(book);assert.equal(counted,ordinary);
  assert.equal(createHash('sha256').update(JSON.stringify(book)).digest('hex'),inputHash);
  report.rows.push({size,inputHash,ordinary,counted,maxBooks:structuredClone(phase9Counts.maxBooks),compareKinds:{...phase9Counts.compareKinds},maxBookCalls:phase9Counts.maxBooks.length,termNodesAcrossBookScans:phase9Counts.maxBooks.reduce((s,b)=>s+b.termNodes,0)});
}
report.unchangedOriginal=identity(component).sha256===original.sha256;assert(report.unchangedOriginal);assert.equal(identity(import.meta.filename).sha256,script.sha256);
report.pass=true;report.finished=new Date().toISOString();fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report.rows.map(({size,maxBookCalls,termNodesAcrossBookScans,compareKinds})=>({size,maxBookCalls,termNodesAcrossBookScans,compareKinds}))));
