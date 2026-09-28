// Independent tests of the actual capture resolver/lifter, including refusals.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
const [outArg]=process.argv.slice(2),out=path.resolve(outArg),root=path.resolve(import.meta.dirname,'../../..');
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const helper=path.join(root,'build/phase12/integrated-03/snapshot/tools/development/equality.mjs');
const origins=[helper,...['rewriter-structure.mjs','rewriter-v5.mjs','rewriter-lift.mjs'].map(n=>path.join(import.meta.dirname,n))],consumed=[];
for(const file of origins){const target=path.join(out,path.relative(root,file));fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(file,target);consumed.push(target);}
const L=await import(pathToFileURL(consumed[3])),V=await import(pathToFileURL(consumed[2]));
const m=await verifyAttempt(path.join(root,'build/phase12/integrated-03')),source=fs.readFileSync(m.checkedApi.file,'utf8');
const report={kind:'phase13-independent-actual-lifter-controls',complete:false,pass:false,scope:'Actual frozen lifter on synthetic generated-owner mutations plus exact existing candidate reproduction. Appended private test exports change no tested function body. Not a new checked B1 or performance result.',inputs:[import.meta.filename,process.execPath,...origins,...consumed,m.checkedApi.file].map(identity),rows:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,(_k,v)=>v===undefined?{$controlUndefined:true}:v,2)+'\n');save();
const choose=(yes,no='return run_loop(0);')=>`return $kc$(condition,run_clo((unit)=>{${yes}}),run_clo((unit)=>{${no}}));`;
const cases=[
 {name:'readonly parameter',params:'condition,x',body:choose('return run_loop(x);'),expect:'equivalent',run:api=>api(true,17)},
 {name:'transitive nested block arrow',params:'condition,x',body:choose('return (y)=>{return run_loop([x,y]);};'),expect:'equivalent',run:api=>api(true,17)(25)},
 {name:'nested block shadow',params:'condition,x',body:choose('return (x)=>{return run_loop(x);};'),expect:'equivalent',run:api=>api(true,17)(25)},
 {name:'computed property capture',params:'condition,record,key',body:choose('return run_loop(record[key]);'),expect:'equivalent',run:api=>api(true,{value:17},'value')},
 {name:'undefined is a legal shadowing parameter',params:'condition,undefined',body:choose('return run_loop(undefined);'),expect:'refuse-or-equivalent',run:api=>api(true,17)},
 ...[['<<=',7],['>>=',8],['>>>=',-1]].map(([op,input])=>({name:'captured shift write '+op,params:'condition,x,save',body:'save((unit)=>{return x;});'+choose(`x ${op} 1;return run_loop(x);`),expect:'refuse',run:api=>{let saved;const value=api(true,input,fn=>{saved=fn;});return{value,saved:saved({$:'Unit'})};}})),
 {name:'ordinary assignment refused',params:'condition,x',body:choose('x=2;return run_loop(x);'),expect:'refuse',run:api=>api(true,17)},
 {name:'later const refused',params:'condition',body:'const jump=$kc$(condition,run_clo((unit)=>{return run_loop(x);}),run_clo((unit)=>{return run_loop(0);}));const x=17;return jump;',expect:'refuse',run:api=>api(true)},
 {name:'unparenthesized arrow unsupported shape',params:'condition,x',body:choose('return x=>{return run_loop(x);};'),expect:'refuse',run:api=>api(true,17)(25)},
 {name:'lexical arguments refused',params:'condition,x',body:choose('return run_loop(arguments[1]);'),expect:'refuse',run:api=>api(true,17)},
];
const observe=fn=>{try{return {value:fn()};}catch(e){return{error:{name:e.name,message:e.message}};}};
try{
 const candidate=path.join(root,'build/phase13/rewriter-norm-eval-01/api.mjs'),actual=L.transform(source,{families:['$norm_eval_node$']});report.inputs.push(identity(candidate));assert.equal(actual.source,fs.readFileSync(candidate,'utf8'));report.existingCandidate={api:identity(candidate),sites:actual.report.sites,workers:actual.report.workers.length,staticCaptures:actual.report.staticCaptureElements,exact:true};save();
 for(let i=0;i<cases.length;i++){
  const c=cases[i],dir=path.join(out,String(i));fs.mkdirSync(dir);
  const input=source.replace('export default {',()=>`function $controlProbe$(${c.params}) {${c.body}}\nexport default {`),inputFile=path.join(dir,'input.mjs');fs.writeFileSync(inputFile,input);report.inputs.push(identity(inputFile));
  let baseline,lift,error;try{baseline=V.transform(input,{version:5});lift=L.transform(input,{families:['$controlProbe$']});}catch(e){error={name:e.name,message:e.message};}
  const row={name:c.name,expect:c.expect,input:identity(inputFile),prerequisiteAccepted:!!baseline,accepted:!!lift,error};report.rows.push(row);save();
  if(!lift){row.pass=c.expect!=='equivalent';save();continue;}
  const apis=[];for(const [name,body]of [['baseline',baseline.source],['candidate',lift.source]]){const file=path.join(dir,name+'.mjs');fs.writeFileSync(file,body+'\nexport const control=(...args)=>run_loop($controlProbe$(...args));\n');report.inputs.push(identity(file));apis.push((await import(pathToFileURL(file))).control);}
  const observations=apis.map(api=>observe(()=>c.run(api)));row.observations=observations;row.equivalent=JSON.stringify(observations[0])===JSON.stringify(observations[1]);row.captures=lift.report.workers.map(w=>w.captures.map(c=>c.name));row.pass=c.expect!=='refuse'&&row.equivalent;save();
 }
 report.inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;report.pass=report.rows.every(r=>r.pass);
 if(!report.pass)process.exitCode=1;
}catch(e){report.error=e.stack;process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,failures:report.rows.filter(r=>!r.pass).map(r=>({name:r.name,accepted:r.accepted,equivalent:r.equivalent,error:r.error})),error:report.error}));
