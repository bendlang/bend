// Independent terminal-record and nested-countdown backend admission controls.
// Uses immutable checked APIs on synthetic KDefs; no frontend claim for these books.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [attemptArgument,outArgument,group='core']=process.argv.slice(2);
assert.ok(attemptArgument&&outArgument&&['core','bounds'].includes(group));
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const save=(name,x)=>fs.writeFileSync(path.join(out,name),json(x),{flag:'wx'});
const manifestFile=path.resolve(attemptArgument,'attempt.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
const driver=path.join(manifest.snapshot.root,'tools/typed-driver.mjs');
const report={kind:'phase30-independent-terminal-region-admission',complete:false,pass:false,group,node:process.version,
 inputs:[import.meta.filename,manifestFile,driver,...['api','runtime','base'].map(k=>manifest[k].file)].map(identity),
 scope:'Actual j_library on synthetic KDefs; source checker admission is not claimed. Refused cyclic/malformed books are never executed.',guards:[],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try{
 for(const k of ['api','runtime','base'])assert.equal(identity(manifest[k].file).sha256,manifest[k].sha256);
 for(const key of Object.keys(process.env))if(key.startsWith('BEND_'))delete process.env[key];
 process.env.BEND_TYPED_API=manifest.api.file;process.env.BEND_TYPED_RUNTIME=manifest.runtime.file;process.env.BEND_BASE=manifest.base.file;
 const {loadApi}=await import(pathToFileURL(driver)),api=await loadApi(),runtime=fs.readFileSync(manifest.runtime.file,'utf8');
 const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
 const arr=xs=>{const out=[];for(let x=xs;x.$==='Con';x=x.tail)out.push(x.head);return out};
 const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
 const lit=(n,kind='U32')=>({$:'KLiteral',kind,number:n>>>0,text:'',originBegin:0,originEnd:0});
 const ty=(name,kids=[],removed=[])=>t('ADT',name,kids,0,0,removed),v=id=>t('Var','',[],id),ref=name=>t('Ref',name);
 const lam=(id,body)=>t('Lam','',[body],id,2),all=(id,a,b,q=2)=>t('All','f'+id,[a,b],id,q),ann=(term,type)=>t('Ann','',[term,type]);
 const app=(f,x)=>t('App','',[f,x]),call=(name,args)=>args.reduce(app,ref(name));
 const mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
 const d=(name,kind='Def',native=false,type=t('Typ'),value=t('Absent'),ctors=[],arity=0)=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
 const nat=ty('Nat'),u32=ty('U32'),bool=ty('Bool'),record=ty('ReviewData');
 const dataKind=t('Typ','',[t('Qua','',[],0,2)]);
 const owners=()=>[
  d('Nat','ADT',true,t('Typ'),t('Absent'),[d('Zero','Ctr',true,nat),d('Succ','Ctr',true,all(900,nat,nat),t('Absent'),[],1)]),
  ...[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']]].map(([name,cs])=>d(name,'ADT',true,t('Typ'),t('Absent'),cs.map(c=>d(c,'Ctr',true)))),
  d('Bool','ADT',true,t('Typ'),t('Absent'),[d('True','Ctr',true,bool),d('False','Ctr',true,bool)]),d('Word','Def',true),
  d('U32.inc','Def',true,all(901,u32,u32),t('Absent'),[],1),d('U32.add','Def',true,all(901,u32,all(902,u32,u32)),t('Absent'),[],2),
  d('U32.to_nat','Def',true,all(901,u32,nat),t('Absent'),[],1)];
 const recordOwner=(fields=[u32,u32])=>{
  const telescope=fields.reduceRight((rest,type,index)=>all(100+index,type,rest),record);
  return d('ReviewData','ADT',false,dataKind,t('Absent'),[d('ReviewPack','Ctr',false,telescope,t('Absent'),[],fields.length)]);
 };
 const ctor=(fields=[v(12),lit(7)])=>t('Ctr','ReviewPack',fields);
 const scalarHelper=(name='step',body=call('U32.inc',[v(30)]),type=all(3,u32,u32))=>d(name,'Def',false,type,lam(30,body),[],1);
 const loop=({name='loop',result=record,state=u32,zero=ctor(),step=call('U32.inc',[v(11)]),tail}={})=>
  d(name,'Def',false,all(1,nat,all(2,state,result)),mat('Zero',lam(12,zero),mat('Succ',lam(10,lam(11,tail??call(name,[v(10),step]))))),[],2);
 const nested=(name='inner',step=call('step',[v(11)]),zero=call('step',[v(12)]))=>loop({name,result:u32,zero,step});
 const book=(worker=loop(),helpers=[],owner=recordOwner(),extra=[])=>[...owners(),owner,worker,...helpers,...extra];
 async function check(name,defs,expected,{run,requiredHelpers=[],forbiddenHelpers=[]}={}){
  report.current=name;save(name+'.book.json',defs);
  const code=api.j_library(list(defs)),file=path.join(out,name+'.mjs');fs.writeFileSync(file,runtime+'\n'+code,{flag:'wx'});
  const line=code.split('\n').find(x=>x.startsWith('G["loop"]=')).replaceAll('\r','');
  const admitted=line.includes('/* private scalar region */'),declarations=[...line.matchAll(/function (\$R(?:_\d+)+)\(/g)].map(x=>x[1]);
  const row={name,admitted,expected,declarations,module:identity(file),assignment:line};report.guards.push(row);
  assert.equal(admitted,expected,name+' admission');assert.equal(new Set(declarations).size,declarations.length,name+' completed helpers unique');
  const encoded=n=>'$R'+[...n].map(c=>'_'+c.codePointAt(0)).join('');
  for(const helper of requiredHelpers)assert.ok(declarations.includes(encoded(helper)),name+' private '+helper);
  for(const helper of forbiddenHelpers)assert.ok(!declarations.includes(encoded(helper)),name+' absent '+helper);
  if(run){const m=await import(pathToFileURL(file));await run(m);}
  delete report.current;
 }
 const observe=(name,value)=>report.observations.push({name,value});
 const recordRun=(label,expected)=>m=>{for(const n of [0n,1n,3n,31n])for(const seed of [0,17,4294967295]){
  const actual=m.default.loop(n,seed),want=expected(n,seed);assert.deepEqual(actual,want,label);observe(label,{n,seed,actual});}};
 const pack=(x,y=7)=>({$:'ReviewPack',a:[x,y]});
 if(group==='core'){
  await check('terminal-var-literal',book(),true,{run:recordRun('terminal-var-literal',(n,x)=>pack((x+Number(n))>>>0))});
  const scalarLet=t('Let','',[t('Bind','',[call('U32.inc',[v(12)])],40,2),ctor([v(40),lit(9)])]);
  await check('terminal-scalar-let',book(loop({zero:scalarLet})),true,{run:recordRun('terminal-scalar-let',(n,x)=>pack((x+Number(n)+1)>>>0,9))});
  const mixed=recordOwner([u32,bool,nat]);
  await check('terminal-bool-nat-literals',book(loop({zero:ctor([v(12),t('Ctr','True'),lit(4,'Nat')])}),[],mixed),true,
   {run:recordRun('terminal-bool-nat-literals',(n,x)=>({$:'ReviewPack',a:[(x+Number(n))>>>0,true,4n]}))});
  await check('terminal-empty-data',book(loop({zero:ctor([])}),[],recordOwner([])),true,{run:recordRun('terminal-empty-data',()=>({$:'ReviewPack',a:[]}))});
  const inner=nested();
  await check('nested-loop-shared-helper',book(loop({step:call('inner',[lit(2,'Nat'),v(11)])}),[inner,scalarHelper()]),true,
   {requiredHelpers:['inner','step'],run:recordRun('nested-loop-shared-helper',(n,x)=>pack((x+3*Number(n))>>>0))});
  await check('nested-loop-zero-count',book(loop({step:call('inner',[lit(0,'Nat'),v(11)])}),[inner,scalarHelper()]),true,
   {requiredHelpers:['inner','step'],run:recordRun('nested-loop-zero-count',(n,x)=>pack((x+Number(n))>>>0))});
  const scalarZero=call('inner',[lit(1,'Nat'),v(12)]);
  await check('nested-both-owner-arms',book(loop({result:u32,zero:scalarZero,step:call('inner',[lit(2,'Nat'),v(11)])}),[inner,scalarHelper()]),true,
   {requiredHelpers:['inner','step'],run(m){for(const n of [0n,1n,7n]){const actual=m.default.loop(n,5);assert.equal(actual,7+3*Number(n));observe('nested-both-owner-arms',actual)}}});
  await check('acyclic-native-Nat-helper',book(loop({step:call('natStep',[v(10)])}),[scalarHelper('natStep',lit(8),all(3,nat,u32))]),true,
   {requiredHelpers:['natStep'],run(m){assert.deepEqual(m.default.loop(3n,5),pack(8));observe('acyclic-native-Nat-helper',8)}});
  const duplicateUse=call('U32.add',[call('inner',[lit(0,'Nat'),v(11)]),call('inner',[lit(0,'Nat'),lit(0)])]);
  await check('completed-helper-reuse',book(loop({step:duplicateUse}),[inner,scalarHelper()]),true,{requiredHelpers:['inner','step'],run:recordRun('completed-helper-reuse',(n,x)=>pack((x+2*Number(n))>>>0))});

  await check('record-state',book(loop({state:record,zero:v(12),step:v(11)})),false);
  const recordRhs=t('Let','',[t('Bind','',[ann(ctor([v(12),lit(0)]),record)],40,2),v(40)]);
  await check('record-let-rhs',book(loop({zero:recordRhs})),false);
  const resultHelper=scalarHelper('box',ctor([v(30),lit(0)]),all(3,u32,record));
  await check('record-returning-helper',book(loop({zero:call('box',[v(12)])}),[resultHelper]),false);
  const project=scalarHelper('unbox',t('Mat','ReviewPack',[lam(31,lam(32,v(31))),t('Efq')]),all(3,record,u32));
  await check('record-argument-projection',book(loop({zero:ctor([call('unbox',[ctor()]),lit(0)])}),[project]),false);
  await check('computed-deferred-field',book(loop({zero:ctor([call('U32.inc',[v(12)]),lit(0)])})),false);
  await check('let-deferred-field',book(loop({zero:ctor([t('Let','',[t('Bind','',[v(12)],40,2),v(40)]),lit(0)])})),false);
  await check('wrong-constructor',book(loop({zero:t('Ctr','Unrelated',[v(12),lit(0)])})),false);
  await check('short-constructor-fields',book(loop({zero:ctor([v(12)])})),false);
  await check('long-constructor-fields',book(loop({zero:ctor([v(12),lit(0),lit(1)])})),false);
  const mutateOwner=(action)=>{const owner=recordOwner();action(owner,arr(owner.ctors)[0]);return owner};
  for(const [name,action]of [
   ['native-owner',o=>{o.native=true}],['template-owner',o=>{o.templates=1}],['parameterized-owner',o=>{o.arity=1}],
   ['wrong-kind',o=>{o.typ=t('Typ','',[t('Qua','',[],0,1)])}],['native-constructor',(o,c)=>{c.native=true}],
   ['template-constructor',(o,c)=>{c.templates=1}],['arity-telescope-mismatch',(o,c)=>{c.arity=3}],
   ['wrong-result-owner',(o,c)=>{c.typ=all(100,u32,all(101,u32,ty('OtherData')))}],
   ['erased-field',(o,c)=>{c.typ=all(100,u32,all(101,u32,record),0)}],
   ['dependent-field',(o,c)=>{c.typ=all(100,u32,all(101,v(100),record))}],
   ['function-field',(o,c)=>{c.typ=all(100,all(110,u32,u32),all(101,u32,record))}],
   ['record-field',(o,c)=>{c.typ=all(100,record,all(101,u32,record))}],
   ['extra-constructor',(o,c)=>{o.ctors=list([c,d('OtherPack','Ctr',false,record)])}],
  ])await check(name,book(loop(),[],mutateOwner(action)),false);
  await check('refined-record-result',book(loop({result:ty('ReviewData',[],['ReviewPack'])})),false);
  await check('applied-record-result',book(loop({result:ty('ReviewData',[u32])})),false);
  await check('too-many-record-fields',book(loop({zero:ctor(Array.from({length:33},()=>lit(0)))}),[],recordOwner(Array.from({length:33},()=>u32))),false);

  const helpersFor=(bad)=>[bad,scalarHelper()];
  const nestedBook=(bad)=>book(loop({step:call('inner',[lit(1,'Nat'),v(11)])}),helpersFor(bad));
  const selfInRhs=nested('inner',call('inner',[v(10),v(11)]));
  await check('nested-self-in-argument',nestedBook(selfInRhs),false);
  const wrongPred=nested();wrongPred.value=mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,call('inner',[lit(1,'Nat'),v(11)])))));
  await check('nested-wrong-predecessor',nestedBook(wrongPred),false);
  const nonTail=nested();nonTail.value=mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,call('U32.inc',[call('inner',[v(10),v(11)])])))));
  await check('nested-nontail-self',nestedBook(nonTail),false);
  const mutual=nested('inner',call('other',[v(11)]));
  await check('nested-mutual-cycle',book(loop({step:call('inner',[lit(1,'Nat'),v(11)])}),[mutual,scalarHelper('other',call('inner',[lit(1,'Nat'),v(30)])),scalarHelper()]),false);
  const outerCycle=nested('inner',call('loop',[lit(1,'Nat'),v(11)]));
  await check('nested-owner-cycle',book(loop({result:u32,zero:v(12),step:call('inner',[lit(1,'Nat'),v(11)])}),[outerCycle,scalarHelper()]),false);
  const malformed=nested();const outer=malformed.value;outer.kids=list([...arr(outer.kids),t('Efq')]);
  await check('nested-extra-match-arm',nestedBook(malformed),false);
  const absurd=nested();const successor=arr(absurd.value.kids)[1];arr(successor.kids)[1].kids=list([lit(0)]);
  await check('nested-malformed-absurd',nestedBook(absurd),false);
 }
 if(group==='bounds'){
  const makeMixed=(count)=>Array.from({length:count},(_,i)=>{
   const name='mixed'+i,next='mixed'+(i+1),last=i===count-1;
   return i%2===0?nested(name,last?call('U32.inc',[v(11)]):call(next,[v(11)]),v(12)):
    scalarHelper(name,last?call('U32.inc',[v(30)]):call(next,[lit(1,'Nat'),v(30)]));
  });
  await check('mixed-depth-17',book(loop({step:call('mixed0',[lit(1,'Nat'),v(11)])}),makeMixed(17)),false);
  const many=Array.from({length:33},(_,i)=>scalarHelper('wide'+i));
  await check('helper-count-33',book(loop({step:many.reduce((x,h)=>call(h.name,[x]),v(11))}),many),false);
  const tree=depth=>depth===0?lit(0):call('U32.add',[tree(depth-1),tree(depth-1)]);
  const large=Array.from({length:16},(_,i)=>scalarHelper('budget'+i,tree(10)));
  const side=(start,end,initial)=>large.slice(start,end).reduce((x,h)=>call(h.name,[x]),initial);
  // Both arms are individually below the shared budget; their combined distinct
  // helper bodies exceed it. Source bound remains below8192 per helper.
  await check('shared-zero-succ-fuel',book(loop({result:u32,zero:side(0,8,v(12)),step:side(8,16,v(11))}),large),false);
  await check('shared-fuel-neighbor-15',book(loop({result:u32,zero:side(0,8,v(12)),step:side(8,15,v(11))}),large.slice(0,15)),true,
   {requiredHelpers:large.slice(0,15).map(h=>h.name)});
  const nestedFuel=(end)=>nested('budgetInner',side(8,end,v(11)),v(12));
  const outerFuel=loop({result:u32,zero:side(0,8,v(12)),step:call('budgetInner',[lit(1,'Nat'),v(11)])});
  await check('nested-shared-fuel',book(outerFuel,[nestedFuel(16),...large]),false);
  await check('nested-fuel-neighbor-15',book(outerFuel,[nestedFuel(15),...large.slice(0,15)]),true,
   {requiredHelpers:['budgetInner',...large.slice(0,15).map(h=>h.name)]});
  const sharedInner=nested('budgetInner',side(0,8,v(11)),v(12));
  await check('nested-completed-cache-budget',book(outerFuel,[sharedInner,...large.slice(0,8)]),true,
   {requiredHelpers:['budgetInner',...large.slice(0,8).map(h=>h.name)]});
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
save('report.json',report);console.log(json({complete:report.complete,pass:report.pass,group,guards:report.guards.length,observations:report.observations.length,current:report.current,error:report.error}));
