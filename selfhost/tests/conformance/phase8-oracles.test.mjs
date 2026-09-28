import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import test from 'node:test';
import {describeFixture,expectation,PIN,PIN_MANIFEST,walk} from '../../tools/conformance/inventory.mjs';
import {selectProbes} from '../../tools/conformance/selection.mjs';
import {judge,rendered} from '../../tools/conformance/judge.mjs';
import {semanticSummary} from '../../tools/conformance/semantic-summary.mjs';

const declaration='ALL PROOFS CHECK\nUse --verdict for mathematical validity.';
const trustText='SOME PROOFS FAIL\nError: 1 def relies on unsafe or foreign code:\n- boom';
const trustFixture={...expectation(trustText+'\nexit 1'),main:false};
const refused={status:'error',phase:'verdict',checked:true,typeAccepted:true,proofTrust:'failed',kernelChecked:false,diagnostic:trustText,exitCode:1};
const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'bend-phase8-oracles-'));
process.on('exit',()=>fs.rmSync(temporary,{recursive:true,force:true}));

test('both new failed-verdict and plain error expectations remain negative',()=>{
  for(const [text,kind] of [[trustText,'proof-trust'],['SOME PROOFS FAIL\nError: wrong type','validation'],['Error: cannot print main','error']]){
    assert.equal(expectation(text).negative,true);assert.equal(expectation(text).failureKind,kind);
  }
  assert.deepEqual(expectation(declaration),{expected:declaration,negative:false,failureKind:null});
  assert.equal(expectation('SOME PROOFS FAILURE').negative,false);
});

test('explicit external expectations use the same failure classification',()=>{
  const file=path.join(temporary,'plain.bend'),selection=path.join(temporary,'selection.json');
  fs.writeFileSync(file,'type T is Data:\n  T{}\n');
  fs.writeFileSync(selection,JSON.stringify([{file,lane:'check',expected:trustText+'\nexit 1'}]));
  const chosen=selectProbes({tests:[]},{selection}).tests[0];
  assert.equal(chosen.negative,true);assert.equal(chosen.failureKind,'proof-trust');
});

test('proof-trust refusal is exact conformance but never checker-rejection evidence',()=>{
  const verdict=judge(trustFixture,'check',refused,{check:true});
  assert.equal(verdict.status,'pass');assert.equal(verdict.evidence,'proof-trust-rejection');
  assert.equal(rendered(refused),trustFixture.expected);
  for(const change of [{phase:'check'},{checked:false},{typeAccepted:false},{proofTrust:'passed'},{exitCode:0},{diagnostic:trustText+' extra'}]){
    assert.equal(judge(trustFixture,'check',{...refused,...change},{check:true}).status,'fail');
  }
  assert.equal(judge(trustFixture,'interpreter',refused,{interpreter:true}).evidence,'proof-trust-rejection');
});

test('explicit type-acceptance oracle admits a proved type acceptance before trust refusal',()=>{
  assert.equal(judge({oracle:'acceptance',accept:true},'check',refused,{check:true}).evidence,'checker-acceptance');
  assert.equal(judge({oracle:'acceptance',accept:true},'check',refused,{check:false}).status,'unsupported');
  assert.equal(judge({oracle:'acceptance',accept:false,rejectPhase:'check'},'check',{...refused,phase:'check'},{check:true}).status,'fail');
  assert.equal(judge({oracle:'acceptance',accept:false,rejectPhase:'verdict'},'check',refused,{check:true}).evidence,'proof-trust-rejection');
});

test('new checker failure framing and exit are mandatory, not stripped',()=>{
  const fixture={...expectation('SOME PROOFS FAIL\nError: bad type\nexit 1'),main:true};
  const rejected={status:'error',phase:'check',checked:true,typeAccepted:false,diagnostic:'SOME PROOFS FAIL\nError: bad type',exitCode:1};
  assert.equal(judge(fixture,'check',rejected,{check:true}).evidence,'checker-rejection');
  for(const change of [{diagnostic:'Error: bad type'},{exitCode:0},{typeAccepted:true}])assert.equal(judge(fixture,'check',{...rejected,...change},{check:true}).status,'fail');
});

test('unsafe executable acceptance retains trust metadata without inventing a rejection',()=>{
  const result={status:'ok',phase:'check',checked:true,typeAccepted:true,proofTrust:'failed',kernelChecked:false,stdout:trustText,exitCode:0};
  assert.equal(judge({negative:false,main:true,expected:'42'},'check',result,{check:true}).evidence,'checker-acceptance');
  assert.equal(judge({negative:false,main:true,expected:'42'},'check',{...result,typeAccepted:false},{check:true}).status,'fail');
});

test('semantic summary separates trust refusals from type rejection and wrong acceptance',()=>{
  const rows=[
    {id:'trust',lane:'check',negative:true,failureKind:'proof-trust',status:'pass',evidence:'proof-trust-rejection',result:refused},
    {id:'bad-type',lane:'check',negative:true,failureKind:'validation',status:'pass',evidence:'checker-rejection',result:{status:'error',phase:'check',checked:true,typeAccepted:false}},
    {id:'unsafe-main',lane:'check',negative:false,status:'pass',result:{status:'ok',phase:'check',checked:true,typeAccepted:true,proofTrust:'failed'}},
    {id:'wrong-accept',lane:'check',negative:true,failureKind:'validation',status:'fail',result:{status:'ok',phase:'check',checked:true,typeAccepted:true}},
  ];
  const summary=semanticSummary(rows);
  assert.equal(summary.typeAcceptance.accepted,3);assert.equal(summary.typeAcceptance.checkerRejected,1);
  assert.equal(summary.proofTrustExpectations.total,1);assert.equal(summary.proofTrustExpectations.typeAccepted,1);assert.equal(summary.proofTrustExpectations.exactPasses,1);
  assert.equal(summary.errorExpectations.total,2);assert.deepEqual(summary.errorExpectations.acceptedWithoutExpectedLaterRejection,['wrong-accept']);
  const noKinds=rows.map(({failureKind,...row})=>row);
  assert.deepEqual(semanticSummary(noKinds,[{id:'trust',failureKind:'proof-trust'}]),summary);
});

test('new gate inventory separates 1,498 fixtures from 11 imported support sources',()=>{
  const root=path.resolve(import.meta.dirname,'../../.bootstrap/upstream-phase8/tests');
  const all=walk(root).filter(file=>file.endsWith('.bend')).map(file=>describeFixture(file,path.relative(root,file)));
  const fixtures=all.filter(t=>t.id.split('/').length===2),support=all.filter(t=>t.id.split('/').length!==2);
  assert.equal(all.length,1509);assert.equal(support.length,11);assert.ok(support.every(t=>!t.hasExpectation));
  assert.equal(fixtures.length,1498);assert.equal(fixtures.filter(t=>!t.negative).length,1001);
  assert.equal(fixtures.filter(t=>t.failureKind==='validation').length,482);
  assert.equal(fixtures.filter(t=>t.failureKind==='error').length,4);
  const trusts=fixtures.filter(t=>t.failureKind==='proof-trust');assert.equal(trusts.length,11);assert.ok(trusts.every(t=>!t.main));
  assert.ok(fixtures.every(t=>t.hasExpectation));
});

test('inventory PIN belongs to the manifest adjacent to each frozen snapshot',async()=>{
  assert.equal(PIN,JSON.parse(fs.readFileSync(PIN_MANIFEST,'utf8')).upstream);
  const root=path.join(temporary,'frozen snapshot'),tool=path.join(root,'tools/conformance/inventory.mjs'),manifest=path.join(root,'src/compiler.json');
  fs.mkdirSync(path.dirname(tool),{recursive:true});fs.mkdirSync(path.dirname(manifest),{recursive:true});
  fs.copyFileSync(path.resolve(import.meta.dirname,'../../tools/conformance/inventory.mjs'),tool);
  const pin='1234567890abcdef1234567890abcdef12345678';fs.writeFileSync(manifest,JSON.stringify({upstream:pin}));
  const frozen=await import(pathToFileURL(tool));assert.equal(frozen.PIN,pin);assert.equal(frozen.PIN_MANIFEST,manifest);
  fs.writeFileSync(manifest,JSON.stringify({upstream:'invalid'}));
  await assert.rejects(import(pathToFileURL(tool)+'?invalid'),/Invalid upstream pin/);
  fs.rmSync(manifest);await assert.rejects(import(pathToFileURL(tool)+'?missing'),/ENOENT/);
});
