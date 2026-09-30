// Independent actual-emitter admission/refusal controls; synthetic core only.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [attemptArgument,outArgument,admissionProfile='scalar-only']=process.argv.slice(2);
assert.ok(attemptArgument&&outArgument,'usage: review-scalar-compiler-admission.mjs CHECKED_ATTEMPT NEW_OUT');
assert.ok(['scalar-only','native-Nat-helpers'].includes(admissionProfile));
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const stringify=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const save=(name,x)=>fs.writeFileSync(path.join(out,name),stringify(x),{flag:'wx'});
const manifestFile=path.resolve(attemptArgument,'attempt.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
const driver=path.join(manifest.snapshot.root,'tools/typed-driver.mjs');
const report={kind:'phase30-independent-actual-region-admission',complete:false,pass:false,node:process.version,
  scope:'Actual checked j_library on synthetic KDefs; no frontend admission claim. Refused recursive or foreign books are emitted but not executed.',
  inputs:[identity(import.meta.filename),identity(manifestFile),identity(driver),...['api','runtime','base'].map(k=>identity(manifest[k].file))],
  admissionProfile,guards:[],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-scalar-compiler-admission.mjs'));
try{
  for(const k of ['api','runtime','base'])assert.equal(identity(manifest[k].file).sha256,manifest[k].sha256);
  for(const k of Object.keys(process.env))if(k.startsWith('BEND_'))delete process.env[k];
  process.env.BEND_TYPED_API=manifest.api.file;process.env.BEND_TYPED_RUNTIME=manifest.runtime.file;process.env.BEND_BASE=manifest.base.file;
  const {loadApi}=await import(pathToFileURL(driver)),api=await loadApi();
  const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
  const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
  const lit=n=>({$:'KLiteral',kind:'U32',number:n>>>0,text:'',originBegin:0,originEnd:0});
  const typ=name=>t('ADT',name),v=id=>t('Var','',[],id),ref=name=>t('Ref',name),lam=(id,body)=>t('Lam','',[body],id,2),all=(id,a,b,q=2)=>t('All','',[a,b],id,q);
  const app=(f,x)=>t('App','',[f,x]),call=(name,args)=>args.reduce(app,ref(name));
  const mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
  const d=(name,kind='Def',native=false,type=t('Typ'),value=t('Absent'),ctors=[],arity=0)=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
  const nat=typ('Nat'),u32=typ('U32'),bool=typ('Bool');
  const ownerRows=()=>[
    d('Nat','ADT',true,t('Typ'),t('Absent'),[d('Zero','Ctr',true,nat),d('Succ','Ctr',true,all(900,nat,nat),t('Absent'),[],1)]),
    ...[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['F32',['F32']]].map(([name,cs])=>d(name,'ADT',true,t('Typ'),t('Absent'),cs.map(c=>d(c,'Ctr',true)))),
    d('Bool','ADT',true,t('Typ'),t('Absent'),[d('True','Ctr',true,bool),d('False','Ctr',true,bool)]),
    d('Word','Def',true),
    d('U32.inc','Def',true,all(901,u32,u32),t('Absent'),[],1),
    d('U32.add','Def',true,all(901,u32,all(902,u32,u32)),t('Absent'),[],2),
    d('U32.is_zero','Def',true,all(901,u32,bool),t('Absent'),[],1),
  ];
  const helper=(name='step',body=call('U32.inc',[v(30)]),type=all(3,u32,u32),arity=1)=>d(name,'Def',false,type,lam(30,body),[],arity);
  const loop=(step=call('step',[v(11)]),zero=v(12))=>d('loop','Def',false,all(1,nat,all(2,u32,u32)),mat('Zero',lam(12,zero),mat('Succ',lam(10,lam(11,call('loop',[v(10),step]))))),[],2);
  const rows=(helpers=[helper()],worker=loop(),owners=ownerRows())=>[...owners,worker,...helpers];
  const runtime=fs.readFileSync(manifest.runtime.file,'utf8');
  // After the scheduling repair, failed purity plans use generic emission;
  // retaining the old eager Nat fallback is itself a correctness failure.
  async function check(name,book,expected,{run,worker=expected}={}){
    report.current=name;save(name+'.book.json',book);
    const code=api.j_library(list(book));
    const file=path.join(out,name+'.mjs');fs.writeFileSync(file,runtime+'\n'+code,{flag:'wx'});
    const line=code.split('\n').find(x=>x.startsWith('G["loop"]=')).replaceAll('\r','');
    const admitted=line.includes('/* private scalar region */');
    const outer=line.includes('/* private Nat loop */');
    const observation={name,admitted,expected,outer,expectedOuter:worker,module:identity(file),assignment:line};
    report.guards.push(observation);assert.equal(admitted,expected,name+' private admission');assert.equal(outer,worker,name+' original Nat worker');
    if(run){const m=await import(pathToFileURL(file));await run(m,name);}
  }
  const observe=(name,value)=>report.observations.push({name,value});
  await check('forward-helper',rows(),true,{run(m){
    for(const n of [0n,1n,31n,50000n]){const result=m.default.loop(n,17);assert.equal(result,17+Number(n));observe('forward-helper-'+n,result);}
    const original=m.G.step,code=original.code;let count=0;original.code=function(a){count++;return code.call(this,a)};
    assert.equal(m.default.loop(9n,17),26);assert.equal(count,9);observe('forward-helper-after-code-mutation',count);original.code=code;
    const before=m.call(m.G.loop,[3n]);assert.equal(before.arity,2);assert.deepEqual(before.bound,[2n]);
    m.G.step={...original,code:a=>a[0]+3};assert.equal(m.call(before,[17]),26);observe('saved-public-partial-after-replacement',26);
  }});
  await check('zero-helper',rows([helper()],loop(call('step',[v(11)]),call('step',[v(12)]))),true,{run(m){
    for(const n of [0n,1n,17n]){const result=m.default.loop(n,9);assert.equal(result,10+Number(n));observe('zero-helper-'+n,result);}
  }});
  const pick=d('pick','Def',false,all(31,bool,all(32,u32,u32)),mat('False',lam(33,call('U32.inc',[v(33)])),mat('True',lam(34,v(34)))),[],2);
  await check('reverse-bool-branches',rows([pick],loop(call('pick',[call('U32.is_zero',[v(11)]),v(11)]))),true,{run(m){
    assert.equal(m.default.loop(100n,0),0);assert.equal(m.default.loop(100n,1),101);observe('reverse-bool-branches',[0,101]);
  }});
  const shadow=t('Let','',[t('Bind','',[call('step',[v(11)])],11,2),t('Bind','',[v(11)],21,2),call('loop',[v(10),v(21)])]);
  const shadowLoop=loop();shadowLoop.value=mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,shadow))));
  await check('parallel-shadow',rows([helper()],shadowLoop),true,{run(m){assert.equal(m.default.loop(100n,7),7);observe('parallel-shadow',7)}});
  await check('transitive-helper',rows([helper('step',call('next',[v(30)])),helper('next')]),true,{run(m){assert.equal(m.default.loop(100n,7),107);observe('transitive-helper',107)}});
  await check('no-helper',rows([],loop(call('U32.inc',[v(11)]))),true,{run(m){assert.equal(m.default.loop(100n,7),107);observe('empty-helper-closure',107)}});
  await check('scalar-direct-cycle',rows([helper('step',call('step',[v(30)]))]),false);
  await check('scalar-mutual-cycle',rows([helper('step',call('other',[v(30)])),helper('other',call('step',[v(30)]))]),false);
  await check('unknown-helper',rows([]),false);
  await check('unknown-expression',rows([helper('step',t('ReviewUnknown','',[v(30)]))]),false);
  await check('higher-order-call',rows([helper('step',app(lam(40,v(40)),v(30)))]),false);
  await check('computed-global',rows([helper('step',ref('value')),d('value','Def',false,u32,lit(7))]),false);
  await check('foreign-helper',rows([d('step','Def',false,all(3,u32,u32),t('Foreign','review_phase30_foreign'),[],1)]),false);
  await check('partial-helper',rows([helper('step',lam(31,v(30)),all(3,u32,all(4,u32,u32)),2)]),false);
  await check('oversaturated-helper',rows([helper()],loop(call('step',[v(11),v(11)]))),false);
  await check('erased-helper-parameter',rows([helper('step',v(30),all(3,u32,u32,0))]),false);
  const template=helper();template.templates=1;await check('template-helper',rows([template]),false);
  const native=helper();native.native=true;await check('unsupported-native-helper',rows([native]),false);
  const natHelper=helper('step',lit(0),all(3,nat,u32));await check('Nat-helper-parameter',rows([natHelper],loop(call('step',[v(10)]))),admissionProfile==='native-Nat-helpers');
  const owners=ownerRows();owners.find(x=>x.name==='U32').native=false;await check('non-native-scalar-owner',rows([helper()],loop(),owners),false,{worker:false});
  const qualified=u32=>t('ADT','U32',[],0,0,['U32']);
  await check('removed-helper-type',rows([helper('step',v(30),all(3,qualified(),u32))]),false);
  const chain=Array.from({length:18},(_,i)=>helper(i===0?'step':'chain'+i,i===17?call('U32.inc',[v(30)]):call('chain'+(i+1),[v(30)])));
  await check('helper-depth-bound',rows(chain),false);
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  delete report.current;report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save('report.json',report);console.log(stringify({complete:report.complete,pass:report.pass,guards:report.guards.length,observations:report.observations.length,current:report.current,error:report.error}));
