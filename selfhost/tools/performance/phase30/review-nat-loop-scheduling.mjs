// Actual j_library witness for first-step/continuation scheduling and live self.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [oldAttempt,newAttempt,outArgument,mode='counterexample']=process.argv.slice(2);assert.ok(oldAttempt&&newAttempt&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const json=x=>JSON.stringify(x,(_,v)=>typeof v==='bigint'?String(v)+'n':v,2)+'\n';const save=(n,x)=>fs.writeFileSync(path.join(out,n),json(x),{flag:'wx'});
const report={kind:'phase30-actual-Nat-loop-scheduling',complete:false,mode,inputs:[identity(import.meta.filename)],emissions:[],observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-nat-loop-scheduling.mjs'));
try{
 const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
 const t=(tag,name='',kids=[],id=0,quant=0)=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list([]),originBegin:0,originEnd:0});
 const typ=name=>t('ADT',name),v=id=>t('Var','',[],id),ref=name=>t('Ref',name),lam=(id,body)=>t('Lam','',[body],id,2),all=(id,a,b)=>t('All','',[a,b],id,2);
 const call=(name,args)=>args.reduce((f,x)=>t('App','',[f,x]),ref(name)),mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
 const d=(name,kind='Def',native=false,type=t('Typ'),value=t('Absent'),ctors=[],arity=0)=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
 const nat=typ('Nat'),u32=typ('U32');
 const rows=[d('Nat','ADT',true,t('Typ'),t('Absent'),[d('Zero','Ctr',true,nat),d('Succ','Ctr',true,all(900,nat,nat),t('Absent'),[],1)]),
 ...[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Bool',['True','False']],['F32',['F32']]].map(([name,cs])=>d(name,'ADT',true,t('Typ'),t('Absent'),cs.map(c=>d(c,'Ctr',true)))),d('Word','Def',true),
 d('U32.inc','Def',true,all(901,u32,u32),t('Absent'),[],1),
 d('step','Def',false,all(3,u32,u32),lam(30,call('U32.inc',[v(30)])),[],1),
 d('loop','Def',false,all(1,nat,all(2,u32,u32)),mat('Zero',lam(12,v(12)),mat('Succ',lam(10,lam(11,call('loop',[v(10),call('step',[v(11)])]))))),[],2)];
 save('book.json',rows);const modules={};
 for(const [side,attempt]of [['baseline',oldAttempt],['candidate',newAttempt]]){
  const mf=path.resolve(attempt,'attempt.json'),m=JSON.parse(fs.readFileSync(mf)),driver=path.join(m.snapshot.root,'tools/typed-driver.mjs');
  report.inputs.push(...[mf,driver,...['api','runtime','base'].map(k=>m[k].file)].map(identity));for(const k of ['api','runtime','base'])assert.equal(identity(m[k].file).sha256,m[k].sha256);
  for(const k of Object.keys(process.env))if(k.startsWith('BEND_'))delete process.env[k];process.env.BEND_TYPED_API=m.api.file;process.env.BEND_TYPED_RUNTIME=m.runtime.file;process.env.BEND_BASE=m.base.file;
  const {loadApi}=await import(pathToFileURL(driver)),api=await loadApi(),code=api.j_library(list(rows));
  const file=path.join(out,side+'.mjs');fs.writeFileSync(file,fs.readFileSync(m.runtime.file,'utf8')+'\n'+code+'\nexport {force};\n',{flag:'wx'});
  const assignment=code.split('\n').find(x=>x.startsWith('G["loop"]=')).replaceAll('\r','');report.emissions.push({side,module:identity(file),assignment});modules[side]=await import(pathToFileURL(file));
 }
 const observe=(m,kind)=>{const events=[],step=m.G.step,loop=m.G.loop,host=(arity,code)=>({arity,code,env:null,bound:[]});
  m.G.step=host(1,a=>{events.push(['step',a[0]]);return a[0]+1});
  try{
   if(kind==='self-binding-mutation'){
    let calls=0;m.G.step=host(1,a=>{events.push(['step',a[0]]);if(calls++===0)m.G.loop=host(2,b=>{events.push(['replacement',...b]);return 1000+b[1]});return a[0]+1});
    return {events,value:m.default.loop(3n,7)};
   }
   const p=m.default.loop(2n);
   if(kind==='raw-callback'){const raw=p.code.call(null,[1n,7]),before=[...events],isBounce=raw?.bounce===true,value=m.force(raw);return {before,events,isBounce,value}}
   let reads=0;const copied=new Proxy([1n,7,99],{get(target,key,receiver){if(key==='length'){reads++;events.push(['copied.length',reads]);if(reads===4&&kind==='oversaturation-mutation')m.G.step=host(1,a=>{events.push(['changed-step',a[0]]);return a[0]+10});if(reads===4&&kind==='oversaturation-error')throw Error('length sentinel')}return Reflect.get(target,key,receiver)}});
   let value,error;try{value=m.call({...p,bound:[]},{slice(){events.push('input.slice');return copied}})}catch(e){error={name:e.name,message:e.message}}return {events,value,error};
  }finally{m.G.step=step;m.G.loop=loop}
 };
 for(const kind of ['oversaturation-order','oversaturation-mutation','oversaturation-error','raw-callback','self-binding-mutation']){
  const baseline=observe(modules.baseline,kind),candidate=observe(modules.candidate,kind),same=json(baseline)===json(candidate);report.observations.push({kind,baseline,candidate,same});
  if(mode==='repaired')assert.deepEqual(candidate,baseline,kind);
 }
 const differences=report.observations.filter(x=>!x.same).length;report.differences=differences;
 if(mode==='counterexample')assert.ok(differences>=4,'must retain concrete existing-worker counterexamples');
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
save('report.json',report);console.log(json({complete:report.complete,mode,observations:report.observations.length,differences:report.differences,error:report.error}));
