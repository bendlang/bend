// Synthetic recognizer controls, distinct from checked-source conformance.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [configArg,outArg]=process.argv.slice(2);assert.ok(configArg&&outArg,'usage: region-nat-guards.mjs CANDIDATE_CONFIG NEW_OUT');
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const config=JSON.parse(fs.readFileSync(configArg,'utf8')),candidate=config.candidate??config;
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase35-private-nat-recognizer-controls',complete:false,pass:false,inputs:[import.meta.filename,configArg,candidate.api].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const unlist=xs=>{const result=[];for(;xs.$==='Con';xs=xs.tail)result.push(xs.head);assert.equal(xs.$,'Nil');return result;};
let serial=200;
const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
const lit=(number,kind='U32')=>({$:'KLiteral',kind,number,text:'',originBegin:0,originEnd:0});
const type=name=>t('ADT',name),nat=type('Nat'),u32=type('U32');
const variable=id=>t('Var','',[],id);
const all=(input,result,quant=2)=>t('All','',[input,result],serial++,quant);
const lam=(body,id=serial++)=>t('Lam','',[body],id,2);
const mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
const def=(name,kind,typ,arity=0,ctors=[],native=true)=>({$:'KDef',name,kind,arity,templates:0,typ,value:t('Absent'),ctors:list(ctors),native,unsafe:false});
function book(){
 const rows=[def('Nat','ADT',t('Typ','',[t('Qua','',[],0,2)]),0,[def('Zero','Ctr',nat),def('Succ','Ctr',all(nat,nat),1)])];
 for(const [name,names]of [['U32',['U32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Bool',['False','True']]])rows.push(def(name,'ADT',t('Typ'),0,names.map(n=>def(n,'Ctr',type(name)))));
 rows.push(def('Word','Def',t('Typ')));return rows;
}
function chain(depth,end=lam(lit(91)),offset=0,kind='U32'){return depth?mat('Zero',lit(offset+10,kind),mat('Succ',chain(depth-1,end,offset+1,kind))):end;}
function inspect(term){const rows=[],todo=[term];while(todo.length){const v=todo.pop();if(v.$==='KTerm'){rows.push({tag:v.tag,name:v.name,id:v.id,quant:v.quant});todo.push(...unlist(v.kids));}}return rows;}
try{
 const original=fs.readFileSync(candidate.api,'utf8');
 const exports=['j_region_nat_select','j_region_prefix'];
 for(const name of exports)assert.equal(original.split('function $'+name+'$(').length,2,'One exact generated definition '+name);
 const addition='\n// Diagnostic exports only; existing checked bodies remain byte-identical.\nexport const phase35NatGuards={'+exports.map(name=>name+':(...args)=>run_loop($'+name+'$(...args))').join(',')+'};\n';
 const diagnostic=path.join(out,'diagnostic-api.mjs');fs.writeFileSync(diagnostic,original+addition,{flag:'wx'});
 report.diagnostic={...identity(diagnostic),parentSha256:report.inputs[2].sha256,unchangedPrefixBytes:Buffer.byteLength(original)};
 const api=(await import(pathToFileURL(diagnostic))).phase35NatGuards;
 function probe(name,{rows=book(),term=chain(3),typ=all(nat,u32),slot=0,fuel=32768,left=1,keep=false,prefix=true,expected=true}={}){
  const state={$:'JRegionBuild',term:t('Absent'),helpers:list([]),fuel,valid:true};
  const result=prefix?api.j_region_prefix(list(rows),list([]),term,typ,slot,left,keep,'',list([]),0,state):api.j_region_nat_select(list(rows),list([]),term,typ,slot,0,list([]),0,state);
  assert.equal(result.valid,expected,name);const plan=inspect(result.term);
  report.observations.push({name,valid:result.valid,fuel:result.fuel,plan});return {result,plan};
 }
 const ordinary=probe('complete-three-case-chain');assert.equal(ordinary.plan.filter(x=>x.tag==='JNatCase').length,3);
 const remainderId=serial++,used=chain(8,lam(variable(remainderId),remainderId),0,'Nat');
 for(const slot of [0,7]){const {plan}=probe('used-default-remainder-slot-'+slot,{term:used,typ:all(nat,nat),slot});assert.ok(plan.some(x=>x.tag==='JNatRest'&&x.name==='8'&&x.id===slot));}
 probe('annotated-input-tree',{term:t('Ann','',[chain(3),all(nat,u32)])});
 probe('64-decisions',{term:chain(64)});probe('65-decisions-refused',{term:chain(65),expected:false});
 probe('zero-fuel-refused',{fuel:0,expected:false});probe('exhausted-fuel-refused',{fuel:2,expected:false});
 probe('erased-input-refused',{typ:all(nat,u32,0),expected:false});
 probe('non-native-input-kind-refused',{typ:all(u32,u32),expected:false});
 probe('unknown-result-type-refused',{typ:all(nat,type('String')),expected:false});
 probe('remaining-argument-refused',{typ:all(nat,all(u32,u32)),left:2,expected:false});
 probe('kept-prefix-refused',{keep:true,expected:false});
 probe('incomplete-succ-refused',{term:mat('Zero',lit(1)),expected:false});
 probe('reordered-constructor-refused',{term:mat('Succ',lam(lit(2)),mat('Zero',lit(1))),expected:false});
 probe('non-Efq-residual-refused',{term:mat('Zero',lit(1),mat('Succ',lam(lit(2)),lam(lit(3)))),expected:false});
 probe('computed-function-prefix-refused',{term:t('App','',[t('Ref','unknown'),lit(1)]),expected:false});
 for(const target of ['Nat','Zero','Succ'])for(const mode of ['missing','not-native','wrong-kind']){
  const rows=book();if(target==='Nat'){
   const at=rows.findIndex(x=>x.name===target);if(mode==='missing')rows.splice(at,1);else if(mode==='not-native')rows[at].native=false;else rows[at].kind='Def';
  }else{const owner=rows.find(x=>x.name==='Nat'),ctors=unlist(owner.ctors),at=ctors.findIndex(x=>x.name===target);if(mode==='missing')ctors.splice(at,1);else if(mode==='not-native')ctors[at].native=false;else ctors[at].kind='Def';owner.ctors=list(ctors);}
  probe(target+'-'+mode,{rows,expected:false});
 }
 for(const item of report.inputs)assert.deepEqual(identity(item.path),item);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
