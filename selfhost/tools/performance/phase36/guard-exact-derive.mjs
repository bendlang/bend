// Saved-output ablation only. Input is an already verified checked-ray cohort.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{createHash}from'node:crypto';
const [cohortArg,outArg,overflowArg]=process.argv.slice(2);
assert(cohortArg&&outArg,'usage: guard-exact-derive.mjs CHECKED_GUARD_COHORT NEW_OUT [CHECKED_OVERFLOW_COHORT]');
const cohort=path.resolve(cohortArg),out=path.resolve(outArg);assert(!fs.existsSync(out));
const hash=x=>createHash('sha256').update(x).digest('hex');const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const inputFile=path.join(cohort,'derive.json'),parent=JSON.parse(fs.readFileSync(inputFile));
assert.equal(parent.acquisitionKind,'phase36-checked-scoped-guard-cohort');assert.equal(parent.complete,true);assert.equal(parent.checked,true);
const inputs=[identity(import.meta.filename),identity(inputFile)];
for(const row of parent.inputs){assert.deepEqual(identity(row.path),row);inputs.push(row);}
for(const row of parent.modules){assert.equal(identity(row.path).sha256,row.sha256);inputs.push(identity(row.path));}
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];const parserModule={exports:{}};
new Function('module','exports',parserSource)(parserModule,parserModule.exports);const acorn=parserModule.exports;assert.equal(acorn.version,'8.16.0');
const parse=s=>acorn.parse(s,{ecmaVersion:'latest',sourceType:'module'});
const old=`  if(!hasExactCodes||!exactCodes.has(code)||Object.getPrototypeOf(code)!==exactPrototype||
      Object.getOwnPropertyDescriptor(code,'call'))return code.call(f.env,all);
  const callProperty=Object.getOwnPropertyDescriptor(exactPrototype,'call');
  if(!callProperty||!Object.hasOwn(callProperty,'value')||callProperty.value!==exactCall)
    return code.call(f.env,all);`;
const next=`  if(!hasExactCodes||!exactCodes.has(code))return code.call(f.env,all);
  if(regionProof===null){
    if(Object.getPrototypeOf(code)!==exactPrototype||Object.getOwnPropertyDescriptor(code,'call'))return code.call(f.env,all);
    const callProperty=Object.getOwnPropertyDescriptor(exactPrototype,'call');
    if(!callProperty||!Object.hasOwn(callProperty,'value')||callProperty.value!==exactCall)return code.call(f.env,all);
  }`;
function change(source,optimize,diagnostic=false){assert.equal(source.split(old).length,2,'one original invokeExact reflection segment required');let replacement=optimize?next:old;
 if(diagnostic){if(optimize)replacement=replacement.replace('  if(regionProof===null){','  $exactMembers++;if(regionProof!==null){$exactInside++;$exactSkipped++;}\n  if(regionProof===null){');
  else replacement=replacement.replace('||Object.getPrototypeOf(code)!==exactPrototype||', '||($exactMembers++,(regionProof!==null&&$exactInside++),Object.getPrototypeOf(code)!==exactPrototype||').replace("Object.getOwnPropertyDescriptor(code,'call'))", "Object.getOwnPropertyDescriptor(code,'call')))");
 }
 let text=source.replace(old,replacement);
 if(diagnostic){assert.equal(text.split('function invokeExact(f,all){').length,2);text=text.replace('function invokeExact(f,all){','function invokeExact(f,all){$exactCalls++;');
  text+='\nlet $exactCalls=0,$exactMembers=0,$exactInside=0,$exactSkipped=0;export function guardExactState(){return {calls:$exactCalls,members:$exactMembers,inside:$exactInside,skipped:$exactSkipped};}\n';}
 parse(text);return text;
}
const clean=fs.readFileSync(parent.modules.find(row=>row.variant==='candidate').path,'utf8');
const diagnostic=fs.readFileSync(parent.modules.find(row=>row.variant==='partial').path,'utf8');
assert(clean.includes('j_tree_scope')===false);assert(clean.includes('regionProofOpen($guards)'));
const variants={original:change(diagnostic,false,true),baseline:change(diagnostic,false,true),partial:change(diagnostic,true,true),candidate:change(clean,true),'timing-baseline':clean};
fs.mkdirSync(out,{recursive:false});const report={kind:'phase36-scoped-guard-prototype',acquisitionKind:'phase36-exact-entry-saved-output-ablation',complete:false,checked:false,certified:false,node:process.version,inputs,
 parent:identity(inputFile),compilers:parent.compilers,roots:parent.roots,dependencies:parent.dependencies,modules:[],parserSha256:hash(parserSource),scope:'Only invokeExact reflection checks inside an already active complete-root proof are skipped. Membership, token entry/finally and every public fallback stay. Clean and diagnostic variants separate. Parent checked output is preserved; ablation is not compiler output.'};
for(const [variant,text]of Object.entries(variants)){const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,text,{flag:'wx'});report.modules.push({variant,...identity(file),bytes:Buffer.byteLength(text)});}
for(const [name,parentRow]of [['controls.mjs',parent.controls],['scope-controls.mjs',parent.scopeControls]]){assert.deepEqual(identity(parentRow.path),parentRow);inputs.push(parentRow);fs.copyFileSync(parentRow.path,path.join(out,name));report[name==='controls.mjs'?'controls':'scopeControls']=identity(path.join(out,name));}
if(overflowArg){const dir=path.resolve(overflowArg),file=path.join(dir,'derive.json'),meta=JSON.parse(fs.readFileSync(file));assert.equal(meta.complete,true);inputs.push(identity(file));
 const target=path.join(out,'overflow');fs.mkdirSync(target);const controlFile=path.join(import.meta.dirname,'guard-overflow-controls-v2.mjs');inputs.push(identity(controlFile));
 const adapted={...meta,kind:'phase36-exact-entry-error-ablation',checked:false,parent:identity(file),variants:{},emissions:{},scope:'Actual checked Bend fixture module with only invokeExact runtime ablation in candidate. Original emission receipts remain parent provenance, not receipts for modified output.'};
 for(const role of ['baseline','candidate']){const row=meta.variants[role],source=row.file??row.path;assert.equal(identity(source).sha256,row.sha256);inputs.push(identity(source));
  if(meta.emissions?.[role]){const r=meta.emissions[role],rf=r.file??r.path;assert.equal(identity(rf).sha256,r.sha256);inputs.push(identity(rf));const emitted=JSON.parse(fs.readFileSync(rf));assert.equal(emitted.complete,true);assert.equal(emitted.observation.checked,true);assert.equal(emitted.output.sha256,row.sha256);if(role==='candidate')assert.equal(emitted.compiler.api.sha256,parent.compilers.candidate.api.sha256);}
  let text=fs.readFileSync(source,'utf8');if(role==='candidate')text=change(text,true);const output=path.join(target,role+'.mjs');fs.writeFileSync(output,text,{flag:'wx'});adapted.variants[role]={file:output,sha256:identity(output).sha256};
 }
 fs.writeFileSync(path.join(target,'derive.json'),JSON.stringify(adapted,null,2)+'\n',{flag:'wx'});
 const controls=fs.readFileSync(controlFile,'utf8').replace('phase36-checked-error-scope-controls','phase36-exact-entry-error-ablation-controls');fs.writeFileSync(path.join(target,'controls.mjs'),controls,{flag:'wx'});report.overflow={manifest:identity(path.join(target,'derive.json')),controls:identity(path.join(target,'controls.mjs'))};
}
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-derive.mjs'));for(const row of inputs)assert.deepEqual(identity(row.path),row);report.complete=true;
fs.writeFileSync(path.join(out,'derive.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:true,checked:false,out,modules:report.modules,controls:report.controls,scopeControls:report.scopeControls,overflow:report.overflow}));
