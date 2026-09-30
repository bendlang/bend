// Independent synthetic KDef coverage for ordinary roots through actual j_library.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [attemptArgument,outArgument]=process.argv.slice(2);assert.ok(attemptArgument&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const save=(name,value)=>fs.writeFileSync(path.join(out,name),json(value),{flag:'wx'});
const manifestFile=path.resolve(attemptArgument,'attempt.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
const driver=path.join(manifest.snapshot.root,'tools/typed-driver.mjs');
const report={kind:'phase30-independent-ordinary-root-admission',complete:false,pass:false,node:process.version,
 scope:'Immutable checked compiler j_library on synthetic KDefs, not frontend/typechecker acceptance. Refused malformed and recursive books are not executed.',
 inputs:[import.meta.filename,manifestFile,driver,...['api','runtime','base'].map(k=>manifest[k].file)].map(identity),guards:[],observations:[]};
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
 const mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
 const d=(name,type,value,arity=2,extras={})=>({$:'KDef',name,kind:'Def',arity,templates:0,typ:type,value,ctors:list([]),native:false,unsafe:false,...extras});
 const nat=ty('Nat'),u32=ty('U32'),bool=ty('Bool'),record=ty('ReviewData');
 const owner=(name,ctors)=>d(name,t('Typ'),t('Absent'),0,{kind:'ADT',native:true,ctors:list(ctors)});
 const ctor=(name,type=t('Typ'),arity=0)=>d(name,type,t('Absent'),arity,{kind:'Ctr',native:true});
 const owners=()=>[
  owner('Nat',[ctor('Zero',nat),ctor('Succ',all(900,nat,nat),1)]),
  ...[['U32','U32'],['Word.Nil','WNil'],['Word.Con','WCon'],['F32','F32']].map(([name,c])=>owner(name,[ctor(c)])),
  owner('Bool',[ctor('True',bool),ctor('False',bool)]),d('Word',t('Typ'),t('Absent'),0,{native:true}),
  d('U32.inc',all(901,u32,u32),t('Absent'),1,{native:true}),
  d('U32.add',all(901,u32,all(902,u32,u32)),t('Absent'),2,{native:true}),
  d('U32.is_zero',all(901,u32,bool),t('Absent'),1,{native:true})];
 const root=(body=call('inner',[v(1),v(2)]),type=all(101,nat,all(102,u32,u32)),value)=>d('root',type,value??lam(1,lam(2,body)));
 const inner=(name='inner',step=call('U32.inc',[v(11)]))=>d(name,all(110,nat,all(111,u32,u32)),
  mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,call(name,[v(10),step]))))));
 const book=(r=root(),helpers=[inner()],os=owners())=>[...os,r,...helpers];
 const observe=(name,value)=>report.observations.push({name,value});
 async function check(name,defs,expected,run){
  report.current=name;save(name+'.book.json',defs);
  const code=api.j_library(list(defs)),file=path.join(out,name+'.mjs');fs.writeFileSync(file,runtime+'\n'+code,{flag:'wx'});
  const line=(code.split('\n').find(x=>x.startsWith('G["root"]=') )??'').replaceAll('\r','');
  const admitted=line.includes('/* private scalar root */');
  const row={name,expected,admitted,globalEmitted:line.length>0,module:identity(file),assignment:line};report.guards.push(row);
  assert.equal(admitted,expected,name+' root admission');
  if(expected){assert.equal((line.match(/scalarCapture\("root",/g)??[]).length,1);assert.ok(line.includes('exactCode(function(a,$entered)'));}
  if(run)await run(await import(pathToFileURL(file)),line);delete report.current;
 }
 const arithmetic=name=>m=>{for(const n of [0n,1n,31n,50000n])for(const seed of [0,17,4294967295]){
  const value=m.default.root(n,seed);assert.equal(value,(seed+Number(n))>>>0);observe(name,{n,seed,value});}};
 await check('forward-nested-loop',book(),true,async(m,line)=>{
  arithmetic('forward-nested-loop')(m);assert.ok(line.includes('$s0<=281474976710655n'));
  const saved=m.call(m.G.root,[3n]),innerDescriptor=m.G.inner,original=innerDescriptor.code;let calls=0;
  innerDescriptor.code=function(a){calls++;return Reflect.apply(original,this,[a])};
  assert.equal(m.call(saved,[7]),10);assert.ok(calls>0);observe('saved-partial-live-helper',{calls,value:10});innerDescriptor.code=original;
  const raw=Reflect.apply(m.G.root.code,null,[[2n,7]]);assert.equal(raw.bounce,true);observe('raw-tail-bounce',true);
 });
 const chain=d('via',all(120,nat,all(121,u32,u32)),lam(21,lam(22,call('inner',[v(21),v(22)]))));
 await check('transitive-nested-loop',book(root(call('via',[v(1),v(2)])),[chain,inner()]),true,arithmetic('transitive-nested-loop'));
 const shadow=t('Let','',[t('Bind','',[call('U32.inc',[v(2)])],2,2),t('Bind','',[v(2)],30,2),call('inner',[v(1),v(30)])]);
 await check('parallel-let-shadow',book(root(shadow)),true,arithmetic('parallel-let-shadow'));
 const wide=d('wide',all(130,nat,all(131,nat,all(132,u32,u32))),
  mat('Zero',lam(20,lam(21,v(21))),mat('Succ',lam(22,lam(23,lam(24,call('wide',[v(22),v(23),call('U32.inc',[v(24)])])))))),3);
 await check('full-unprojected-Nat',book(root(call('wide',[lit(0,'Nat'),v(1),v(2)])),[wide]),true,(m,line)=>{
  assert.ok(line.includes('$s0<=281474976710655n'));assert.ok(!line.includes('$s0<281474976710655n'));
  for(const n of [0n,1n,281474976710654n,281474976710655n]){assert.equal(m.default.root(n,23),23);observe('unused-Nat-state',{n,value:23});}
 });
 const boolRoot=root(call('inner',[lit(2,'Nat'),call('pick',[v(1),v(2)])]),all(101,bool,all(102,u32,u32)));
 const pick=d('pick',all(140,bool,all(141,u32,u32)),mat('False',lam(41,v(41)),mat('True',lam(42,call('U32.inc',[v(42)])))));
 await check('Bool-root-native-branches',book(boolRoot,[inner(),pick]),true,m=>{for(const x of [false,true]){const value=m.default.root(x,9);assert.equal(value,x?12:11);observe('Bool-root',{x,value});}});
 await check('trivial-no-loop',book(root(v(2)),[]),false);
 await check('acyclic-no-loop',book(root(call('U32.inc',[v(2)])),[]),false);
 await check('unused-loop-is-not-proof',book(root(v(2))),false);
 await check('partial-leading-telescope',book(root(undefined,undefined,lam(1,ref('inner')))),false);
 const erased=root();erased.typ=all(101,nat,all(102,u32,u32),0);await check('erased-root-parameter',book(erased),false);
 const recordParam=root(undefined,all(101,record,all(102,u32,u32)));await check('record-root-parameter',book(recordParam),false);
 const recordResult=root(undefined,all(101,nat,all(102,u32,record)));await check('record-root-result',book(recordResult),false);
 const templated=root();templated.templates=1;await check('templated-root',book(templated),false);
 const native=root();native.native=true;await check('native-root',book(native),false);
 await check('duplicate-prefix-binder',book(root(undefined,undefined,lam(1,lam(1,call('inner',[v(1),lit(0)]))))),false);
 await check('labelled-prefix',book(root(undefined,undefined,lam(1,lam(2,call('inner',[v(1),v(2)])),['$js.review-root']))),false);
 await check('root-self-call',book(root(call('root',[v(1),v(2)]))),false);
 await check('root-mutual-call',book(root(call('via',[v(1),v(2)])),[d('via',chain.typ,lam(21,lam(22,call('root',[v(21),v(22)])))),inner()]),false);
 await check('unknown-helper',book(root(call('missing',[v(1),v(2)]))),false);
 await check('foreign-root',book(root(undefined,undefined,t('Foreign','review_root'))),false);
 await check('foreign-helper',book(root(),[d('inner',inner().typ,t('Foreign','review_inner'))]),false);
 await check('higher-order-call',book(root(app(lam(45,v(45)),call('inner',[v(1),v(2)])))),false);
 await check('partial-helper',book(root(call('inner',[v(1)]))),false);
 await check('oversaturated-helper',book(root(call('inner',[v(1),v(2),v(2)]))),false);
 const invalidOwners=owners();invalidOwners.find(x=>x.name==='Nat').native=false;
 await check('invalid-native-Nat',book(root(),[inner()],invalidOwners),false);
 const refined=root(undefined,all(101,t('ADT','Nat',[],0,0,['Succ']),all(102,u32,u32)));
 await check('refined-Nat-parameter',book(refined),false);
 const badCounter=inner();badCounter.value=mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,call('inner',[lit(1,'Nat'),v(11)])))));
 await check('unproved-helper-self-edge',book(root(),[badCounter]),false);
 const deep=Array.from({length:18},(_,i)=>d('link'+i,chain.typ,lam(21,lam(22,call(i===17?'inner':'link'+(i+1),[v(21),v(22)])))));
 await check('helper-depth-budget',book(root(call('link0',[v(1),v(2)])),[...deep,inner()]),false);
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
save('report.json',report);console.log(json({complete:report.complete,pass:report.pass,guards:report.guards.length,observations:report.observations.length,current:report.current,error:report.error}));
