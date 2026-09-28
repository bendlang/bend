// Exact public observations on independently checked loader candidates.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
const [baseArg,aliasArg,combinedArg,countsArg,outArg]=process.argv.slice(2);const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const paths=[baseArg,aliasArg,combinedArg].map(p=>path.resolve(p));const inputs=[identity(import.meta.filename),identity(process.execPath)];
const report={kind:'phase10-checked-membership-controls',complete:false,pass:false,inputs,variants:[],rows:[],scope:'Exact public graph/check/trace/source-origin results and selected upstream import observations; no timing claim.'};const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try {
const variants=[];for(const [i,p]of paths.entries()){
 const m=await verifyAttempt(p);inputs.push(identity(path.join(p,'attempt.json')),m.api,m.checkedApi,m.bootstrapReport,m.runtime,m.base);
 for(const key of Object.keys(process.env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete process.env[key];
 Object.assign(process.env,{BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file});
 const driver=path.join(m.snapshot.root,'tools/typed-driver.mjs');inputs.push(identity(driver));const {default:api}=await import(pathToFileURL(m.api.file));const D=await import(pathToFileURL(driver));const name=['baseline','alias','combined'][i];variants.push({name,api,D,m});report.variants.push({name,api:m.api,source:identity(JSON.parse(fs.readFileSync(m.bootstrapReport.file)).source),runtime:m.runtime,base:m.base});
}
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
const record=(name,outputs)=>{for(const value of outputs.slice(1))assert.deepEqual(value.result,outputs[0].result,name+'/'+value.variant);report.rows.push({name,exact:true});fs.writeFileSync(path.join(out,name.replaceAll('/','_')+'.json'),JSON.stringify(outputs,null,2)+'\n');};
for(const name of ['ordinary-4','ordinary-8','ordinary-16','ordinary-32','alias-replacement','duplicate-refusal']){
 const file=path.resolve(countsArg,name+'.json');inputs.push(identity(file));const fixture=JSON.parse(fs.readFileSync(file));
 record(name,variants.map(({name:variant,api})=>{const sources=list(fixture.sources);const result=api.f_load_graph('/main.bend',sources),trace=api.f_load_graph_trace('/main.bend',sources);return {variant,result:{loaded:result,trace,checked:api.check_book(result.book),origins:api.f_load_origins_for('/main.bend',sources,'copy0')}};}));
}
const upstream=variants[0].m.config.upstream;
for(const name of ['alias_shadow','alias_decl','alias_twice','alias_file_name','shadow_base','shadow_tmpl','goal_alias','cross_file_proof','unsafe_law_own','suffix_refused']){
 const file=path.join(upstream,'tests/import',name+'.bend');inputs.push(identity(file));const outputs=[];
 for(const {name:variant,api,D}of variants){try{const graph=D.discoverSources(api,file);for(const dependency of graph.files)inputs.push(identity(dependency));}catch(error){inputs.push(identity(file));}const result=await D.inspect(file,{api,mode:'check',withReport:true});const {hostProvenance,...observed}=result;outputs.push({variant,result:observed});}
 record('import/'+name,outputs);
}
inputs.forEach(verifyIdentity);for(const p of paths)await verifyAttempt(p);report.inputsVerified=true;report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1;}report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
