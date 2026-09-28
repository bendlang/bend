import assert from 'node:assert/strict';
import test from 'node:test';
import {compareReports} from '../../tools/conformance/compare-artifacts.mjs';

const fixture={id:'case',sha256:'source',file:'/upstream/tests/case.bend',expected:'SOME PROOFS FAIL\nError: wrong\nexit 1',negative:true,failureKind:'validation',main:false};
const row={id:'case',lane:'check',negative:true,failureKind:'validation',status:'pass',evidence:'checker-rejection',result:{status:'error',phase:'check',checked:true,typeAccepted:false,proofTrust:'not-assessed',kernelChecked:false,exitCode:1,diagnostic:'SOME PROOFS FAIL\nError: /upstream/tests/case.bend'}};
const report=()=>({inventory:{revision:'pin',tests:[structuredClone(fixture)]},results:[structuredClone(row)],options:{upstream:'/upstream'},finished:'now',changedInputs:[],workers:[{errors:[]}],identity:{artifacts:{'harness/compilerManifest':{sha256:'manifest'}},finalArtifactHashes:{'harness/compilerManifest':'manifest'},adapterChangedDuringRun:false,changedArtifacts:[]}});

test('strict comparison retains all acceptance and trust differences',()=>{
  const before=report();assert.equal(compareReports(before,report(),{strictPaths:true}).sameObservedBehavior,true);
  for(const change of [{typeAccepted:true},{proofTrust:'failed'},{kernelChecked:true},{unsafeDefinitions:['boom']},{diagnostic:'SOME PROOFS FAIL\nError: other'},{exitCode:0}]){
    const after=report();Object.assign(after.results[0].result,change);
    assert.equal(compareReports(before,after,{strictPaths:true}).changes.length,1);
  }
});

test('legacy path normalization is retained only outside strict mode',()=>{
  const before=report(),after=report();after.options.upstream='/moved';after.results[0].result.diagnostic=after.results[0].result.diagnostic.replace('/upstream','/moved');
  assert.equal(compareReports(before,after).sameObservedBehavior,true);
  assert.throws(()=>compareReports(before,after,{strictPaths:true}),/Different upstream paths/);
});

test('strict mode binds fixture oracle, target manifest, and unchanged report identities',()=>{
  for(const mutate of [
    r=>r.inventory.tests[0].expected='different',r=>r.inventory.tests[0].file='/elsewhere',
    r=>{r.identity.artifacts['harness/compilerManifest'].sha256='other';r.identity.finalArtifactHashes['harness/compilerManifest']='other';},
    r=>r.identity.finalArtifactHashes['harness/compilerManifest']='changed',r=>r.changedInputs.push('source'),
    r=>r.identity.changedArtifacts.push('compiler'),r=>r.workers[0].errors.push('crashed'),r=>delete r.finished,
  ]){const after=report();mutate(after);assert.throws(()=>compareReports(report(),after,{strictPaths:true}));}
  const early=report();early.identity.artifacts.compilerManifest=early.identity.artifacts['harness/compilerManifest'];early.identity.finalArtifactHashes.compilerManifest='manifest';delete early.identity.artifacts['harness/compilerManifest'];delete early.identity.finalArtifactHashes['harness/compilerManifest'];
  assert.equal(compareReports(early,report(),{strictPaths:true}).sameObservedBehavior,true);
});

test('duplicates cannot vanish through map replacement and missing rows stay visible',()=>{
  const duplicate=report();duplicate.results.push(structuredClone(row));assert.throws(()=>compareReports(report(),duplicate),/Duplicate probe/);
  const sameFixture=report();sameFixture.inventory.tests.push(structuredClone(fixture));assert.throws(()=>compareReports(report(),sameFixture),/Duplicate fixture/);
  const missing=report();missing.results=[];const result=compareReports(report(),missing);assert.equal(result.sameObservedBehavior,false);assert.equal(result.missing.length,1);
});
