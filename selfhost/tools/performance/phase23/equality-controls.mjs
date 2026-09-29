// Differential private conversion controls. No generated implementation edits.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [apiArg,upstreamArg,outArg]=process.argv.slice(2);
const api=fs.realpathSync(apiArg),upstream=fs.realpathSync(upstreamArg),out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs=[import.meta.filename,api,path.join(upstream,'bend2/bend.ts'),process.execPath].map(identity);
const K=(await import(pathToFileURL(api))).default,B=await import(pathToFileURL(path.join(upstream,'bend2/bend.ts')));
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const array=xs=>{const r=[];for(;xs.$==='Con';xs=xs.tail)r.push(xs.head);return r;};
const t=(tag,name='',id=0,quant=0,kids=[],removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
const v=id=>t('Var','x',id),lam=(id,body)=>t('Lam','x',id,2,[body]),app=(f,x)=>t('App','',0,0,[f,x]);
const ctr=(name,...xs)=>t('Ctr',name,0,0,xs),ref=name=>t('Ref',name),qua=q=>t('Qua','',0,q);
const kind=x=>t('Typ','',0,0,[x]),all=(id,a,b)=>t('All','x',id,1,[a,b]);
const meet=(a,b)=>t('Min','',0,0,[a,b]),adt=removed=>t('ADT','D',0,0,[],removed);
const def=(name,arity,value)=>({$:'KDef',name,kind:'Def',arity,templates:0,typ:t('Absent'),value,ctors:nil,native:false,unsafe:true});
const q=n=>[B.None(),B.Lone(),B.Many()][n];
function higher(x,env=new Map()){
 const k=array(x.kids),go=y=>higher(y,env),open=(id,body)=>arg=>higher(body,new Map([...env,[id,arg]]));
 switch(x.tag){
  case 'Var':return env.get(x.id)??B.Var(x.name,x.id);
  case 'Ref':return B.Ref(x.name);
  case 'Lam':return B.Lam(x.name,x.id,open(x.id,k[0]),undefined,q(x.quant));
  case 'All':return B.All(q(x.quant),x.name,x.id,go(k[0]),open(x.id,k[1]));
  case 'App':return B.App(go(k[0]),go(k[1]));
  case 'Typ':return B.Typ(go(k[0]));
  case 'Qua':return B.Qua(q(x.quant));
  case 'Min':return B.Min(go(k[0]),go(k[1]));
  case 'Ctr':return B.Ctr(x.name,k.map(go));
  case 'ADT':return B.ADT(x.name,k.map(go),undefined,array(x.removed));
  case 'Ann':return B.Ann(go(k[0]),go(k[1]));
  case 'Eql':return B.Eql(go(k[0]),go(k[1]),go(k[2]));
  case 'Rwt':return B.Rwt(go(k[0]),go(k[1]),go(k[2]));
  case 'Rfl':return B.Rfl();
  case 'Efq':return B.Efq();
  case 'Qnt':return B.Qnt();
  default:throw Error('Unreviewed control tag '+x.tag);
 }
}
function book(ds){const r=B.book_nil();for(const d of ds){r.order.push(d.name);r.tlds[d.name]={$: 'Def',n:d.arity,x:0,T:B.Qnt(),v:d.value.tag==='Absent'?null:higher(d.value),u:true};}return r;}
const A=ctr('A'),Z=ctr('Z'),cases=[];
const add=(name,a,b,le,expected,defs=[])=>cases.push({name,a,b,le,expected,defs});
const shared=(n,seed,base)=>{for(let i=0;i<n;i++){const id=base+i;seed=app(lam(id,ctr('Pair',v(id),v(id))),seed);}return seed;};
for(const n of [0,8,16,32,64]){
 add('shared graph equal depth '+n,shared(n,A,100),shared(n,A,300),false,true);
 add('shared graph unequal depth '+n,shared(n,A,100),shared(n,Z,300),false,false);
}
add('successful shared prefix does not hide later mismatch',ctr('Pair',shared(32,A,100),A),ctr('Pair',shared(32,A,300),Z),false,false);
add('shared lambda payload alpha',shared(16,lam(11,v(11)),100),shared(16,lam(12,v(12)),300),false,true);
add('shared lambda capture mismatch',shared(16,lam(11,lam(12,v(11))),100),shared(16,lam(13,lam(14,v(14))),300),false,false);
add('sharing begins after binder opens',lam(31,shared(16,v(31),100)),lam(32,shared(16,v(32),300)),false,true);
add('free variable survives binder opening',lam(31,shared(16,v(900000),100)),lam(32,shared(16,v(32),300)),false,false);
const sharedAll=(id,payload)=>app(lam(id,all(id+1,v(id),ctr('Box',v(id)))),payload);
add('LE fit never merges cells subsequently compared EQ',sharedAll(50,adt([])),sharedAll(60,adt(['Gone'])),true,false);
add('LE reverse domain rejects',sharedAll(50,adt(['Gone'])),sharedAll(60,adt([])),true,false);
add('EQ rejects proper subtype',adt(['Gone']),adt([]),false,false);
add('LE accepts proper subtype',adt(['Gone']),adt([]),true,true);
add('kind alternative success',kind(v(91)),kind(meet(v(92),v(91))),true,true);
add('kind alternative preserves later mismatch',all(11,kind(meet(v(92),v(91))),A),all(12,kind(v(91)),Z),true,false);
add('rigid alpha copies with opaque heads',lam(11,app(ref('f'),v(11))),lam(12,app(ref('f'),v(12))),false,true,[def('f',1,lam(21,shared(32,v(21),100)))]);
add('full book retry follows failed rigid comparison',app(ref('id'),A),A,false,true,[def('id',1,lam(71,v(71)))]);
add('full book retry retains mismatch',app(ref('id'),A),Z,false,false,[def('id',1,lam(71,v(71)))]);
add('under-applied definitions compare extensionally',ref('id'),ref('other'),false,true,[def('id',1,lam(71,v(71))),def('other',1,lam(72,v(72)))]);
add('different stuck heads remain nominal',app(ref('f'),v(91)),app(ref('g'),v(91)),false,false,[def('f',1,t('Absent')),def('g',1,t('Absent'))]);
const source=path.join(out,'cases.json');fs.writeFileSync(source,JSON.stringify(cases)+'\n');inputs.push(identity(source));
const report={kind:'phase23-graph-conversion-controls',complete:false,pass:false,scope:'Private checked conversion API against exact upstream semantic constructors. Interleaved per-request times are descriptive, not a performance benchmark.',inputs,rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 for(const c of cases){
  let begin=performance.now();const reference=B.term_compare(c.le?'LE':'EQ',book(c.defs),higher(c.a),higher(c.b));const referenceMs=performance.now()-begin;
  begin=performance.now();const candidate=K.compare(list(c.defs),c.a,c.b,c.le);const candidateMs=performance.now()-begin;
  report.rows.push({name:c.name,expected:c.expected,reference,candidate,referenceMs,candidateMs,pass:reference===c.expected&&candidate===reference});save();
  assert.equal(reference,c.expected,c.name+' reference assumption');assert.equal(candidate,reference,c.name);
 }
 report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
report.changedInputs=inputs.filter(x=>identity(x.file).sha256!==x.sha256);if(report.changedInputs.length)report.pass=false;
report.maxRssKiB=process.resourceUsage().maxRSS;save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
