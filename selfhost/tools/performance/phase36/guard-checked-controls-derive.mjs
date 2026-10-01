// Bind unchanged saved-output guard assertions to real checked compiler output.
// This producer adds diagnostic counters/exports only; it never adds an optimizer.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{createHash}from'node:crypto';
const [baseArg,candidateArg,outArg]=process.argv.slice(2);
assert(baseArg&&candidateArg&&outArg,'usage: guard-checked-controls-derive.mjs BASELINE_RAY.mjs CANDIDATE_RAY.mjs NEW_OUT');
const out=path.resolve(outArg);assert(!fs.existsSync(out));
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const inputs=[identity(import.meta.filename)];
function verify(row){const file=row.file??row.path,actual=identity(file);assert.equal(actual.sha256,row.sha256,'changed input '+file);inputs.push(actual);return actual;}
function checked(file,role){file=fs.realpathSync(file);const receiptFile=file+'.json',receipt=JSON.parse(fs.readFileSync(receiptFile));inputs.push(identity(receiptFile));
 assert.equal(receipt.kind,'bend-program-checked-emission');assert.equal(receipt.complete,true);assert.equal(receipt.observation.checked,true);assert.equal(receipt.observation.typeAccepted,true);assert.equal(receipt.observation.exitCode,0);
 assert.equal(receipt.compiler.kind,'checked-development-attempt');assert.equal(receipt.compiler.upstreamCommit,'018751270e800bc222a93dad7f257083ee53a5f7');
 assert.equal(identity(file).sha256,receipt.output.sha256);inputs.push(identity(file));
 assert.equal(receipt.input.sha256,'4674b2580aceb5f5fe6771ce16c987b97f791b52a9e1305794c435beeebf5837');verify(receipt.input);
 verify(receipt.attempt);const attempt=JSON.parse(fs.readFileSync(receipt.attempt.file??receipt.attempt.path));assert.equal(attempt.kind,'bend-development-attempt');assert.equal(attempt.checked,true);assert.equal(attempt.artifactKind,'derived-b1');
 for(const key of ['api','runtime','base']){verify(receipt.compiler[key]);assert.equal(attempt[key].sha256,receipt.compiler[key].sha256);}
 verify(receipt.compiler.driver);verify(receipt.producer);
 if(role==='baseline')assert.equal(receipt.compiler.api.sha256,'467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82');
 else{assert.notEqual(receipt.compiler.api.sha256,'467bc7dec2751a94cb677c5eb2da22a8fb69ee3522c6e164cb2bfcc147a78d82');
  const frozen=attempt.snapshot.sources.find(row=>(row.frozen.file??row.frozen.path).endsWith('/src/back/js/tree.bend'))?.frozen;assert(frozen,'checked tree emitter source required');verify(frozen);
  const treeSource=fs.readFileSync(frozen.file??frozen.path,'utf8');assert(treeSource.includes('j_pure_valid(j_pure_graph(book, d, JPure{Nil{}, 32768, True{}}))'),'whole-root purity gate required in checked source');
 }
 return {file,text:fs.readFileSync(file,'utf8'),receipt:identity(receiptFile),compiler:receipt.compiler,attempt:receipt.attempt};
}
const baseline=checked(baseArg,'baseline'),candidate=checked(candidateArg,'candidate');
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const parse=s=>acorn.parse(s,{ecmaVersion:'latest',sourceType:'module'}),tree=parse(candidate.text),take=n=>candidate.text.slice(n.start,n.end);
function walk(n,f){if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){
 if(Array.isArray(v)){for(const x of v)walk(x,f);}else if(v&&typeof v==='object')walk(v,f);
}}
const assignments=new Map(),functions=new Map();
for(const s of tree.body){if(s.type==='FunctionDeclaration')functions.set(s.id.name,s);const n=s.type==='ExpressionStatement'?s.expression:null;
 if(n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&typeof n.left.property.value==='string')assignments.set(n.left.property.value,n);}
const roots=[],edits=[];
for(const name of ['rowf','colf']){const def=assignments.get(name);assert(def);const guards=[],branches=[];
 walk(def,n=>{if(n.type==='VariableDeclarator'&&n.id.name==='$guards')guards.push(n.init);
  if(n.type==='IfStatement'&&take(n.test).startsWith('$entered&&regionHostGuard()&&')&&take(n.consequent).includes('/* private scalar tree */'))branches.push(n.consequent);});
 assert.equal(guards.length,1);assert.equal(branches.length,1);const body=branches[0],tries=[];
 walk(body,n=>{if(n.type==='TryStatement'&&take(n.finalizer).includes('regionProofClose($previousProof)'))tries.push(n);});
 assert.equal(tries.length,1,'actual '+name+' proof finally required');assert(take(body).includes('regionProofOpen($guards)'),'actual '+name+' proof open required');
 const names=guards[0].elements.map(n=>{assert.equal(n.type,'Literal');assert.equal(typeof n.value,'string');return n.value;});
 assert(names.includes(name)&&names.includes('nearest')&&names.includes('nearest.t'));
 roots.push({name,names});if(name==='colf')edits.push({start:body.start+1,end:body.start+1,text:'$colEntries++;'});
}
for(const name of roots[1].names)assert(roots[0].names.includes(name),'row proof must cover col proof');
for(const [name,counter]of [['regionProofOpen','$proofOpened'],['regionProofClose','$proofClosed']]){const f=functions.get(name);assert(f);edits.push({start:f.body.start+1,end:f.body.start+1,text:counter+'++;'});}
for(const [name,condition,counter]of [['regionHostGuard','regionProof!==null','$proofHostReused'],['localGuard','regionProofCovers(names)','$proofLocalReused'],['scalarGuard','regionProofCovers(names)','$proofScalarReused']]){
 const f=functions.get(name);assert(f);const first=f.body.body[0];assert.equal(first.type,'IfStatement');assert.equal(take(first.test).replaceAll(' ',''),condition);
 assert.equal(first.consequent.type,'ReturnStatement');assert.equal(first.consequent.argument.value,true);
 edits.push({start:first.consequent.start,end:first.consequent.end,text:'{'+counter+'++;'+take(first.consequent)+'}'});
 if(name==='regionHostGuard')edits.push({start:first.end,end:first.end,text:'$proofHostFull++;'});
}
let diagnostic=candidate.text;for(const e of edits.sort((a,b)=>b.start-a.start||b.end-a.end))diagnostic=diagnostic.slice(0,e.start)+e.text+diagnostic.slice(e.end);
diagnostic+=`\nlet $proofOpened=0,$proofClosed=0,$proofHostReused=0,$proofHostFull=0,$proofLocalReused=0,$proofScalarReused=0;
export function guardProofState(){return {active:regionProof!==null,opened:$proofOpened,closed:$proofClosed,hostReused:$proofHostReused,hostFull:$proofHostFull,localReused:$proofLocalReused,scalarReused:$proofScalarReused};}\n`;
const common=`\nlet $colEntries=0;export function colfEntryCount(){return $colEntries;}\nexport function colfCandidatePoint(depth,seed,width=0){return call(get(G,'colf'),[BigInt(depth),seed>>>0,0,width>>>0,40,32]);}\n`;
const noProof=`\nexport function guardProofState(){return {active:false,opened:0,closed:0,hostReused:0,hostFull:0,localReused:0,scalarReused:0};}\n`;
const colfFile=path.resolve(import.meta.dirname,'../phase35/region-colf-controls.mjs'),scopeFile=path.resolve(import.meta.dirname,'guard-scope-controls-v2.mjs');inputs.push(identity(colfFile),identity(scopeFile));
let controls=fs.readFileSync(colfFile,'utf8').replaceAll('phase35-private-partial-colf-prototype','phase36-scoped-guard-prototype').replaceAll('phase35-private-partial-colf-controls','phase36-checked-scoped-guard-colf-controls').replaceAll('/* private partial colf prototype */','/* private scalar tree */');
assert.equal(controls.split('finally{restore();}').length,2);controls=controls.replace('finally{restore();}','finally{restore();assert.equal(m.guardProofState().active,false,"proof leaked after public observation");}');
const variants={original:baseline.text+common+noProof,baseline:baseline.text+common+noProof,partial:diagnostic+common,candidate:candidate.text};
fs.mkdirSync(out,{recursive:false});const report={kind:'phase36-scoped-guard-prototype',acquisitionKind:'phase36-checked-scoped-guard-cohort',complete:false,checked:true,certified:false,node:process.version,inputs,
 compilers:{baseline:baseline.compiler,candidate:candidate.compiler},checkedEmissions:{baseline:baseline.receipt,candidate:candidate.receipt},parserSha256:hash(parserSource),dependencies:roots[1].names,roots,modules:[],
 scope:'Checked source emissions with exact receipt/API/runtime/Base/source hashes. Only diagnostic counters and exports added; no scoped proof or optimizer synthesized. Stable protocol kind retains unchanged scope/colf assertions. Clean candidate is byte-identical to checked emission.'};
for(const [variant,text]of Object.entries(variants)){parse(text);const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});}
fs.writeFileSync(path.join(out,'controls.mjs'),controls,{flag:'wx'});fs.copyFileSync(scopeFile,path.join(out,'scope-controls.mjs'));fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));
report.controls=identity(path.join(out,'controls.mjs'));report.scopeControls=identity(path.join(out,'scope-controls.mjs'));
assert.equal(identity(path.join(out,'candidate.mjs')).sha256,identity(candidate.file).sha256);
for(const row of inputs)assert.deepEqual(identity(row.path),row);report.complete=true;fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,checked:true,cohort:out,controls:report.controls,scopeControls:report.scopeControls,compilers:report.compilers}));
