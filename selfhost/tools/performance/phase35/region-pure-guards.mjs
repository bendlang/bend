// Synthetic typed-proof controls. Root runs against an acquired checked API.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [configArg,outArg]=process.argv.slice(2);assert(configArg&&outArg,'usage: region-pure-guards.mjs CANDIDATE_CONFIG NEW_OUT');
const config=JSON.parse(fs.readFileSync(configArg)),candidate=config.candidate??config,out=path.resolve(outArg);
fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase35-private-purity-recognizer-controls',complete:false,pass:false,inputs:[import.meta.filename,configArg,candidate.api].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const unlist=xs=>{const r=[];for(;xs.$==='Con';xs=xs.tail)r.push(xs.head);assert.equal(xs.$,'Nil');return r;};
let serial=200;
const t=(tag,name='',kids=[],id=0,quant=0,removed=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:list(removed),originBegin:0,originEnd:0});
const lit=(number,kind='U32')=>({$:'KLiteral',kind,number,text:'',originBegin:0,originEnd:0});
const ty=name=>t('ADT',name),nat=ty('Nat'),u32=ty('U32'),f32=ty('F32'),expr=ty('Expr');
const variable=id=>t('Var','',[],id),all=(a,b,q=2)=>t('All','',[a,b],serial++,q),lam=(body,id=serial++)=>t('Lam','',[body],id,2);
const mat=(name,arm,rest=t('Efq'))=>t('Mat',name,[arm,rest]);
const app=(name,...args)=>args.reduce((f,a)=>t('App','',[f,a]),t('Ref',name));
const kind=()=>t('Typ','',[t('Qua','',[],0,2)]);
const def=(name,tag,typ,arity=0,value=t('Absent'),native=false,ctors=[])=>({$:'KDef',name,kind:tag,typ,arity,value,native,templates:0,ctors:list(ctors),unsafe:false});
const ctor=(name,typ,arity=0,native=false)=>def(name,'Ctr',typ,arity,t('Absent'),native);
function book(){const rows=[def('Nat','ADT',kind(),0,t('Absent'),true,[ctor('Zero',nat,0,true),ctor('Succ',all(nat,nat),1,true)])];
 for(const [name,names]of [['U32',['U32']],['F32',['F32']],['Word.Nil',['WNil']],['Word.Con',['WCon']],['Bool',['False','True']]])rows.push(def(name,'ADT',kind(),0,t('Absent'),true,names.map(n=>ctor(n,ty(name),0,true))));
 rows.push(def('Word','Def',kind(),0,t('Absent'),true));
 rows.push(def('Expr','ADT',kind(),0,t('Absent'),false,[ctor('Leaf',all(u32,expr),1),ctor('Fork',all(expr,all(expr,expr)),2)]));return rows;
}
function idDef(name='id'){const id=serial++;return def(name,'Def',all(u32,u32),1,lam(variable(id),id));}
function genDef(){const p=serial++;return def('gen','Def',all(nat,expr),1,
 mat('Zero',t('Ctr','Leaf',[lit(3)]),mat('Succ',lam(t('Ctr','Fork',[app('gen',variable(p)),app('gen',variable(p))]),p))));}
try{
 const original=fs.readFileSync(candidate.api,'utf8'),names=['j_pure_type','j_pure_signature','j_pure_graph'];
 for(const name of names)assert.equal(original.split('function $'+name+'$(').length,2,'exact checked helper '+name);
 const addition='\n// Diagnostic exports; original checked API bytes are unchanged.\nexport const phase35Pure={'+names.map(n=>n+':(...a)=>run_loop($'+n+'$(...a))').join(',')+'};\n';
 const diagnostic=path.join(out,'diagnostic-api.mjs');fs.writeFileSync(diagnostic,original+addition,{flag:'wx'});
 report.diagnostic={...identity(diagnostic),parentSha256:report.inputs[2].sha256,unchangedPrefixBytes:Buffer.byteLength(original)};
 const api=(await import(pathToFileURL(diagnostic))).phase35Pure;
 function typeProbe(name,typ,{rows=book(),expected=true}={}){const actual=api.j_pure_type(list(rows),typ);assert.equal(actual,expected,name);report.observations.push({name,actual});}
 function graph(name,d,{rows=book(),defs=[],fuel=32768,expected=true}={}){const result=api.j_pure_graph(list([...rows,d,...defs]),d,{$:'JPure',defs:list([]),fuel,valid:true});
  const dependencies=unlist(result.defs).map(x=>x.name);report.current={name,valid:result.valid,dependencies,fuel:result.fuel};assert.equal(result.valid,expected,name);report.observations.push(report.current);delete report.current;return dependencies;}
 typeProbe('recursive-tagged-type',expr);typeProbe('canonical-F32',f32);typeProbe('unknown-type',ty('Unknown'),{expected:false});
 typeProbe('function-field-type',all(u32,u32),{expected:false});typeProbe('type-parameters',t('ADT','Expr',[u32]),{expected:false});
 for(const mode of ['foreign-owner','quantity-one','foreign-constructor','wrong-result','erased-field','higher-order-field','late-bad-field']){
  const rows=book(),e=rows.find(d=>d.name==='Expr'),cs=unlist(e.ctors);
  if(mode==='foreign-owner')e.native=true;
  if(mode==='quantity-one')e.typ=t('Typ','',[t('Qua','',[],0,1)]);
  if(mode==='foreign-constructor')cs[1].native=true;
  if(mode==='wrong-result')cs[0].typ=all(u32,nat);
  if(mode==='erased-field')cs[0].typ=all(u32,expr,0);
  if(mode==='higher-order-field')cs[0].typ=all(all(u32,u32),expr);
  if(mode==='late-bad-field')cs.push(ctor('Late',all(all(u32,u32),expr),1));
  e.ctors=list(cs);typeProbe(mode,expr,{rows,expected:false});
 }
 for(const name of ['Array','IO']){const rows=book();rows.push(def(name,'ADT',kind(),0,t('Absent'),true,[ctor(name,ty(name),0,true)]));typeProbe('native-'+name,ty(name),{rows,expected:false});}
 graph('scalar-identity',idDef());const g=genDef();assert.deepEqual(graph('recursive-materialized-constructor-graph',g),['gen']);
 graph('zero-fuel',idDef(),{fuel:0,expected:false});graph('exhausted-body-fuel',idDef(),{fuel:1,expected:false});
 graph('zero-arity',def('constant','Def',u32,0,lit(1)),{expected:false});
 const p=serial++;graph('incomplete-match',def('incomplete','Def',all(nat,u32),1,mat('Zero',lit(1))),{expected:false});
 graph('default-match',def('default','Def',all(nat,u32),1,mat('Zero',lit(1),lam(lit(2),p))));
 graph('duplicate-match',def('duplicate','Def',all(nat,u32),1,mat('Zero',lit(1),mat('Zero',lit(2)))),{expected:false});
 graph('foreign-body',def('foreign','Def',all(u32,u32),1,lam(t('Foreign','foreign'))),{expected:false});
 graph('dynamic-call',def('dynamic','Def',all(u32,u32),1,lam(t('App','',[variable(p),lit(0)]),p)),{expected:false});
 graph('function-result',def('higher','Def',all(u32,all(u32,u32)),1,lam(lam(lit(1)))),{expected:false});
 graph('function-input',def('higherarg','Def',all(all(u32,u32),u32),1,lam(lit(1))),{expected:false});
 const aId=serial++,bId=serial++,a=def('a','Def',all(u32,u32),1,lam(app('b',variable(aId)),aId)),b=def('b','Def',all(u32,u32),1,lam(app('a',variable(bId)),bId));
 assert.deepEqual(graph('complete-mutual-cycle',a,{defs:[b]}).sort(),['a','b']);
 const badB={...b,value:lam(t('Foreign','foreign'),bId)};graph('bad-body-after-cycle-reservation',a,{defs:[badB],expected:false});
 const hidden=def('hidden','Def',all(u32,u32),1,lam(t('Foreign','foreign'),serial++));
 const q=serial++,branch=def('branch','Def',all(nat,u32),1,mat('Zero',lit(0),mat('Succ',lam(app('hidden',lit(1)),q))));
 graph('unselected-bad-arm',branch,{defs:[hidden],expected:false});
 const native=def('F32.to_u32','Def',all(f32,u32),1,t('Absent'),true);graph('approved-native',native);
 for(const mode of ['wrong-input','wrong-result','wrong-arity','foreign-body','different-native']){const d={...native};
  if(mode==='wrong-input')d.typ=all(u32,u32);if(mode==='wrong-result')d.typ=all(f32,f32);if(mode==='wrong-arity')d.arity=2;
  if(mode==='foreign-body')d.value=t('Foreign','foreign');if(mode==='different-native')d.name='Random.next';graph('native-'+mode,d,{expected:false});}
 const chain=[];for(let i=0;i<33;i++){const id=serial++;chain.push(def('chain'+i,'Def',all(u32,u32),1,lam(i===32?variable(id):app('chain'+(i+1),variable(id)),id)));}
 graph('33-definition-cap',chain[0],{defs:chain.slice(1),expected:false});
 graph('32-definition-cap',chain[1],{defs:chain.slice(2)});
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
