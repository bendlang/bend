// Independent private Nat-loop recognizer and parallel/erased-let witnesses.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);
assert.ok(configFile&&outArgument,'usage: controls-worker-guards.mjs CONFIG NEW_OUT');
const config=JSON.parse(fs.readFileSync(configFile)),candidate=config.candidate??config,out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const save=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,(_,x)=>typeof x==='bigint'?String(x)+'n':x,2)+'\n',{flag:'wx'});
const report={kind:'phase29-independent-worker-guards',complete:false,pass:false,node:process.version,args:process.execArgv,
  inputs:[identity(configFile),identity(import.meta.filename),...['api','driver','runtime','base'].map(k=>identity(candidate[k]))],
  scope:'Synthetic KDefs, not frontend admission. Guard refusals and executable erased/parallel-let scopes.',guards:[],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls-worker-guards.mjs'));save(path.join(out,'config.json'),config);
try{
  for(const key of Object.keys(process.env))if(key.startsWith('BEND_'))delete process.env[key];
  process.env.BEND_TYPED_API=candidate.api;process.env.BEND_TYPED_RUNTIME=candidate.runtime;process.env.BEND_BASE=candidate.base;
  const {loadApi}=await import(pathToFileURL(candidate.driver));let api=await loadApi();
  if(typeof api.j_nat_loop_worker!=='function'){
    const original=fs.readFileSync(candidate.api,'utf8');assert.equal(original.split('function $j_nat_loop_worker$(').length,2);
    const added='\n// Diagnostic only; original checked generated bodies unchanged.\nexport const phase29WorkerGuard={j_nat_loop_worker:(book,d)=>run_loop($j_nat_loop_worker$(book,d))};\n';
    const file=path.join(out,'diagnostic-api.mjs');fs.writeFileSync(file,original+added,{flag:'wx'});report.diagnostic={...identity(file),appendOnly:true,unchangedPrefixSha256:sha(original)};
    api={...api,...(await import(pathToFileURL(file))).phase29WorkerGuard};
  }
  const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'}),array=xs=>{const a=[];for(;xs.$==='Con';xs=xs.tail)a.push(xs.head);return a;};
  const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
  const lit=n=>({$:'KLiteral',kind:'U32',number:n>>>0,text:'',originBegin:0,originEnd:0});
  const typ=name=>t('ADT',name),v=id=>t('Var','',[],id),ref=name=>t('Ref',name),lam=(id,body)=>t('Lam','',[body],id,2),all=(id,a,b,q=2)=>t('All','',[a,b],id,q);
  const app=(f,x)=>t('App','',[f,x]),apply=(name,args)=>args.reduce((f,x)=>app(f,x),ref(name)),mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
  const d=(name,kind='Def',native=false,type=t('Typ'),value=t('Absent'),ctors=[],arity=0)=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
  const nat=typ('Nat'),u32=typ('U32');
  const ownerRows=()=>[
    d('Nat','ADT',true,t('Typ'),t('Absent'),[d('Zero','Ctr',true,nat),d('Succ','Ctr',true,all(900,nat,nat),t('Absent'),[],1)]),
    ...[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Bool',['True','False']],['F32',['F32']]].map(([name,cs])=>d(name,'ADT',true,t('Typ'),t('Absent'),cs.map(c=>d(c,'Ctr',true)))),
    d('Word','Def',true),d('U32.inc','Def',true,all(901,u32,u32),t('Absent'),[],1),d('U32.add','Def',true,all(901,u32,all(902,u32,u32)),t('Absent'),[],2),
  ];
  const definition=(name='loop',body=apply(name,[v(10),apply('U32.inc',[v(11)])]),zero=lam(12,v(12)),succId=10,argId=11)=>d(name,'Def',false,all(1,nat,all(2,u32,u32)),mat('Zero',zero,mat('Succ',lam(succId,lam(argId,body)))),[],2);
  const check=(name,def,rows,expected)=>{const got=api.j_nat_loop_worker(list([...rows,def]),def);assert.equal(got!=='',expected,name);report.guards.push({name,accepted:got!=='',bytes:Buffer.byteLength(got)});return got;};
  const yes=(name,def=definition(),rows=ownerRows())=>check(name,def,rows,true),no=(name,def=definition(),rows=ownerRows())=>check(name,def,rows,false);
  yes('countdown');yes('annotations',definition('loop',t('Ann','',[apply('loop',[v(10),v(11)]),u32])));
  {
    const def=definition(),rows=ownerRows();rows.push(d('LoopType','Def',false,t('Typ'),def.typ));def.typ=ref('LoopType');yes('aliased-signature',def,rows);
  }
  for(const change of ['kind','native-function','template','root-name','missing-succ','extra-alternative','non-native-Nat','non-native-Zero','non-native-Succ','wrong-Succ-domain','erased-Succ-field','wrong-Zero-result']){
    const def=definition(),rows=ownerRows(),root=def.value,parts=array(root.kids),natOwner=rows[0],constructors=array(natOwner.ctors);
    if(change==='kind')def.kind='Ctr';if(change==='native-function')def.native=true;if(change==='template')def.templates=1;if(change==='root-name')root.name='Succ';
    if(change==='missing-succ')root.kids=list([parts[0],t('Efq')]);if(change==='extra-alternative')parts[1].kids=list([array(parts[1].kids)[0],lam(99,lit(0))]);
    if(change==='non-native-Nat')natOwner.native=false;if(change==='non-native-Zero')constructors[0].native=false;if(change==='non-native-Succ')constructors[1].native=false;
    if(change==='wrong-Succ-domain')constructors[1].typ=all(900,u32,nat);if(change==='erased-Succ-field')constructors[1].typ=all(900,nat,nat,0);if(change==='wrong-Zero-result')constructors[0].typ=u32;
    no(change,def,rows);
  }
  no('non-predecessor-first',definition('loop',apply('loop',[v(11),v(11)])));
  no('computed-counter',definition('loop',apply('loop',[apply('Nat.sub',[v(10),t('Ctr','Zero')]),v(11)])));
  no('other-callee',definition('loop',apply('other',[v(10),v(11)])));
  no('missing-argument',definition('loop',apply('loop',[v(10)])));
  no('extra-argument',definition('loop',apply('loop',[v(10),v(11),v(11)])));
  no('non-tail-recursion',definition('loop',apply('U32.inc',[apply('loop',[v(10),v(11)])])));
  no('effect-before-zero-lambda',definition('loop',undefined,t('Let','',[t('Bind','',[ref('effect')],70,2),lam(12,v(12))])));
  no('predecessor-shadowed-by-residual-lambda',definition('loop',apply('loop',[v(10),v(10)]),lam(12,v(12)),10,10));
  no('predecessor-shadowed-by-let',definition('loop',t('Let','',[t('Bind','',[t('Ctr','Zero')],10,2),apply('loop',[v(10),v(11)])])));
  no('non-binding-let-node',definition('loop',t('Let','',[t('Wrong','',[lit(0)],20,2),apply('loop',[v(10),v(11)])])));
  no('missing-binding-value',definition('loop',t('Let','',[t('Bind','',[],20,2),apply('loop',[v(10),v(11)])])));
  no('extra-binding-value',definition('loop',t('Let','',[t('Bind','',[lit(0),lit(1)],20,2),apply('loop',[v(10),v(11)])])));
  no('duplicate-sibling-binding',definition('loop',t('Let','',[t('Bind','',[lit(0)],20,2),t('Bind','',[lit(1)],20,2),apply('loop',[v(10),v(11)])])));
  for(const position of [0,1]){const def=definition();if(position===0)def.typ.quant=0;else array(def.typ.kids)[1].quant=0;no('erased-signature-'+position,def);}
  for(const shape of ['function-result','parameterized-Nat','removed-Nat','residual-String']){
    const def=definition(),rest=array(def.typ.kids)[1];
    if(shape==='function-result')rest.kids=list([u32,all(3,u32,u32)]);
    if(shape==='parameterized-Nat')def.typ.kids=list([t('ADT','Nat',[lit(0)]),rest]);
    if(shape==='removed-Nat')def.typ.kids=list([t('ADT','Nat',[],0,0,['Zero']),rest]);
    if(shape==='residual-String')rest.kids=list([typ('String'),u32]);
    no(shape,def);
  }
  const erased=definition('erased',t('Let','',[t('Bind','',[ref('must_not_run')],20,0),apply('erased',[v(10),apply('U32.inc',[v(11)])])])),shadow=definition('shadow',t('Let','',[t('Bind','',[apply('U32.inc',[v(11)])],11,2),t('Bind','',[v(11)],21,2),apply('shadow',[v(10),v(21)])]));
  yes('erased-let',erased);yes('parallel-shadow-let',shadow);
  const rows=[...ownerRows(),d('must_not_run','Def',false,u32),erased,shadow];save(path.join(out,'book.json'),rows);
  const emission=api.j_library(list(rows)),file=path.join(out,'controls.mjs');fs.writeFileSync(file,fs.readFileSync(candidate.runtime,'utf8')+'\n'+emission,{flag:'wx'});report.module=identity(file);
  const {default:generated,G}=await import(pathToFileURL(file));let called=0;G.must_not_run={arity:0,code:()=>{called++;throw Error('erased RHS ran')},env:null,bound:[]};
  assert.equal(generated.erased(100n,7),107);assert.equal(called,0);report.observations.push({name:'erased-let-suppresses-RHS',result:107,calls:called});
  assert.equal(generated.shadow(100n,7),7);report.observations.push({name:'parallel-RHS-sees-old-binding',result:7});
  assert.equal((emission.match(/\/\* private Nat loop \*\//g)||[]).length,2);
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save(path.join(out,'report.json'),report);console.log(JSON.stringify({complete:report.complete,pass:report.pass,guards:report.guards.length,observations:report.observations.length,error:report.error}));
