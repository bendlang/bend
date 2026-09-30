// Independent synthetic-core controls through two actual j_library emitters.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [oldAttempt,newAttempt,outArgument]=process.argv.slice(2);assert.ok(oldAttempt&&newAttempt&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const sha=x=>createHash('sha256').update(x).digest('hex'),identity=file=>({file:fs.realpathSync(file),sha256:sha(fs.readFileSync(file))});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?{$bigint:String(v)}:v,2)+'\n';
const save=(name,x)=>fs.writeFileSync(path.join(out,name),json(x),{flag:'wx'});
const report={kind:'phase30-independent-owned-emitter-controls',complete:false,pass:false,node:process.version,
  inputs:[identity(import.meta.filename)],emissions:[],observations:[],scope:'Actual checked compiler APIs emit synthetic core books. No frontend admission or timing claim. Snapshot runtimes only.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-owned-emitter.mjs'));
try{
  const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
  const t=(tag,name='',kids=[],id=0,quant=0)=>({$:'KTerm',tag,name,kids:list(kids),id,quant,removed:list([]),originBegin:0,originEnd:0});
  const typ=t('ADT','Scalar'),v=id=>t('Var','',[],id),ref=name=>t('Ref',name),lam=(id,body)=>t('Lam','',[body],id,2),all=(id,a,b,q=2)=>t('All','',[a,b],id,q);
  const app=(f,x)=>t('App','',[f,x]),apps=(name,args)=>args.reduce(app,ref(name));
  const let1=(id,value,body,q=2)=>t('Let','',[t('Bind','',[value],id,q),body]);
  const d=(name,value,type)=>({$:'KDef',name,kind:'Def',arity:0,templates:0,typ:type,value,ctors:list([]),native:false,unsafe:false});
  const unary=all(100,typ,typ),binary=all(100,typ,unary),fnresult=all(100,typ,unary);
  const rows=[
    d('sink',t('Absent'),unary),d('left',t('Absent'),typ),d('right',t('Absent'),typ),d('danger',t('Absent'),typ),
    d('callee',lam(1,lam(2,v(1))),binary),
    d('erasedTarget',lam(3,lam(4,v(4))),all(100,typ,unary,0)),
    d('one',lam(10,let1(20,apps('sink',[v(10)]),v(20))),unary),
    d('batched',lam(11,lam(12,let1(21,apps('callee',[v(11),v(12)]),v(21)))),binary),
    d('tail',lam(13,apps('sink',[v(13)])),unary),
    d('partial',lam(14,let1(22,apps('callee',[v(14)]),v(22))),fnresult),
    d('erased',lam(15,let1(23,apps('erasedTarget',[ref('danger'),v(15)]),v(23))),unary),
    d('order',lam(16,let1(24,apps('callee',[ref('left'),ref('right')]),v(24))),unary),
    d('erasedLet',lam(17,let1(25,ref('danger'),v(17),0)),unary),
  ];
  save('book.json',rows);const modules={};
  for(const [side,attempt]of [['baseline',oldAttempt],['candidate',newAttempt]]){
    const mf=path.resolve(attempt,'attempt.json'),m=JSON.parse(fs.readFileSync(mf));
    const driver=path.join(m.snapshot.root,'tools/typed-driver.mjs');
    for(const file of [mf,m.api.file,m.runtime.file,m.base.file,driver])report.inputs.push(identity(file));
    for(const field of ['api','runtime','base'])assert.equal(identity(m[field].file).sha256,m[field].sha256);
    for(const k of Object.keys(process.env))if(k.startsWith('BEND_'))delete process.env[k];
    process.env.BEND_TYPED_API=m.api.file;process.env.BEND_TYPED_RUNTIME=m.runtime.file;process.env.BEND_BASE=m.base.file;
    const {loadApi}=await import(pathToFileURL(driver));const api=await loadApi(),code=api.j_library(list(rows));
    const file=path.join(out,side+'.mjs');fs.writeFileSync(file,fs.readFileSync(m.runtime.file,'utf8')+'\n'+code+'\nexport {fn,force,jump};\n',{flag:'wx'});
    const assignments=Object.fromEntries(['one','batched','partial','erased','order','tail'].map(name=>[name,code.split('\n').find(x=>x.startsWith('G['+JSON.stringify(name)+']='))]));
    for(const name of ['one','batched','partial','erased','order'])assert.equal(assignments[name].includes('callOwned('),side==='candidate',side+' '+name+' emission');
    assert.ok(assignments.tail.includes('jump('));assert.ok(!assignments.tail.includes('callOwned('));
    report.emissions.push({side,module:identity(file),assignments});modules[side]=await import(pathToFileURL(file));
  }
  const transcripts={};
  for(const [side,m]of Object.entries(modules)){
    const {default:a,G,call,fn,force,jump}=m,trace=[];
    const note=(name,value)=>trace.push({name,value});
    const desc=f=>({keys:Object.keys(f),arity:f.arity,env:f.env,bound:[...f.bound]});
    G.sink=fn(1,x=>{x[0]=71;x.push(73);return x});note('one-mutates-owned-vector',a.one(5));
    G.callee=fn(2,x=>{x[0]=79;x.push(83);return x});note('batched-mutates-owned-vector',a.batched(7,11));
    G.callee=fn(2,x=>{x[0]=89;return x});const p=a.partial(13);note('partial-before',desc(p));note('partial-result',call(p,[17]));note('partial-after',desc(p));
    let danger=0;G.danger=fn(0,()=>{danger++;throw Error('erased ran')});note('erased-argument',a.erased(19));note('erased-let',a.erasedLet(23));assert.equal(danger,0);note('erased-evaluations',danger);
    for(const fail of ['none','left','right','body']){
      const events=[];G.left=fn(0,()=>{events.push('left');if(fail==='left')throw Error('left sentinel');return 29});
      G.right=fn(0,()=>{events.push('right');if(fail==='right')throw Error('right sentinel');return 31});
      G.callee=fn(2,x=>{events.push(['body',...x]);if(fail==='body')throw Error('body sentinel');return x});
      let value;try{value={result:a.order(0)}}catch(e){value={error:e.message}}note('order-'+fail,{events,...value});
    }
    for(const arity of [0,1,2,3]){
      G.callee=fn(arity,x=>{x.push(97);return fn(1,y=>[...x,...y])});
      let value;try{const r=a.batched(37,41);value=r?.code?desc(r):r}catch(e){value={error:e.message}}note('changed-arity-'+arity,value);
    }
    {
      const events=[];G.sink={get code(){events.push('code');return x=>x[0]},get bound(){events.push('bound');return []},get arity(){events.push('arity');return 1},get env(){events.push('env');return null}};
      note('metadata-getters',{result:a.one(43),events});
    }
    {
      const vector=[47],target=fn(1,x=>{x[0]=101;return x});const result=call(target,vector);assert.deepEqual(vector,[47]);note('public-copy',{vector,result});
      const bounce=jump(fn(1,x=>++x[0]),[53]);note('reusable-tail',{first:force(bounce),second:force(bounce),args:bounce.args});assert.deepEqual(bounce.args,[53]);
    }
    {
      const env={increment:7};G.sink=fn(1,function(x){return this.increment+x[0]},env);note('environment',a.one(59));
      G.sink=null;note('null',a.one(61));G.sink={typeName:'T',typeArgs:[67]};note('type-application',a.one(71));
    }
    transcripts[side]=trace;
  }
  report.transcripts=transcripts;assert.deepEqual(transcripts.candidate,transcripts.baseline);report.observations=transcripts.candidate;
  report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
  report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save('report.json',report);console.log(json({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
