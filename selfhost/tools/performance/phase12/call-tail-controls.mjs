import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import{pathToFileURL}from'node:url';import{identity,verifyIdentity}from'../../development/workflow.mjs';import{transformChoices as lowerLiteralChoices}from'./call-choice.mjs';import{transformTailChoices as transformChoices}from'./call-tail.mjs';
const [baselineArg,candidateArg,outArg]=process.argv.slice(2);const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});const inputs=[import.meta.filename,path.join(import.meta.dirname,'call-choice.mjs'),path.join(import.meta.dirname,'call-tail.mjs'),baselineArg,candidateArg,process.execPath].map(identity);fs.copyFileSync(import.meta.filename,path.join(out,'call-tail-controls.mjs'));const original=fs.readFileSync(baselineArg,'utf8'),actual=fs.readFileSync(candidateArg,'utf8');assert.equal(transformChoices(original).source,actual);
const prefix=original.slice(0,original.indexOf('// Program\n// =======\n')+'// Program\n// =======\n'.length);const body=n=>original.match(new RegExp('function \\$'+n+'\\$\\([^\\n]+\\) \\{\\n[\\s\\S]*?^\\}','m'))[0];
const rawSynthetic=prefix+body('kc')+'\n'+body('f_choose')+'\n'+body('nt_choose')+`
function $choose$(_b_0, _effect_0, _a_0, _b_1) {
 return $nt_choose$(_effect_0("condition", _b_0),run_clo((_u_0)=>{const _effect_1=_effect_0("yes", _u_0.$);return _a_0;}),run_clo((_u_1)=>{const _effect_1=_effect_0("no", _u_1.$);return _b_1;}));
}
function $nested$(_a_0,_b_0,_effect_0){return $nt_choose$(_a_0,run_clo((_u_0)=>{return $f_choose$(_b_0,run_clo((_u_1)=>{return _effect_0("first");}),run_clo((_u_2)=>{return _effect_0("second");}));}),run_clo((_u_3)=>{return _effect_0("third");}));}
function $down$(_n_0,_a_0){return $nt_choose$(_n_0>0,run_clo((_u_0)=>{return $down$(_n_0-1,_a_0+1);}),run_clo((_u_1)=>{return _a_0;}));}
function $dynamic$(_b_0,_yes_0,_no_0){return $nt_choose$(_b_0,_yes_0,_no_0);}
export default {choose:run_lib((_b_0,_e_0,_a_0,_b_1)=>run_loop($choose$(_b_0,_e_0,_a_0,_b_1)),4),nested:run_lib((_a_0,_b_0,_e_0)=>run_loop($nested$(_a_0,_b_0,_e_0)),3),down:run_lib((_n_0,_a_0)=>run_loop($down$(_n_0,_a_0)),2),dynamic:run_lib((_b_0,_y_0,_n_0)=>run_loop($dynamic$(_b_0,_y_0,_n_0)),3)};
`;
const synthetic=lowerLiteralChoices(rawSynthetic).source;
const report={kind:'phase12-choice-boundary-controls',complete:false,pass:false,inputs,checks:[],scope:'Synthetic structurally recognized control bodies and actual compiled public API graphs; not full-language conformance.'};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{
 const transformed=transformChoices(synthetic);assert.equal(transformed.report.sites,4);assert.equal(transformed.report.skipped.length,0);report.syntheticTransform=transformed.report;const variants=[];
 for(const [name,text]of [['baseline',synthetic],['candidate',transformed.source]]){const file=path.join(out,name+'-synthetic.mjs');fs.writeFileSync(file,text);variants.push((await import(pathToFileURL(file))).default);}
 const observe=fn=>{try{return{value:fn()};}catch(e){return{error:e?.name+': '+e?.message};}};const same=(name,fn)=>{const xs=variants.map(fn);assert.deepEqual(xs[1],xs[0],name);report.checks.push({name,result:xs[0]});};
 for(const condition of [true,false,0,1,'','x',null,undefined,{},[]])same('truthiness '+String(condition),api=>{const log=[];const result=api.choose(condition,(label,value)=>{log.push([label,value]);return value;},17,23);return{result,log};});
 for(const a of [false,true])for(const b of [false,true])same('nested '+a+b,api=>{const log=[];const result=api.nested(a,b,label=>{log.push(label);return label});return{result,log};});
 for(const condition of [true,false])same('chosen exception '+condition,api=>{const log=[];const result=observe(()=>api.nested(condition,true,label=>{log.push(label);throw new Error(label)}));return{result,log};});
 same('condition exception precedes branches',api=>observe(()=>api.choose(true,()=>{throw new Error('condition')},17,23)));
 same('partial application',api=>api.choose(true)((label,value)=>value)(17)(23));
 same('overapplication ignored by existing export',api=>api.choose(false,(label,value)=>value,17,23,'extra'));
 same('dynamic nonliteral thunk fallback',api=>api.dynamic(true,u=>u.$+' yes',()=>{throw Error('unselected')}));
 same('returned function can be called',api=>api.choose(true,(label,value)=>value,x=>x+7,x=>x+8)(5));
 same('raw jump return retains outer forcing',api=>api.choose(true,(label,value)=>value,{$:'$JMP',f:x=>x+1,x:[40]},null));
 same('100000 tail iterations',api=>api.down(100000,0));
 for(const [name,bad]of [['runtime',synthetic.replace('function run_tail(f, x) {','function run_tail(f, x) {\nthrow 0;')],['this',synthetic.replace('function $down$(_n_0,_a_0){','function $down$(_n_0,_a_0){this.x;')],['shadowed',synthetic.replace('function $down$(_n_0,_a_0)','function $down$(_n_0,run_tail)')]]){assert.throws(()=>transformChoices(bad));report.checks.push({name:'refuse '+name,pass:true});}
 const apis=[];for(const file of [baselineArg,candidateArg])apis.push((await import(pathToFileURL(path.resolve(file)))).default);const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
 for(const n of [4,16,64]){const text='type Bit is Data:\n  On{}\n'+Array.from({length:n},(_,i)=>'def value'+i+'() -> Bit:\n  On{}\n').join('');const file=path.join(out,'ordinary-'+n+'.bend');fs.writeFileSync(file,text);inputs.push(identity(file));const observations=apis.map(api=>{const sources=list([{$:'FSource',name:'main',path:'/main.bend',text}]);const trace=api.f_load_graph_trace('/main.bend',sources);assert.equal(trace.result.error,'');const checked=api.check_book(trace.result.book);assert.equal(checked,'');return{trace,checked,report:api.driver_report(trace.result.book,list([]))};});assert.deepEqual(observations[1],observations[0]);report.checks.push({name:'actual graph/check/report '+n,pass:true});fs.writeFileSync(path.join(out,'ordinary-'+n+'-observations.json'),JSON.stringify(observations,null,2)+'\n');}
 inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,checks:report.checks.length,error:report.error}));
