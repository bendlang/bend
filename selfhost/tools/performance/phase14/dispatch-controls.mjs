// Finite raw normalizer demand controls on genuinely upstream-checked components.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
const [componentArg,outArg]=process.argv.slice(2),out=path.resolve(outArg),component=JSON.parse(fs.readFileSync(componentArg));
assert.equal(process.version,'v24.18.0');assert.ok(component.complete&&component.pass);fs.mkdirSync(out);
const report={kind:'phase14-normalizer-component-demand-controls',complete:false,pass:false,scope:'Finite ordinary/raw data and throwing getter controls; not equivalence for arbitrary stateful JavaScript objects.',inputs:[identity(import.meta.filename),identity(componentArg),identity(process.execPath),...component.variants.map(v=>v.api)],rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const nil=()=>({$: 'Nil'}),list=xs=>xs.reduceRight((tail,head)=>({$: 'Con',head,tail}),nil());
const term=(tag,kids=[],name='',id=0,quant=0)=>({$: 'KTerm',tag,name,id,quant,kids:list(kids),removed:nil()});
const value=()=>term('Ctr',[],'O');
const makeDef=(v,arity=0)=>({$: 'KDef',name:'foo',kind:'Def',arity,templates:0,typ:term('Absent'),value:v,ctors:nil(),native:false,unsafe:false});
const fixtures=[];const add=(name,make)=>fixtures.push({name,make});
for(const tag of ['Absent','Ctr','Qua','Typ','Var','Hol','Efq','Unknown'])add('default-'+tag,()=>({t:term(tag),identity:'t'}));
add('app-beta',()=>({t:term('App',[term('Lam',[term('Var',[],'x',1)],'x',1),value()])}));
add('ann',()=>({t:term('Ann',[value(),term('Typ')])}));
add('let-empty',()=>({t:term('Let')}));
add('let-singleton',()=>({t:term('Let',[value()])}));
add('ref-filled',()=>({t:term('Ref',[],'foo'),book:list([makeDef(value())])}));
add('ref-missing',()=>({t:term('Ref',[],'missing'),identity:'t'}));
add('ref-under-applied',()=>({t:term('Ref',[],'foo'),book:list([makeDef(value(),1)]),identity:'t'}));
add('min-data-left',()=>({t:term('Min',[term('Qua',[],'',0,2),term('Qua',[],'',0,1)])}));
add('min-type-left',()=>({t:term('Min',[term('Qua',[],'',0,0),term('Qua',[],'',0,1)])}));
add('rewrite-reflexive',()=>({t:term('Rwt',[term('Rfl'),term('Absent'),value()])}));
add('rewrite-stuck',()=>({t:term('Rwt',[value(),term('Absent'),term('Absent')]),identity:'t'}));
add('lambda-argument',()=>({t:term('Lam',[term('Var',[],'x',1)],'x',1),args:list([value()])}));
add('exfalso-fallback',()=>({t:term('Efq'),args:list([value()]),left:1,identity:'fallback'}));
add('application-opaque',()=>({t:value(),args:list([term('Qua')])}));
for(const tag of ['App','Ann','Let','Ref','Min','Rwt','Ctr']){
 add('ordered-tests-'+tag,()=>{const trace=[],t=term(tag,tag==='Rwt'?[term('Rfl'),term('Absent'),value()]:tag==='Min'?[term('Qua',[],'',0,2),value()]:tag==='App'?[value(),value()]:[value()]);Object.defineProperty(t,'tag',{enumerable:true,get(){trace.push('tag');return tag;}});return {t,trace};});
}
for(const tag of ['Ctr','Qua','Unknown'])add('unused-fields-'+tag,()=>{const trace=[],t=term(tag);for(const key of ['name','kids','id','quant','removed'])Object.defineProperty(t,key,{enumerable:true,get(){trace.push(key);throw Error('unwanted:'+key);}});return {t,trace,identity:'t'};});
for(const tag of ['App','Ann','Let','Min','Rwt'])add('selected-bad-kids-'+tag,()=>{const t=term(tag);t.kids=null;return {t};});
add('selected-bad-ref-book',()=>({t:term('Ref',[],'foo'),book:null}));
add('null-term',()=>({t:null}));
add('deep-annotation-5000',()=>{let t=value();for(let i=0;i<5000;i++)t=term('Ann',[t]);return {t};});
add('deep-application-5000',()=>{let t=value();for(let i=0;i<5000;i++)t=term('App',[t,value()]);return {t,summary:r=>({tag:r.tag})};});
const observe=(K,fixture)=>{const data=fixture.make(),{t,book=nil(),args=nil(),left=0,fallback=term('Fallback'),trace=[]}=data;let result;
 try{const r=K.norm_eval_node(book,t,args,left,fallback);if(data.identity){assert.equal(r,data.identity==='t'?t:fallback);result={kind:'identity',value:data.identity};}else result={kind:'value',value:data.summary?data.summary(r):JSON.parse(JSON.stringify(r))};}
 catch(e){result={kind:'throw',name:e.name,message:e.message};}return {...result,trace};};
try{const variants=await Promise.all(component.variants.map(async v=>({name:v.name,K:(await import(pathToFileURL(v.api.file))).default})));
 for(const fixture of fixtures){const observations=variants.map(({name,K})=>({name,result:observe(K,fixture)}));report.rows.push({name:fixture.name,observations});save();assert.deepEqual(observations[1].result,observations[0].result,fixture.name);}
 for(const row of report.rows)if(!row.name.startsWith('selected-bad')&&row.name!=='null-term')assert.notEqual(row.observations[0].result.kind,'throw',row.name+' unexpectedly threw');
 report.inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:report.rows.length,error:report.error}));
