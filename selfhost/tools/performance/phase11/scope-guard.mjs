// Prospective P11-005: counter screen, exact controls and isolated source recipe.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
const [attemptArg,outArg,candidateAttemptArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const m=await verifyAttempt(path.resolve(attemptArg));const original=fs.readFileSync(m.api.file,'utf8');
const actual=candidateAttemptArg?await verifyAttempt(path.resolve(candidateAttemptArg)):null;
const before='  const _x_5 = ($f_eq$(($dk$(run_loop($f_find$(($nm$(_t_0)), _book_0)))), "ADT"));';
const after='  const _x_5 = (_x_3 === 3 && !_x_4) ? ($f_eq$(($dk$(run_loop($f_find$(($nm$(_t_0)), _book_0)))), "ADT")) : false;';
const sourceBefore='U32.is_eq(qt(t), 3) && (Bool.not(f_eq(tg(bound), "Absent")) || f_eq(dk(f_find(nm(t), book)), "ADT"))';
const sourceAfter='f_choose(Bool, U32.is_eq(qt(t), 3), u => f_choose(Bool, Bool.not(f_eq(tg(bound), "Absent")), u => True{}, u => f_eq(dk(f_find(nm(t), book)), "ADT")), u => False{})';
const once=(s,a,b)=>{assert.equal(s.split(a).length,2);return s.replace(a,b)};
const inputs=[import.meta.filename,process.execPath,path.join(attemptArg,'attempt.json'),m.api.file,m.bootstrapReport.file,m.base.file,m.runtime.file].map(identity);
if(actual)inputs.push(identity(path.join(candidateAttemptArg,'attempt.json')),identity(actual.api.file));
const report={kind:'phase11-scope-guard-counts-and-recipe',complete:false,inputs,scope:'Disposable generated counter ablation; source candidate requires separate genuine checked build. Not timing.',rows:[],rawBoundary:[],variants:[]};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const term=(tag,name='',quant=0,id=0,kids=[])=>({$:'KTerm',tag,name,quant,id,kids:list(kids),removed:list([])});
const def=(name,kind='Def')=>({$:'KDef',name,kind,arity:0,templates:0,typ:term('Set'),value:term('Absent'),ctors:list([]),native:false,unsafe:false});
try{
 const variants=[];
 for(const name of ['baseline','candidate']){
  let s=name==='baseline'?original:actual?fs.readFileSync(actual.api.file,'utf8'):once(original,before,after);
  s='let __count=0;\n'+once(s,'function $f_find$(_name_0, _book_0) {','function $f_find$(_name_0, _book_0) {\n__count++;');
  s+='\nexport function reset(){__count=0;}export function count(){return __count;}export function scope(t,b,book){return run_loop($f_scope_reference$(t,b,book));}\n';
  const file=path.join(out,name+'.mjs');fs.writeFileSync(file,s);const K=await import(pathToFileURL(file));variants.push({name,K});report.variants.push({name,image:identity(file)});
 }
 for(const n of [4,8,16,32]){
  const source='type Bit is Data:\n  O{}\n  I{}\n'+Array.from({length:n},(_,i)=>`def id${i}(x: Bit) -> Bit:\n  x\n`).join('');const input=path.join(out,'binders-'+n+'.bend');fs.writeFileSync(input,source);inputs.push(identity(input));let expected;
  for(const {name,K}of variants){K.reset();const parsed=K.default.f_load_graph('/main.bend',list([{$:'FSource',name:'main',path:'/main.bend',text:source}]));assert.equal(parsed.error,'');const checked=K.default.check_book(parsed.book);assert.equal(checked,'');const observation={parsed,checked};if(name==='baseline')expected=observation;else assert.deepEqual(observation,expected);report.rows.push({kind:'public',n,variant:name,count:K.count(),exactBaseline:true});fs.writeFileSync(path.join(out,'binders-'+n+'-'+name+'.json'),JSON.stringify(observation)+'\n');}
 }
 for(const quant of [0,1,2,3])for(const bound of [term('Absent'),term('Var','local',1,17)])for(const kind of ['Def','ADT','missing']){
  const t=term('Ref','Name',quant,4),book=list(kind==='missing'?[]:[def('Name',kind)]);let expected;
  for(const {name,K}of variants){K.reset();const result=K.scope(t,bound,book);if(name==='baseline')expected=result;else assert.deepEqual(result,expected);report.rows.push({kind:'direct',quant,bound:bound.tag,definition:kind,variant:name,count:K.count(),result,exactBaseline:true});}
 }
 for(const boundary of [{name:'unused book for ordinary local',quant:0,bound:term('Var','local',1,17)},{name:'known local offload refusal',quant:3,bound:term('Var','local',1,17)}]){
  const rows=[];for(const {name,K}of variants){try{rows.push({variant:name,result:K.scope(term('Ref','Name',boundary.quant),boundary.bound,null)});}catch(e){rows.push({variant:name,error:e.name+': '+e.message});}}report.rawBoundary.push({name:boundary.name,rows});
 }
 if(!actual){
 const project=path.join(out,'project');fs.mkdirSync(project);for(const name of ['src','tools','tests'])fs.cpSync(path.join(m.snapshot.root,name),path.join(project,name),{recursive:true});
 const file=path.join(project,'src/front/families.bend'),pre=identity(file);fs.writeFileSync(file,once(fs.readFileSync(file,'utf8'),sourceBefore,sourceAfter));
 const config=path.join(out,'candidate.json');fs.writeFileSync(config,JSON.stringify({project,upstream:m.config.upstream,jobs:1,cpu:'0',profile:'equality',timeoutMs:30000},null,2)+'\n');report.recipe={preimage:pre,modified:identity(file),config:identity(config),sourceBefore,sourceAfter};
 }else report.checkedCandidate={attempt:identity(path.join(candidateAttemptArg,'attempt.json')),api:actual.api};
 inputs.forEach(verifyIdentity);report.complete=true;
}catch(e){report.error=e.stack;process.exitCode=1;}save();console.log(JSON.stringify({complete:report.complete,error:report.error,rows:report.rows.filter(x=>x.kind==='public'),rawBoundary:report.rawBoundary,recipe:report.recipe}));
