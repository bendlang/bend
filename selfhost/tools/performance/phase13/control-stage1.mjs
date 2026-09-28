// Independent differential controls of the actual shared v5 implementation.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';

const [outArg]=process.argv.slice(2),out=path.resolve(outArg);
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
const root=path.resolve(import.meta.dirname,'../../..');
const helper=path.join(root,'build/phase12/integrated-03/snapshot/tools/development/equality.mjs');
const origins=[helper,...['rewriter-structure.mjs','rewriter-v5.mjs'].map(name=>path.join(import.meta.dirname,name))];
const consumed=[];
for(const file of origins){const target=path.join(out,path.relative(root,file));fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(file,target);consumed.push(target);}
const old=await import(pathToFileURL(consumed[0]));
const actual=await import(pathToFileURL(consumed[2]));
const S=await import(pathToFileURL(consumed[1]));
const attempt=await verifyAttempt(path.join(root,'build/phase12/integrated-03'));
const source=fs.readFileSync(attempt.checkedApi.file,'utf8');
const inputs=[import.meta.filename,process.execPath,...origins,...consumed,attempt.checkedApi.file,path.join(root,'build/phase12/integrated-03/attempt.json')].map(identity);
const report={kind:'phase13-independent-stage1-controls',complete:false,pass:false,inputs,rows:[],structuralRows:[],scope:'Actual old/new transformation acceptance and exact output/statistics on frozen checked input mutations. Refusal message wording is recorded but not required equal. Source-range views are not a full JS parser or lifting proof.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const add=body=>source.replace('export default {',()=>body+'\nexport default {');
const fixture=(name,body,accept=true)=>({name,text:add(body),accept});
const cases=[
 {name:'unchanged actual checked compiler',text:source,accept:true},
 fixture('plain function','function $controlPlain$(x) { return x; }'),
 fixture('nested choices','function $controlNested$(a,b) { return $kc$(a,run_clo((u)=>{return $f_choose$(b,run_clo((v)=>{return 1;}),run_clo((w)=>{return 2;}));}),run_clo((z)=>{return 3;})); }'),
 fixture('dynamic thunk skipping','function $controlDynamic$(a,y,n) { return $kc$(a,y,n); }'),
 fixture('extra arrow parentheses remain skipped','function $controlParens$(a) { return $kc$(a,run_clo(((u)=>{return 1;})),run_clo(((v)=>{return 2;}))); }'),
 fixture('nonleaf branch declarations','function $controlDecl$(a,x) { return $kc$(a,run_clo((u)=>{const y=x+1;return y;}),run_clo((v)=>{return x;})); }'),
 fixture('quoted dependencies and delimiters','function $controlString$() { return {name:"$kc$", value:"[ { ( ; , ) } ]", other:"run_tail"}; }'),
 fixture('nested arrow scopes','function $controlScopes$(a,x) { return $kc$(a,run_clo((u)=>{const local=(x)=>x;return (y)=>local(y)+x;}),run_clo((v)=>{return (x)=>x;})); }'),
 fixture('zero-arity terminal generated call','function $controlZero$() { return 17; }\nfunction $controlCall$(a) { return $kc$(a,run_clo((u)=>{return $controlZero$();}),run_clo((v)=>{return $controlZero$();})); }'),
 fixture('commas in nested call arguments','function $controlArgs$(a,x,y) { return $kc$(a,run_clo((u)=>{return $String$eq$((x),({field:y,more:[1,2]}));}),run_clo((v)=>{return false;})); }'),
 fixture('mutable capture is allowed in v5 unchanged boundary','function $controlMutable$(x) { const jump=$kc$(true,run_clo((u)=>{return x;}),run_clo((v)=>{return 0;})); x=2; return jump; }'),
 fixture('later const allowed in v5 unchanged boundary','function $controlTdz$() { const jump=$kc$(true,run_clo((u)=>{return x;}),run_clo((v)=>{return 0;})); const x=17; return jump; }'),
 fixture('protected parameter','function $controlBad$($kc$) { return 0; }',false),
 fixture('protected destructuring','function $controlBad$() { const {$kc$}=record; return 0; }',false),
 fixture('protected destructuring assignment','function $controlBad$() { ({value:$kc$}=record); return 0; }',false),
 fixture('protected rebinding','function $controlBad$() { $nt_choose$=replacement; return 0; }',false),
 fixture('protected update','function $controlBad$() { $f_choose$++; return 0; }',false),
 fixture('protected member call','function $controlBad$() { return record.$kc$(true,run_clo((u)=>1),run_clo((v)=>2)); }',false),
 fixture('protected optional member call','function $controlBad$() { return record?.$nt_choose$(true,run_clo((u)=>1),run_clo((v)=>2)); }',false),
 fixture('nested generated function','function $controlBad$() { function $nested$() { return 0; } return 0; }',false),
 fixture('this lexical dependency','function $controlBad$() { return this.value; }',false),
 fixture('arguments lexical dependency','function $controlBad$() { return arguments[0]; }',false),
 fixture('new target dependency','function $controlBad$() { return new.target; }',false),
 fixture('try finally dependency','function $controlBad$() { try { return 0; } finally {} }',false),
 fixture('template literal refused','function $controlBad$() { return `text`; }',false),
 fixture('comment refused','function $controlBad$() { /* comment */ return 0; }',false),
 {name:'runtime drift',text:source.replace('function run_tail(f, x) {','function run_tail(f, x) {\nvoid 0;'),accept:false},
 {name:'choice body drift',text:source.replace('function $nt_choose$(_b_0, _yes_0, _no_0) {','function $nt_choose$(_b_0, _yes_0, _no_0) {\nvoid 0;'),accept:false},
 {name:'unbalanced source',text:source.slice(0,-3),accept:false},
 {name:'unexpected trailing top-level expression',text:source+'\n0;',accept:false},
];
try {
 for(let i=0;i<cases.length;i++){
  const c=cases[i],file=path.join(out,'input-'+i+'.mjs');fs.writeFileSync(file,c.text);inputs.push(identity(file));
  const run=fn=>{try{return {ok:true,output:fn()};}catch(e){return {ok:false,error:{name:e.name,message:e.message}};}};
  const expected=run(()=>old.transformEquality(c.text,5)),observed=run(()=>actual.transform(c.text,{version:5}));
  const row={name:c.name,input:identity(file),expectedAccept:c.accept,baselineAccept:expected.ok,candidateAccept:observed.ok,baselineError:expected.error,candidateError:observed.error};report.rows.push(row);save();
  assert.equal(expected.ok,c.accept,'Baseline fixture expectation: '+c.name);assert.equal(observed.ok,expected.ok,c.name);
  if(expected.ok){assert.equal(observed.output.source,expected.output.source,c.name);assert.equal(JSON.stringify(observed.output.stats),JSON.stringify(expected.output.stats),c.name);row.sourceAndStatsExact=true;row.outputSha256=S.sha(observed.output.source);row.stats=observed.output.stats;}
  save();
 }
 const view=S.moduleView(source),empty=view.program(new Map(),()=>{throw Error('unexpected replacement');});assert.equal(empty,source);report.structuralRows.push({name:'empty rendering exactly preserves complete module',pass:true});
 for(const f of view.functions.values())assert.equal(f.source,source.slice(view.ts[f.first].start,view.ts[f.end].end));report.structuralRows.push({name:'all top-level source ranges agree with token endpoints',count:view.functions.size,pass:true});
 for(const version of [1,2,3,4,5]){const options={version,extra:true};assert.throws(()=>actual.transform(source,options));}report.structuralRows.push({name:'unknown option keys refused',count:5,pass:true});
 for(const version of [0,6,'5',null])assert.throws(()=>actual.transform(source,{version}));report.structuralRows.push({name:'unknown version values refused',count:4,pass:true});
 inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;report.inputsVerified=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:report.rows.length,structural:report.structuralRows.length,error:report.error}));
