// Counterfactual branch counts; no performance claim comes from these counters.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';
import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [baseArg,outArg]=process.argv.slice(2);assert(baseArg&&outArg,'usage: guard-exact-controls.mjs EXACT_ABLATION NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({path:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const mf=path.join(base,'derive.json'),meta=JSON.parse(fs.readFileSync(mf));assert.equal(meta.complete,true);assert.equal(meta.acquisitionKind,'phase36-exact-entry-saved-output-ablation');
const report={kind:'phase36-exact-entry-branch-controls',complete:false,pass:false,inputs:[import.meta.filename,mf].map(identity),observations:[]};fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try{
 const modules=[];for(const role of ['original','partial']){const row=meta.modules.find(r=>r.variant===role);assert.equal(identity(row.path).sha256,row.sha256);report.inputs.push(identity(row.path));modules.push(await import(pathToFileURL(row.path)));}
 function delta(a,b){return Object.fromEntries(Object.keys(a).map(k=>[k,b[k]-a[k]]));}
 for(const args of [[1n,9384,32,16384,40,32],[2n,9384,32,16384,40,32],[3n,0,0,16384,40,32]]){
  const rows=modules.map(m=>{const before=m.guardExactState(),value=m.default.colf(...args),after=m.guardExactState();assert.equal(m.guardProofState().active,false);return{value,delta:delta(before,after)};});
  assert.deepEqual(rows[1].value,rows[0].value);assert.equal(rows[0].delta.skipped,0);assert(rows[0].delta.inside>0,'original must actually reflect under active proof');
  assert.equal(rows[1].delta.skipped,rows[1].delta.inside);assert.equal(rows[1].delta.inside,rows[0].delta.inside);assert.equal(rows[1].delta.members,rows[0].delta.members);assert.equal(rows[1].delta.calls,rows[0].delta.calls);
  report.observations.push({kind:'inside-proof',args:args.map(x=>typeof x==='bigint'?x+'n':x),rows});
 }
 const args=[2n,0,0,0,0,0,1,1e9,9,1e9,9,false];
 const rows=modules.map(m=>{const before=m.guardExactState(),value=m.default.nearest(...args),after=m.guardExactState(),d=delta(before,after);assert.equal(d.inside,0);assert.equal(d.skipped,0);assert(d.members>0,'public exact entry must execute');assert.equal(m.guardProofState().active,false);return{value,delta:d};});
 assert.deepEqual(rows[1],rows[0]);report.observations.push({kind:'public-exact-entry',rows});
 // A publicly saved exact wrapper can be changed between invocations; neither
 // that wrapper nor its getter/reentrant callback may inherit a private proof.
 for(const mode of ['own-call','code-prototype','call-getter-reentry']){
  const observations=modules.map(m=>{const partial=m.default.nearest(...args.slice(0,-1)),code=partial.code,proto=Object.getPrototypeOf(code),own=Object.getOwnPropertyDescriptor(code,'call'),events=[];let value,error;
   const invoke=function(env,a){events.push('call');assert.equal(m.guardProofState().active,false);return Reflect.apply(code,env,[a]);};
   try{if(mode==='own-call')Object.defineProperty(code,'call',{value:invoke,writable:true,configurable:true});
    else if(mode==='code-prototype')Object.setPrototypeOf(code,Object.create(proto,{call:{value:invoke,configurable:true}}));
    else Object.defineProperty(code,'call',{configurable:true,get(){events.push('get-call');assert.equal(m.guardProofState().active,false);events.push(['nested',m.default.colf(1n,9384,32,16384,40,32)]);assert.equal(m.guardProofState().active,false);return invoke;}});
    value=m.call(partial,[false]);
   }catch(e){error={name:e.name,message:e.message};}
   finally{Object.setPrototypeOf(code,proto);if(own)Object.defineProperty(code,'call',own);else delete code.call;}
   assert(events.length>0,'public mutation must be observed');assert.equal(error,undefined);assert.equal(m.guardProofState().active,false);return{value,error,events};
  });assert.deepEqual(observations[1],observations[0],mode);report.observations.push({kind:'public-mutated-exact-wrapper',mode,observations});
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
