import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {compareReports} from './frontend-layout-compare.mjs';
const out=path.resolve(process.argv[2]);fs.mkdirSync(out);
const sha=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const identity=file=>({file,sha256:sha(fs.readFileSync(file))});
const write=(name,value)=>{const file=path.join(out,name);fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');return identity(file);};
const oldManifest={upstream:'pin',modules:['a.bend'],targetVersion:'2'},newManifest={...oldManifest,modules:['a.bend','contextual.bend']};
const a=write('before-manifest.json',oldManifest),b=write('after-manifest.json',newManifest);
function report(artifact){return {schemaVersion:1,finished:'closed',changedInputs:[],workers:[{errors:[]}],options:{upstream:'/fixed/pin'},identity:{artifacts:{compilerManifest:artifact},finalArtifactHashes:{compilerManifest:artifact.sha256},adapterChangedDuringRun:false,changedArtifacts:[]},inventory:{revision:'pin',tests:[{id:'one',file:'/fixed/pin/one.bend',sha256:'fixture',expected:'42n',negative:false,main:true}]},results:[{id:'one',lane:'parse',status:'pass',negative:false,result:{status:'ok',phase:'parse'}}]};}
const before=report(a),after=report(b),migration={kind:'explicit-compiler-module-layout-migration',before:{sha256:a.sha256,modules:oldManifest.modules},after:{sha256:b.sha256,modules:newManifest.modules},expectedNonModules:{upstream:'pin',targetVersion:'2'}};
const rows=[],options={strictPaths:true,moduleLayoutMigration:migration};
function check(name,fn){try{fn();rows.push({name,pass:true});}catch(error){rows.push({name,pass:false,error:String(error.stack)});}}
function refuse(name,mutate,pattern){check(name,()=>{const x=structuredClone(before),y=structuredClone(after),m=structuredClone(migration);mutate(x,y,m);assert.throws(()=>compareReports(x,y,{strictPaths:true,moduleLayoutMigration:m}),pattern);});}
check('explicit migration accepted with exact observations',()=>{const r=compareReports(before,after,options);assert.equal(r.sameObservedBehavior,true);assert.deepEqual(r.moduleLayout.added,['contextual.bend']);});
check('unapproved migration still refuses',()=>assert.throws(()=>compareReports(before,after,{strictPaths:true}),/Different target manifests/));
check('unchanged manifest strict route retained',()=>assert.equal(compareReports(before,before,{strictPaths:true}).sameObservedBehavior,true));
check('migration cannot normalize paths',()=>assert.throws(()=>compareReports(before,after,{moduleLayoutMigration:migration}),/requires strict/));
refuse('schema drift',(_,y)=>y.schemaVersion=2,/schemas/);
refuse('upstream pin drift',(_,y)=>y.inventory.revision='other',/upstream pins/);
refuse('upstream path drift',(_,y)=>y.options.upstream='/other',/upstream paths/);
refuse('fixture path drift',(_,y)=>y.inventory.tests[0].file='/different',/paths or oracles/);
refuse('fixture oracle drift',(_,y)=>y.inventory.tests[0].expected='wrong',/paths or oracles/);
refuse('fixture content hash drift',(_,y)=>y.inventory.tests[0].sha256='different',/fixture inventory/);
refuse('manifest recorded hash drift',(_,y)=>y.identity.artifacts.compilerManifest.sha256='wrong',/manifest identity/);
refuse('manifest final hash drift',(_,y)=>y.identity.finalArtifactHashes.compilerManifest='wrong',/manifest identity/);
refuse('descriptor manifest hash drift',(_,y,m)=>m.after.sha256='wrong',/Unapproved target manifest/);
refuse('ordered module drift',(_,y,m)=>m.after.modules.reverse(),/Unapproved module layout/);
refuse('duplicate manifest identity disagreement',(_,y)=>{y.identity.artifacts['harness/compilerManifest']=a;y.identity.finalArtifactHashes['harness/compilerManifest']=a.sha256;},/Unapproved target manifest/);
refuse('changed inputs',(_,y)=>y.changedInputs=['fixture'],/changed report/);
refuse('changed adapter',(_,y)=>y.identity.adapterChangedDuringRun=true,/changed report/);
refuse('worker failure',(_,y)=>y.workers[0].errors=['failure'],/changed report/);
refuse('unfinished report',(_,y)=>delete y.finished,/changed report/);
for(const key of ['targetVersion','upstream','extraTargetField']){
 check('actual '+key+' drift refused',()=>{const changed={...newManifest,[key]:'changed'},artifact=write('changed-'+key+'.json',changed),r=report(artifact),m=structuredClone(migration);m.after.sha256=artifact.sha256;assert.throws(()=>compareReports(before,r,{strictPaths:true,moduleLayoutMigration:m}),/non-module manifest/);});
}
check('actual manifest bytes drift refused',()=>{const file=path.join(out,'wrong-bytes.json');fs.writeFileSync(file,'{}');const r=report({...b,file});assert.throws(()=>compareReports(before,r,options),/manifest bytes/);});
check('diagnostic difference remains visible',()=>{const r=structuredClone(after);r.results[0].result.diagnostic='different';assert.equal(compareReports(before,r,options).changes.length,1);});
check('missing observation remains visible',()=>{const r=structuredClone(after);r.results=[];assert.equal(compareReports(before,r,options).missing.length,1);});
const result={kind:'phase22-module-layout-comparator-controls',complete:true,pass:rows.every(x=>x.pass),scope:'Synthetic audit-policy controls only; no compiler execution.',rows,inputs:[identity(import.meta.filename),identity(path.join(import.meta.dirname,'frontend-layout-compare.mjs'))]};
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify({pass:result.pass,rows:rows.length,failed:rows.filter(x=>!x.pass)}));if(!result.pass)process.exitCode=1;
