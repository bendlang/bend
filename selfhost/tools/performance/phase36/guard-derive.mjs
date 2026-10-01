// Frozen saved-output scoped proof discriminator. Does not compile or time code.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import{createHash}from'node:crypto';
const [inputArg,outArg]=process.argv.slice(2);
assert(inputArg&&outArg,'usage: guard-derive.mjs PHASE35_RAYTRACE.mjs NEW_OUT');
const input=fs.realpathSync(inputArg),out=path.resolve(outArg);assert(!fs.existsSync(out));
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const source=fs.readFileSync(input,'utf8');
assert.equal(hash(source),'d6b3abd23fddec72c3756af4b1ae531483758b8bc7c25c412cd0e7e2264aa197');
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const parse=s=>acorn.parse(s,{ecmaVersion:'latest',sourceType:'module'}),tree=parse(source);
const take=n=>source.slice(n.start,n.end);
function walk(n,f){if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){
 if(Array.isArray(v)){for(const x of v)walk(x,f);}else if(v&&typeof v==='object')walk(v,f);
}}
const assignments=new Map();
for(const s of tree.body){const n=s.type==='ExpressionStatement'?s.expression:null;
 if(n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&typeof n.left.property.value==='string')assignments.set(n.left.property.value,n);}
const roots=['rowf','colf'],plans=[];
for(const name of roots){const def=assignments.get(name),guards=[],branches=[];assert(def);
 walk(def,n=>{if(n.type==='VariableDeclarator'&&n.id.name==='$guards')guards.push(n.init);
  if(n.type==='IfStatement'&&take(n.test).startsWith('$entered&&regionHostGuard()&&')&&take(n.consequent).includes('/* private scalar tree */'))branches.push(n.consequent);});
 assert.equal(guards.length,1);assert.equal(branches.length,1);
 const names=guards[0].elements.map(n=>{assert.equal(n.type,'Literal');assert.equal(typeof n.value,'string');return n.value;});
 assert(names.includes(name)&&names.includes('nearest')&&names.includes('nearest.t'));
 plans.push({name,names,body:branches[0]});
}
for(const name of plans[1].names)assert(plans[0].names.includes(name),'row proof must cover col proof');
const runtimeFile=path.join(import.meta.dirname,'guard-runtime.inc.mjs');
const runtime=fs.readFileSync(runtimeFile,'utf8');
function change(text,old,next){assert.equal(text.split(old).length,2,'one replacement: '+old);return text.replace(old,next);}
function derive(diagnostic){let text=source;
 for(const {name,body}of [...plans].sort((a,b)=>b.body.start-a.body.start)){
  const original=source.slice(body.start+1,body.end-1);
  const wrapped=`{const $previousProof=regionProofOpen($guards);${diagnostic?'$proofOpened++;':''}try{${name==='colf'&&diagnostic?'$colEntries++;':''}${original}}finally{regionProofClose($previousProof);${diagnostic?'$proofClosed++;':''}}}`;
  text=text.slice(0,body.start)+wrapped+text.slice(body.end);
 }
 text=change(text,'function regionHostGuard(){','function regionHostGuard(){\n  if(regionProof!==null){'+(diagnostic?'$proofHostReused++;':'')+'return true;}'+(diagnostic?'$proofHostFull++;':''));
 text=change(text,'function localGuard(names){','function localGuard(names){\n  if(regionProofCovers(names)){'+(diagnostic?'$proofLocalReused++;':'')+'return true;}');
 text=change(text,'function scalarGuard(names){','function scalarGuard(names){\n  if(regionProofCovers(names)){'+(diagnostic?'$proofScalarReused++;':'')+'return true;}');
 text+='\n'+runtime;
 if(diagnostic)text+=`\nlet $proofOpened=0,$proofClosed=0,$proofHostReused=0,$proofHostFull=0,$proofLocalReused=0,$proofScalarReused=0;\nexport function guardProofState(){return {active:regionProof!==null,opened:$proofOpened,closed:$proofClosed,hostReused:$proofHostReused,hostFull:$proofHostFull,localReused:$proofLocalReused,scalarReused:$proofScalarReused};}\n`;
 return text;
}
const common=`\nlet $colEntries=0;export function colfEntryCount(){return $colEntries;}\nexport function colfCandidatePoint(depth,seed,width=0){return call(get(G,'colf'),[BigInt(depth),seed>>>0,0,width>>>0,40,32]);}\n`;
const noProof=`\nexport function guardProofState(){return {active:false,opened:0,closed:0,hostReused:0,hostFull:0,localReused:0,scalarReused:0};}\n`;
const variants={original:source+common+noProof,baseline:source+common+noProof,partial:derive(true)+common,candidate:derive(false)};
const controlFile=path.resolve(import.meta.dirname,'../phase35/region-colf-controls.mjs');
let controls=fs.readFileSync(controlFile,'utf8');
controls=controls.replaceAll('phase35-private-partial-colf-prototype','phase36-scoped-guard-prototype').replaceAll('phase35-private-partial-colf-controls','phase36-scoped-guard-colf-controls').replaceAll('/* private partial colf prototype */','/* private scalar tree */');
controls=change(controls,'finally{restore();}','finally{restore();assert.equal(m.guardProofState().active,false,"proof leaked after public observation");}');
fs.mkdirSync(out,{recursive:false});
const report={kind:'phase36-scoped-guard-prototype',complete:false,checked:false,certified:false,node:process.version,
 inputs:[input,import.meta.filename,runtimeFile,controlFile].map(identity),parserSha256:hash(parserSource),dependencies:plans[1].names,
 roots:plans.map(({name,names})=>({name,names})),modules:[],scope:'Only frozen rowf/colf admitted scalar tree bodies grant scoped covering proofs. Diagnostic variants have counters; candidate is clean. Existing colf control assertions retained, with active-proof leak assertion. No execution by producer.'};
for(const [variant,text]of Object.entries(variants)){parse(text);const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});}
fs.writeFileSync(path.join(out,'controls.mjs'),controls,{flag:'wx'});report.controls=identity(path.join(out,'controls.mjs'));
for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=true;
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));fs.copyFileSync(runtimeFile,path.join(out,'consumed-runtime.inc.mjs'));
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:true,checked:false,roots:report.roots,modules:report.modules,controls:report.controls}));
