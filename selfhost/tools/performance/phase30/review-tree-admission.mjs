// Independent actual-emitter scalar-tree admission and noncommutative oracles.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [attemptArgument,outArgument]=process.argv.slice(2);assert.ok(attemptArgument&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const save=(name,x)=>fs.writeFileSync(path.join(out,name),json(x),{flag:'wx'});
const manifestFile=path.resolve(attemptArgument,'attempt.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
const driver=path.join(manifest.snapshot.root,'tools/typed-driver.mjs');
const report={kind:'phase30-independent-scalar-tree-admission',complete:false,pass:false,node:process.version,
 inputs:[import.meta.filename,manifestFile,driver,...['api','runtime','base'].map(k=>manifest[k].file)].map(identity),guards:[],observations:[],
 scope:'Actual immutable checked j_library on synthetic books. Independent recursive arithmetic oracle; refusals are emitted but not executed. No frontend/conformance percentage or timing claim.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try{
 for(const k of ['api','runtime','base'])assert.equal(identity(manifest[k].file).sha256,manifest[k].sha256);
 for(const k of Object.keys(process.env))if(k.startsWith('BEND_'))delete process.env[k];
 process.env.BEND_TYPED_API=manifest.api.file;process.env.BEND_TYPED_RUNTIME=manifest.runtime.file;process.env.BEND_BASE=manifest.base.file;
 const {loadApi}=await import(pathToFileURL(driver)),api=await loadApi(),runtime=fs.readFileSync(manifest.runtime.file,'utf8');
 const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
 const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
 const lit=(n,kind='U32')=>({$:'KLiteral',kind,number:n>>>0,text:'',originBegin:0,originEnd:0});
 const ty=name=>t('ADT',name),v=id=>t('Var','',[],id),ref=name=>t('Ref',name),lam=(id,body,removed=[])=>t('Lam','',[body],id,2,removed);
 const all=(id,a,b,q=2)=>t('All','',[a,b],id,q),app=(f,x)=>t('App','',[f,x]),call=(name,args)=>args.reduce(app,ref(name));
 const mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]),bind=(id,body,q=2)=>t('Bind','',[body],id,q);
 const d=(name,type,value,arity=2,extra={})=>({$:'KDef',name,kind:'Def',arity,templates:0,typ:type,value,ctors:list([]),native:false,unsafe:false,...extra});
 const nat=ty('Nat'),u32=ty('U32'),bool=ty('Bool'),record=ty('ReviewData');
 const ctr=(name,type=t('Typ'),arity=0)=>d(name,type,t('Absent'),arity,{kind:'Ctr',native:true});
 const owner=(name,cs)=>d(name,t('Typ'),t('Absent'),0,{kind:'ADT',native:true,ctors:list(cs)});
 const owners=()=>[
  owner('Nat',[ctr('Zero',nat),ctr('Succ',all(900,nat,nat),1)]),
  ...[['U32','U32'],['Word.Nil','WNil'],['Word.Con','WCon']].map(([name,c])=>owner(name,[ctr(c)])),
  owner('Bool',[ctr('True',bool),ctr('False',bool)]),d('Word',t('Typ'),t('Absent'),0,{native:true}),
  ...['add','sub','mul'].map(name=>d('U32.'+name,all(901,u32,all(902,u32,u32)),t('Absent'),2,{native:true})),
  d('U32.inc',all(901,u32,u32),t('Absent'),1,{native:true}),
  d('ReviewData',t('Typ','',[t('Qua','',[],0,2)]),t('Absent'),0,{kind:'ADT',ctors:list([d('ReviewPack',all(905,u32,record),t('Absent'),1,{kind:'Ctr'})])})];
 const leftDefault=()=>call('U32.add',[v(11),lit(1)]),rightDefault=()=>call('U32.mul',[v(11),lit(3)]);
 const tree=({zero=v(12),left=leftDefault(),right=rightDefault(),combine=call('U32.sub',[v(20),v(21)]),state=u32,result=u32,body,first=10}={})=>
  d('tree',all(100,nat,all(101,state,result)),mat('Zero',lam(12,zero),mat('Succ',lam(first,lam(11,body??t('Let','',[
   bind(20,call('tree',[v(first),left])),bind(21,call('tree',[v(first),right])),combine]))))));
 const helper=(name='step',body=call('U32.inc',[v(30)]))=>d(name,all(102,u32,u32),lam(30,body),1);
 const inner=()=>d('inner',all(110,nat,all(111,u32,u32)),mat('Zero',lam(42,v(42)),mat('Succ',lam(40,lam(41,call('inner',[v(40),call('U32.inc',[v(41)])]))))));
 const book=(root=tree(),helpers=[],os=owners())=>[...os,root,...helpers];
 const observe=(name,value)=>report.observations.push({name,value});
 async function check(name,defs,expected,run){
  report.current=name;save(name+'.book.json',defs);
  const code=api.j_library(list(defs)),file=path.join(out,name+'.mjs');fs.writeFileSync(file,runtime+'\n'+code,{flag:'wx'});
  const line=(code.split('\n').find(x=>x.startsWith('G["tree"]=') )??'').replaceAll('\r','');
  const admitted=line.includes('/* private scalar tree */'),helpers=[...line.matchAll(/function (\$R(?:_\d+)+)\(/g)].map(x=>x[1]);
  report.guards.push({name,expected,admitted,helpers,module:identity(file),assignment:line});assert.equal(admitted,expected,name+' admission');
  if(expected){assert.ok(line.includes('$s0<32n&&scalarGuard($guards)'));assert.equal(new Set(helpers).size,helpers.length);assert.equal((line.match(/scalarCapture\("tree",/g)??[]).length,1);}
  if(run)await run(await import(pathToFileURL(file)),line);delete report.current;
 }
 function oracle(n,s,{zero=x=>x,left=x=>(x+1)>>>0,right=x=>Math.imul(x,3)>>>0,combine=(a,b)=>(a-b)>>>0}={}){
  if(n===0)return zero(s);const a=oracle(n-1,left(s),{zero,left,right,combine});const b=oracle(n-1,right(s),{zero,left,right,combine});return combine(a,b);
 }
 const arithmetic=(name,options)=>m=>{for(const n of [0,1,2,3,5])for(const seed of [0,1,17,4294967295]){
  const result=m.default.tree(BigInt(n),seed),expected=oracle(n,seed,options);assert.equal(result,expected,name);observe(name,{n,seed,result});}};
 await check('noncommutative-different-children',book(),true,(m,line)=>{
  arithmetic('noncommutative')(m);const saved=m.default.tree(3n),code=saved.code;
  const raw=Reflect.apply(code,null,[[2n,17]]);assert.equal(raw,oracle(3,17));observe('raw-successor-result',raw);
  const parent=m.G.tree,original=parent.code;let calls=0;
  parent.code=function(args){calls++;return Reflect.apply(original,this,[args])};
  const result=m.call(saved,[17]);assert.equal(result,oracle(3,17));assert.ok(calls>0);parent.code=original;
  observe('saved-partial-owner-mutation',{result,calls});
 });
 await check('reversed-combine',book(tree({combine:call('U32.sub',[v(21),v(20)])})),true,
  arithmetic('reversed-combine',{combine:(a,b)=>(b-a)>>>0}));
 const shared=tree({zero:call('step',[v(12)]),left:call('step',[v(11)]),right:call('step',[call('step',[v(11)])]),combine:call('step',[call('U32.sub',[v(20),v(21)])])});
 await check('shared-helper-all-four-sites',book(shared,[helper()]),true,arithmetic('shared-helper',{
  zero:x=>(x+1)>>>0,left:x=>(x+1)>>>0,right:x=>(x+2)>>>0,combine:(a,b)=>(a-b+1)>>>0}));
 await check('nested-countdown-zero',book(tree({zero:call('inner',[lit(2,'Nat'),v(12)])}),[inner()]),true,
  arithmetic('nested-countdown-zero',{zero:x=>(x+2)>>>0}));
 const boolword=d('boolword',all(120,bool,u32),mat('False',lit(0),mat('True',lit(1))),1);
 await check('native-Bool-state',book(tree({state:bool,zero:call('boolword',[v(12)]),left:t('Ctr','True'),right:v(11)}),[boolword]),true,m=>{
  for(const n of [0,1,2,4])for(const x of [false,true]){const result=m.default.tree(BigInt(n),x);assert.equal(result,oracle(n,x,{zero:Number,left:()=>true,right:y=>y}));observe('Bool-state',{n,x,result});}
 });
 await check('native-Nat-state',book(tree({state:nat,zero:lit(7),left:v(11),right:v(11)})),true,m=>{
  for(const n of [0n,1n,3n])for(const x of [0n,281474976710655n]){const result=m.default.tree(n,x);assert.equal(result,n===0n?7:0);observe('Nat-state',{n,x,result});}
 });
 const children=()=>[bind(20,call('tree',[v(10),leftDefault()])),bind(21,call('tree',[v(10),rightDefault()]))];
 const letBody=(kids,comb=call('U32.sub',[v(20),v(21)]))=>t('Let','',[...kids,comb]);
 await check('third-child',book(tree({body:letBody([...children(),bind(22,call('tree',[v(10),v(11)]))])})),false);
 await check('one-child',book(tree({body:letBody(children().slice(0,1),v(20))})),false);
 await check('erased-child',book(tree({body:letBody([bind(20,call('tree',[v(10),v(11)]),0),children()[1]])})),false);
 await check('duplicate-child-binders',book(tree({body:letBody([children()[0],bind(20,call('tree',[v(10),v(11)]))],v(20))})),false);
 for(const id of [10,11])await check('child-shadows-parent-'+id,book(tree({body:letBody([bind(id,call('tree',[v(10),v(11)])),children()[1]],v(21))})),false);
 await check('right-sees-left-result',book(tree({right:v(20)})),false);
 await check('combine-captures-parent',book(tree({combine:call('U32.add',[v(20),v(11)])})),false);
 await check('wrong-first-predecessor',book(tree({body:letBody([bind(20,call('tree',[lit(0,'Nat'),v(11)])),children()[1]])})),false);
 await check('partial-child',book(tree({body:letBody([bind(20,call('tree',[v(10)])),children()[1]])})),false);
 await check('oversaturated-child',book(tree({body:letBody([bind(20,call('tree',[v(10),v(11),v(11)])),children()[1]])})),false);
 await check('self-call-in-argument',book(tree({left:call('tree',[v(10),v(11)])})),false);
 await check('self-call-in-combine',book(tree({combine:call('tree',[lit(0,'Nat'),v(20)])})),false);
 const reenter=d('reenter',all(130,nat,all(131,u32,u32)),lam(50,lam(51,call('tree',[v(50),v(51)]))));
 await check('helper-owner-reentry',book(tree({left:call('reenter',[v(10),v(11)])}),[reenter]),false);
 await check('helper-mutual-cycle',book(tree({zero:call('a',[v(12)])}),[helper('a',call('b',[v(30)])),helper('b',call('a',[v(30)]))]),false);
 await check('unknown-helper',book(tree({zero:call('missing',[v(12)])})),false);
 await check('foreign-helper',book(tree({zero:call('foreign',[v(12)])}),[d('foreign',all(132,u32,u32),t('Foreign','review_tree'),1)]),false);
 await check('record-state',book(tree({state:record,zero:lit(7),left:v(11),right:v(11)})),false);
 await check('record-result',book(tree({result:record,zero:t('Ctr','ReviewPack',[v(12)]),combine:v(20)})),false);
 await check('escaping-combine',book(tree({combine:lam(70,v(20))})),false);
 const labelled=tree();labelled.value=mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,letBody(children())),['$js.tree-review'])));
 await check('labelled-successor',book(labelled),false);
 const os=owners();os.find(x=>x.name==='Nat').native=false;await check('invalid-native-Nat',book(tree(),[],os),false);
 const sum=(indices,arg)=>indices.map(i=>call('h'+i,[arg])).reduce((a,b)=>call('U32.add',[a,b]));
 for(const count of [32,33]){
  const hs=Array.from({length:count},(_,i)=>helper('h'+i));
  const root=tree({zero:sum(Array.from({length:8},(_,i)=>i),v(12)),left:sum(Array.from({length:8},(_,i)=>i+8),v(11)),
   right:sum(Array.from({length:8},(_,i)=>i+16),v(11)),combine:sum(Array.from({length:count-24},(_,i)=>i+24),v(20))});
  await check('shared-helper-budget-'+count,book(root,hs),count===32);
 }
 const chain=Array.from({length:18},(_,i)=>helper('deep'+i,i===17?call('U32.inc',[v(30)]):call('deep'+(i+1),[v(30)])));
 await check('shared-helper-depth',book(tree({zero:call('deep0',[v(12)])}),chain),false);
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
save('report.json',report);console.log(json({complete:report.complete,pass:report.pass,guards:report.guards.length,observations:report.observations.length,current:report.current,error:report.error}));
