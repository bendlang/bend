import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [attemptArg,outArg]=process.argv.slice(2),attempt=fs.realpathSync(attemptArg),out=path.resolve(outArg);fs.mkdirSync(out);
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')}),read=file=>JSON.parse(fs.readFileSync(file)),write=(name,data)=>fs.writeFileSync(path.join(out,name),JSON.stringify(data,null,2)+'\n');
const report={kind:'phase22-template-count-index-proof',complete:false,pass:false,scope:'Actual compiled primitive projection controls plus instrumented production calls. Appended extension is not a checked compiler or timing artifact. Different-count private initial duplicates are a required counterexample, not supported production input.',inputs:[identity(import.meta.filename),identity('design/phase22/context-template-index.md'),identity('design/phase22/context-template-index-proof.md')],primitive:[],production:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));const save=()=>write('report.json',report);save();
try {
 const a=read(path.join(attempt,'attempt.json')),W=await import(pathToFileURL(path.join(a.snapshot.root,'tools/development/workflow.mjs')));await W.verifyAttempt(attempt);report.api=a.api;report.inputs.push(identity(path.join(attempt,'attempt.json')),identity(a.api.file));
 const original=fs.readFileSync(a.api.file);for(const name of ['f_find','index_build','index_find','index_hash','f_graph_fill','f_context_declared','f_context_call_input'])assert(original.includes(Buffer.from('function $'+name+'$(')));
 const suffix=`
export const __projection=(prior,name)=>{const index=run_loop($index_build$(run_loop($List$reverse$(prior))));return {linear:run_loop($f_find$(name,prior)),indexed:run_loop($index_find$(index,name,run_loop($index_hash$(name,2166136261)),32))};};
export const __fill=(d,old)=>run_loop($f_graph_fill$(d,old));
export const __publish=(d,prior)=>{const index=run_loop($index_build$(run_loop($List$reverse$(prior))));const scope=run_loop($f_context_declared$(d,prior,index,'',{$:'Nil'}));return {linear:run_loop($f_find$(d.name,scope.prior)),indexed:run_loop($index_find$(scope.index,d.name,run_loop($index_hash$(d.name,2166136261)),32))};};
const __originalCall=$f_context_call_input$;let __calls={calls:0,refs:0,templateRefs:0,missingRefs:0,mismatches:[]};
$f_context_call_input$=(head,input,min)=>{__calls.calls++;if(head.tag==='Ref'){__calls.refs++;const scope=input.context.scope,name=head.name;const linear=run_loop($f_find$(name,scope.prior)),indexed=run_loop($index_find$(scope.index,name,run_loop($index_hash$(name,2166136261)),32));if(linear.templates>0)__calls.templateRefs++;if(linear.kind==='Missing')__calls.missingRefs++;if(linear.templates!==indexed.templates)__calls.mismatches.push({name,linear:linear.templates,indexed:indexed.templates});}return __originalCall(head,input,min);};
export const __reset=()=>{__calls={calls:0,refs:0,templateRefs:0,missingRefs:0,mismatches:[]};};export const __counts=()=>__calls;
`;
 const extension=path.join(out,'private-extension.mjs');fs.writeFileSync(extension,Buffer.concat([original,Buffer.from(suffix)]));assert(fs.readFileSync(extension).subarray(0,original.length).equals(original));report.extension={originalPrefixBytes:original.length,originalPrefixUnchanged:true,file:identity(extension),scope:'Named probe exports and instrumentation wrapper appended after unchanged generated production bytes.'};const P=await import(pathToFileURL(extension));
 const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil),term=(tag,name='',kids=[])=>({$:'KTerm',tag,name,id:0,quant:1,kids:list(kids),removed:nil,originBegin:0,originEnd:0}),def=(name,templates,opts={})=>({$:'KDef',name,kind:'Def',arity:templates,templates,typ:term('Set'),value:term('Absent'),ctors:nil,native:false,unsafe:false,...opts});
 const row=(name,actual,check)=>{check(actual);report.primitive.push({name,pass:true,actual});save();};
 row('unique-counts',P.__projection(list([def('a',0),def('b',2)]),'b'),x=>assert.equal(x.linear.templates,x.indexed.templates));
 row('same-count-different-definition',P.__projection(list([def('a',2,{arity:3}),def('a',2,{arity:7})]),'a'),x=>{assert.equal(x.linear.templates,x.indexed.templates);assert.notDeepEqual(x.linear,x.indexed);});
 row('negative-private-different-count-duplicates',P.__projection(list([def('a',1),def('a',2)]),'a'),x=>{assert.equal(x.linear.templates,1);assert.equal(x.indexed.templates,2);});
 row('missing-sentinel-projection',P.__projection(nil,'missing'),x=>{assert.equal(x.linear.templates,0);assert.equal(x.indexed.templates,0);assert.notDeepEqual(x.linear,x.indexed);});
 row('latest-publication-overrides-both',P.__publish(def('a',3),list([def('a',1),def('a',2)])),x=>{assert.deepEqual(x.linear,x.indexed);assert.equal(x.linear.templates,3);});
 const params=[term('Bind','A',[term('Qnt')]),term('Bind','x',[term('Qnt')])],fill=def('alias.f',0,{arity:2,typ:term('ImportLaw','alias.f',params),value:term('Set')}),law=def('dep.f',2,{arity:3});
 row('successful-imported-fill-inherits-count',P.__fill(fill,law),x=>{assert.equal(x.kind,'ImportFill');assert.equal(x.templates,2);assert.equal(x.name,'dep.f');});
 row('invalid-short-fill-is-error',P.__fill({...fill,arity:1},law),x=>assert.equal(x.typ.tag,'Error'));
 row('type-zero-count',P.__projection(list([def('T',0,{kind:'ADT'})]),'T'),x=>{assert.equal(x.linear.templates,0);assert.equal(x.indexed.templates,0);});
 process.env.BEND_BASE=a.base.file;const D=await import(pathToFileURL(path.join(a.snapshot.root,'tools/typed-driver.mjs')));
 const source=read('selfhost/build/phase22/installed-profile-01/request.json').source;
 const fixtures=[['template-self','selfhost/build/phase22/context-header-controls-01/fixtures/template-self.bend'],['local-template','selfhost/build/phase16/local-law-source-01/fixtures/ordinary-template.bend'],['imported-law-fill','selfhost/build/phase16/compact-final-context-host-01/fixtures/imported-law-fill/main.bend'],['compiler-workload',source]];
 for(const [name,file] of fixtures){P.__reset();const discovered=D.discoverSources(P.default,path.resolve(file));const counts=P.__counts();assert.equal(counts.mismatches.length,0);assert.equal(discovered.loadTrace.result.error,'');report.production.push({name,source:identity(file),files:discovered.files.map(identity),counts,pass:true});save();}
 assert(report.production.some(x=>x.counts.templateRefs>0));assert(report.production.every(x=>x.counts.calls>=0));await W.verifyAttempt(attempt);for(const input of report.inputs)assert.equal(identity(input.file).sha256,input.sha256);report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,primitive:report.primitive.length,production:report.production.map(x=>({name:x.name,...x.counts})),error:report.error}));if(!report.pass)process.exitCode=1;
