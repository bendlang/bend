// Disposable operation counters and independent lazy-control ablations.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
const [attemptArg,outArg]=process.argv.slice(2);const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const m=await verifyAttempt(path.resolve(attemptArg));
const inputs=[import.meta.filename,process.execPath,path.join(attemptArg,'attempt.json'),m.api.file,m.checkedApi.file,m.bootstrapReport.file,m.runtime.file,m.base.file].map(identity);
const original=fs.readFileSync(m.api.file,'utf8');
const aliasBefore='($Bool$and$(($Bool$and$(($Bool$not$(($String$eq$(_name_0, ($nm$(_t_0)))))), ($f_declared$(_name_0, _scope_0)))), ($f_declared$(($nm$(_t_0)), _scope_0))))';
const aliasAfter='(($Bool$not$($String$eq$(_name_0, $nm$(_t_0)))) ? ($Bool$and$($f_declared$(_name_0, _scope_0), $f_declared$($nm$(_t_0), _scope_0))) : false)';
const scannerBefore='    const _x_0 = ($f_eq$(_name_0, ($dn$(_d_0))));\n    const _x_1 = ($f_declared$(_name_0, ($dc$(_d_0))));\n    const _x_2 = (_x_0 || _x_1);\n    const _x_3 = ($f_declared$(_name_0, _ds_0));\n    return (_x_2 || _x_3);';
const scannerAfter='    return $f_eq$(_name_0, $dn$(_d_0)) || $f_declared$(_name_0, $dc$(_d_0)) || $f_declared$(_name_0, _ds_0);';
const once=(s,a,b)=>{assert.equal(s.split(a).length,2);return s.replace(a,b)};
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const term=(name)=>({$:'KTerm',tag:'Ref',name,id:0,quant:0,kids:list([]),removed:list([])});
const def=(name,ctors=[])=>({$:'KDef',name,kind:'Def',arity:0,templates:0,typ:term('Absent'),value:term('Absent'),ctors:list(ctors),native:false,unsafe:false});
const report={kind:'phase10-membership-operation-controls',complete:false,started:new Date().toISOString(),inputs,scope:'Counter-only generated image ablations; not checked candidates and not timing samples.',variants:[],rows:[],rawBoundary:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try {
const variants=[];
for(const name of ['baseline','alias','scanner','combined']) {
 let s=original;if(['alias','combined'].includes(name))s=once(s,aliasBefore,aliasAfter);if(['scanner','combined'].includes(name))s=once(s,scannerBefore,scannerAfter);
 s='let __counts={calls:0,cells:0};\n'+once(s,'function $f_declared$(_name_0, _book_0) {','function $f_declared$(_name_0, _book_0) {\n__counts.calls++; if(_book_0.$!=="Nil")__counts.cells++;');
 s+='\nexport function __reset(){__counts={calls:0,cells:0};} export function __get(){return {...__counts};} export function __alias(t,imports,scope,name){return run_loop($f_alias_named$(t,imports,scope,name));} export function __declared(name,book){return run_loop($f_declared$(name,book));}\n';
 const file=path.join(out,name+'.mjs');fs.writeFileSync(file,s,{flag:'wx'});const K=await import(pathToFileURL(file));variants.push({name,K});report.variants.push({name,image:identity(file)});
}
const fixtures=[];
for(const n of [4,8,16,32]){
 const dep='type Bit is Data:\n  O{}\n  I{}\n'+Array.from({length:n},(_,i)=>`def value${i}() -> Bit:\n  O{}\n`).join('');
 const main='import dep.bend as dep\n'+Array.from({length:n},(_,i)=>`def copy${i}() -> dep.Bit:\n  dep.value${i}\n`).join('');
 fixtures.push({name:'ordinary-'+n,n,sources:[{$:'FSource',name:'main',path:'/main.bend',text:main},{$:'FSource',name:'dep',path:'/dep.bend',text:dep}]});
}
fixtures.push({name:'alias-replacement',sources:[{$:'FSource',name:'main',path:'/main.bend',text:'import dep.bend as D\ndef copy() -> D.Bit:\n  D.O{}\n'},{$:'FSource',name:'dep',path:'/dep.bend',text:'type Bit is Data:\n  O{}\n'}]});
fixtures.push({name:'duplicate-refusal',sources:[{$:'FSource',name:'main',path:'/main.bend',text:'type Bit is Data:\n  O{}\ndef value() -> Bit:\n  O{}\ndef value() -> Bit:\n  O{}\n'}]});
for(const fixture of fixtures){
 const file=path.join(out,fixture.name+'.json');fs.writeFileSync(file,JSON.stringify(fixture,null,2)+'\n');inputs.push(identity(file));let reference;
 for(const {name,K} of variants){K.__reset();const result=K.default.f_load_graph('/main.bend',list(fixture.sources));const counts=K.__get();if(fixture.name!=='duplicate-refusal')assert.equal(result.error,'',fixture.name+' must load');const checked=K.default.check_book(result.book);if(fixture.name!=='duplicate-refusal')assert.equal(checked,'',fixture.name+' must check');const observation={result,checked};if(name==='baseline')reference=observation;else assert.deepEqual(observation,reference,fixture.name+'/'+name);report.rows.push({fixture:fixture.name,n:fixture.n,variant:name,counts,error:result.error,checked,exactBaseline:true,inputHash:identity(file).sha256});fs.writeFileSync(path.join(out,fixture.name+'-'+name+'-result.json'),JSON.stringify(observation,null,2)+'\n');}
}
// Typed internal membership boundary: duplicates, empty names, nested constructors,
// Unicode and an exact 32-bit hash collision remain plain equality queries.
for(const names of [['','same','same'],['α','😀','a'],['left','right']])for(const query of [...names,'missing']){
 const book=list(names.map((n,i)=>def(n,i===0?[def('Nested')]:[])));let expected;
 for(const {name,K}of variants){K.__reset();const result=K.__declared(query,book);if(name==='baseline')expected=result;else assert.equal(result,expected);report.rows.push({fixture:'direct-'+JSON.stringify([names,query]),variant:name,counts:K.__get(),result,exactBaseline:true});}
}
for(const boundary of [{name:'unchanged malformed scope',term:term('same'),scope:list([null]),target:'same'},{name:'hit before malformed tail',query:'hit',scope:list([def('hit'),null])}]){
 const outcomes=[];for(const {name,K}of variants){try{outcomes.push({variant:name,result:boundary.query?K.__declared(boundary.query,boundary.scope):K.__alias(boundary.term,list([]),boundary.scope,boundary.target)});}catch(e){outcomes.push({variant:name,error:e.name+': '+e.message});}}report.rawBoundary.push({name:boundary.name,outcomes});
}
inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;
}catch(e){report.error=e.stack;process.exitCode=1;}report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,error:report.error,rows:report.rows.filter(r=>r.n||r.fixture==='alias-replacement').map(({fixture,variant,counts,error,checked})=>({fixture,variant,counts,error,checked})),rawBoundary:report.rawBoundary}));
