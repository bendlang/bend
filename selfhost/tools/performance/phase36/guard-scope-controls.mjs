// Scope-specific checks. Public differential controls live in derived controls.mjs.
// Fault injection below tests emitted cleanup; it is never a timed variant.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [baseArg,outArg]=process.argv.slice(2);assert(baseArg&&outArg,'usage: guard-scope-controls.mjs DERIVED_DIR NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);assert(!fs.existsSync(out));fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const manifestFile=path.join(base,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));assert.equal(manifest.kind,'phase36-scoped-guard-prototype');assert.equal(manifest.complete,true);
const report={kind:'phase36-scoped-guard-scope-controls',complete:false,pass:false,inputs:[import.meta.filename,manifestFile].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const parserSource=process.binding('natives')['internal/deps/acorn/acorn/dist/acorn'];
const parserModule={exports:{}};new Function('module','exports',parserSource)(parserModule,parserModule.exports);
const parse=s=>parserModule.exports.parse(s,{ecmaVersion:'latest',sourceType:'module'});
function walk(n,f){if(!n||typeof n!=='object')return;f(n);for(const v of Object.values(n)){
 if(Array.isArray(v)){for(const x of v)walk(x,f);}else if(v&&typeof v==='object')walk(v,f);
}}
try{
 const files=['original','partial'].map(variant=>{const row=manifest.modules.find(x=>x.variant===variant);assert.deepEqual(identity(row.path),{path:row.path,sha256:row.sha256});report.inputs.push(identity(row.path));return row.path;});
 const [original,candidate]=await Promise.all(files.map(file=>import(pathToFileURL(file))));
 const checkInactive=()=>assert.equal(candidate.guardProofState().active,false,'proof leaked to external caller');
 for(const args of [[1n,0,0,16384,40,32],[2n,1,0,16384,40,32],[1n,4294967295,0,16384,40,32]]){
  const before=candidate.guardProofState(),expected=original.default.colf(...args),value=candidate.default.colf(...args),after=candidate.guardProofState();
  assert.equal(value,expected);assert(after.opened>before.opened);assert(after.hostReused>before.hostReused,'live nested host guard must reuse proof');
  assert(after.localReused>before.localReused,'live nested dependency guard must reuse proof');assert.equal(after.opened,after.closed);checkInactive();
  report.observations.push({kind:'live-colf',args:args.map(x=>typeof x==='bigint'?x+'n':x),expected,value,before,after});
 }
 // Public calls following a successful proof must inspect dependencies anew.
 for(const name of ['nearest','nearest.t','pixel']){
  const observe=m=>{const f=m.G[name],code=f.code;let calls=0;f.code=function(a){calls++;return Reflect.apply(code,this,[a]);};
   try{return{value:m.default.colf(1n,0,0,16384,40,32),calls};}finally{f.code=code;}};
  const a=observe(original),b=observe(candidate);assert.deepEqual(b,a);assert(a.calls>0,name+' hook must execute');checkInactive();
  report.observations.push({kind:'post-success-mutation',name,expected:a,actual:b});
 }
 // Inject only at the already admitted colf branch to test the actual emitted
 // finally on throw, bounce and delayed field exit, not a mirrored test wrapper.
 let injected=fs.readFileSync(files[1],'utf8'),tree=parse(injected),colf;
 for(const s of tree.body){const n=s.type==='ExpressionStatement'?s.expression:null;
  if(n?.type==='AssignmentExpression'&&n.left.type==='MemberExpression'&&n.left.object.name==='G'&&n.left.property.value==='colf')colf=n;}
 assert(colf);const tries=[];walk(colf,n=>{if(n.type==='TryStatement'&&injected.slice(n.finalizer.start,n.finalizer.end).includes('regionProofClose($previousProof)'))tries.push(n);});assert.equal(tries.length,1);
 const code=`if($guardFault==='throw')throw Error('guard injected sentinel');
 if($guardFault==='bounce')return {bounce:true,f:fn(0,()=>{if(regionProof!==null)throw Error('bounce inherited proof');return 91;}),args:[]};
 if($guardFault==='build')return build('Phase36GuardBox',[()=>{if(regionProof!==null)throw Error('build inherited proof');return 92;}]);
 if($guardFault==='coverage'){if(!regionProofCovers(['nearest'])||regionProofCovers(['IO.print']))throw Error('wrong proof coverage');return 93;}
 `;
 const at=tries[0].block.start+1;injected=injected.slice(0,at)+code+injected.slice(at);
 injected+='\nlet $guardFault="";export function guardSetFault(mode){$guardFault=mode;}\n';parse(injected);
 const file=path.join(out,'fault-injection.mjs');fs.writeFileSync(file,injected,{flag:'wx'});report.faultModule={parent:identity(files[1]),output:identity(file),scope:'Diagnostic injection only after the actual admitted colf try begins; not a compiler or timing artifact.'};
 const fault=await import(pathToFileURL(file));
 for(const mode of ['throw','bounce','build','coverage']){fault.guardSetFault(mode);let value,error;
  try{value=fault.default.colf(1n,0,0,16384,40,32);}catch(e){error={name:e.name,message:e.message};}
  if(mode==='throw')assert.deepEqual(error,{name:'Error',message:'guard injected sentinel'});else{assert.equal(error,undefined);assert.deepEqual(value,mode==='bounce'?91:mode==='coverage'?93:{$:'Phase36GuardBox',a:[92]});}
  const state=fault.guardProofState();assert.equal(state.active,false);assert.equal(state.opened,state.closed);report.observations.push({kind:'diagnostic-finally',mode,value,error,state});
 }
 fault.guardSetFault('');assert.equal(fault.default.colf(1n,0,0,16384,40,32),original.default.colf(1n,0,0,16384,40,32));assert.equal(fault.guardProofState().active,false);
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
