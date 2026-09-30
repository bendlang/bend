// Synthetic checked-core emission probes: preserve operand demand and errors.
import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);assert.ok(configFile&&outArgument);
const config=JSON.parse(fs.readFileSync(configFile)),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const save=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const t=(tag,name='',kids=[],id=0,quant=0)=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:{$:'Nil'},originBegin:0,originEnd:0});
const typ=name=>t('ADT',name),all=(a,b,id)=>t('All','',[a,b],id,2);
const literal=number=>({$:'KLiteral',kind:'Nat',number,text:'',originBegin:0,originEnd:0});
const ref=name=>t('Ref',name),app=(f,x)=>t('App','',[f,x]);
const def=(name,kind='Def',native=false,type=t('Typ'),value=t('Absent'),ctors=[],arity=0)=>({$:'KDef',name,kind,arity,templates:0,typ:type,value,ctors:list(ctors),native,unsafe:false});
const owners=[['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Nat',['Zero','Succ']]];
const rows=[...owners.map(([name,cs])=>def(name,'ADT',true,t('Typ'),t('Absent'),cs.map(c=>def(c,'Ctr')))),def('Word','Def',true),def('left','Def',false,typ('U32'))];
for(const op of ['shln','shrn']){
 rows.push(def('U32.'+op,'Def',true,all(typ('U32'),all(typ('Nat'),typ('U32'),2),1),t('Absent'),[],2));
 for(const count of [0,8,31,32,33,4294967295])for(const annotated of [false,true]){
  const n=literal(count),arg=annotated?t('Ann','',[n,typ('Nat')]):n;
  rows.push(def(op+'_'+count+(annotated?'_ann':''),'Def',false,typ('U32'),app(app(ref('U32.'+op),ref('left')),arg)));
 }
}
const report={kind:'phase30-literal-shift-operand-order',complete:false,pass:false,scope:'Synthetic KDefs through actual j_library; this does not claim frontend admission.',inputs:[identity(configFile),identity(import.meta.filename)],modules:{},observations:[]};
save(path.join(out,'book.json'),rows);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
try{
 const modules={};
 for(const side of ['baseline','candidate']){
  const c=config[side];for(const key of ['api','runtime','driver','base'])report.inputs.push(identity(c[key]));
  for(const key of Object.keys(process.env))if(key.startsWith('BEND_'))delete process.env[key];
  process.env.BEND_TYPED_API=c.api;process.env.BEND_TYPED_RUNTIME=c.runtime;process.env.BEND_BASE=c.base;
  const D=await import(pathToFileURL(c.driver)),api=await D.loadApi();
  const code=api.j_library(list(rows)),file=path.join(out,side+'.mjs');
  fs.writeFileSync(file,fs.readFileSync(c.runtime,'utf8')+'\n'+code,{flag:'wx'});
  report.modules[side]=identity(file);modules[side]=await import(pathToFileURL(file));
 }
 for(const op of ['shln','shrn'])for(const count of [0,8,31,32,33,4294967295])for(const annotated of [false,true])for(const behavior of ['number','throw','coercible','coercion-throw']){
  const name=op+'_'+count+(annotated?'_ann':''),observations={};
  for(const side of ['baseline','candidate']){
   const m=modules[side],events=[];m.G.left={arity:0,env:null,bound:[],code(){events.push('left');if(behavior==='throw')throw Error('left sentinel');
    if(behavior.startsWith('coerc'))return {valueOf(){events.push('coerce');if(behavior==='coercion-throw')throw Error('coercion sentinel');return 4294967295}};
    return 4294967295}};
   try{observations[side]={value:m.default[name](),events}}catch(error){observations[side]={error:{name:error.name,message:error.message},events}}
  }
  assert.deepEqual(observations.candidate,observations.baseline,name+' '+behavior);
  assert.equal(observations.candidate.events[0],'left');
  if(count>=32)assert.deepEqual(observations.candidate.events,['left'],'large shifts evaluate but never coerce their operand');
  report.observations.push({name,behavior,...observations.candidate});
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1}
save(path.join(out,'report.json'),report);console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
