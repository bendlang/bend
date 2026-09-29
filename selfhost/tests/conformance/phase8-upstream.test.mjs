import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import {capabilities,declarationReport,probeWithModules} from '../../tools/conformance/adapters/upstream.mjs';

const root=path.resolve(process.env.BEND_UPSTREAM||path.join(import.meta.dirname,'../../.bootstrap/upstream-phase23'));
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-phase8-reference-'));
process.on('exit',()=>fs.rmSync(directory,{recursive:true,force:true}));
const term={$:'Typ'},def=(extra={})=>({$:'Def',T:term,v:term,e:term,...extra});
const book=()=>({tlds:Object.create(null),ctrs:Object.create(null),order:[],hols:0});
const lowering={term_lower:x=>x};
function mocks({load,validate}={}){
  return {book_nil(){const b=book();Object.defineProperty(b,'open',{get(){throw Error('removed Book.open used');}});return b;},
    book_load:async b=>{load?.(b);return 99;},book_valid:b=>validate?.(b),...lowering,
    err_show:error=>error.text,term_snf:(_b,x)=>x,term_show:()=> '42'};
}
const noOldAPIs={get book_owned(){throw Error('removed book_owned used');},get SYNTH(){throw Error('obsolete SYNTH used');},io_type:()=>null};
const request=(lane='check',file='test.bend')=>({upstream:root,test:{file:path.join(directory,file)},lane,workdir:directory,timeoutMs:1000});

test('safe verdict uses new wording and disclaims kernel validation',()=>{
  const b=book();b.tlds.clean=def();b.order=['clean'];
  assert.deepEqual(declarationReport(lowering,b),{text:'ALL PROOFS CHECK\nUse --verdict for mathematical validity.\n',proofTrust:'passed',unsafeDefinitions:[],kernelChecked:false});
  assert.equal(capabilities.proofKernel,false);
});

test('trust includes imported declarations, transitive types and fields, but not Base promises',()=>{
  const b=book();Object.assign(b.tlds,{base: def({b:true,i:['base.js']}),foreign:def({i:['own.js']}),boom:def({u:true}),
    'imported.user':def({e:{$:'Ref',k:'boom'}}),Box:{$:'ADT',T:term,c:[{T:{$:'Ref',k:'imported.user'}}]},
    typed:def({T:{$:'ADT',k:'Box'}}),clean:def({e:{$:'Ref',k:'base',s:{$:'Ref',k:'boom'}}})});
  b.order=['base','foreign','boom','imported.user','Box','typed','clean','boom'];
  const result=declarationReport(lowering,b);
  assert.deepEqual(result.unsafeDefinitions,['foreign','boom','imported.user','Box','typed']);
  assert.equal(result.text,'SOME PROOFS FAIL\nError: 5 defs rely on unsafe or foreign code:\n- foreign\n- boom\n- imported.user\n- Box\n- typed\n');
});

test('ordinary check never touches deleted book_owned or Book.open',async()=>{
  const result=await probeWithModules(request(),mocks(),noOldAPIs);
  assert.equal(result.status,'ok');assert.equal(result.checked,true);assert.equal(result.typeAccepted,true);assert.equal(result.kernelChecked,false);
});

test('trust refusal preserves actual type acceptance and is a distinct phase',async()=>{
  const B=mocks({load:b=>{b.tlds.boom=def({u:true});b.order=['boom'];}});
  for(const lane of ['check','interpreter']){
    const result=await probeWithModules(request(lane),B,noOldAPIs);
    assert.equal(result.status,'error');assert.equal(result.phase,'verdict');assert.equal(result.checked,true);assert.equal(result.typeAccepted,true);assert.equal(result.exitCode,1);
    assert.equal(result.proofTrust,'failed');assert.equal(result.kernelChecked,false);
    assert.equal(result.diagnostic,'SOME PROOFS FAIL\nError: 1 def relies on unsafe or foreign code:\n- boom\n');
  }
});

test('unsafe runnable main accepts and executes while its trust failure remains recorded',async()=>{
  const B=mocks({load:b=>{b.tlds.main=def({u:true});b.order=['main'];}});
  const checked=await probeWithModules(request(),B,noOldAPIs);
  assert.equal(checked.status,'ok');assert.equal(checked.phase,'check');assert.equal(checked.typeAccepted,true);assert.equal(checked.proofTrust,'failed');assert.equal(checked.exitCode,0);
  const executed=await probeWithModules(request('interpreter'),B,noOldAPIs);
  assert.equal(executed.status,'ok');assert.equal(executed.phase,'runtime');assert.equal(executed.stdout,'42\n');assert.equal(executed.proofTrust,'not-assessed');
});

test('load, checker, and TODO failures receive new framing without acceptance credit',async()=>{
  const cases=[
    [mocks({load:()=>{throw {$:'Err',text:'Error: bad source'};}}),'parse',false,'Error: bad source'],
    [mocks({validate:()=>{throw {$:'Err',text:'Error: bad type'};}}),'check',true,'Error: bad type'],
    [mocks({validate:b=>{b.hols=2;}}),'check',true,'Error: 2 TODOs found.\nThe code is incomplete, and not a valid proof yet.'],
    [mocks({validate:()=>{throw new RangeError();}}),'check',true,'Error: the machine stack overflowed (a deep recursion, or a literal too large to expand)'],
  ];
  for(const [B,phase,checked,text] of cases){const result=await probeWithModules(request(),B,noOldAPIs);assert.equal(result.phase,phase);assert.equal(result.checked,checked);assert.equal(result.typeAccepted,false);assert.equal(result.diagnostic,'SOME PROOFS FAIL\n'+text);assert.equal(result.exitCode,1);}
});

test('PROOF missing LAWS is a framed load refusal, while parse lane stays observation-only',async()=>{
  fs.writeFileSync(path.join(directory,'LAWS.bend'),'');
  const result=await probeWithModules(request('check','PROOF.bend'),mocks(),noOldAPIs);
  assert.equal(result.phase,'load');assert.equal(result.checked,false);assert.equal(result.diagnostic,'SOME PROOFS FAIL\nError: PROOF.bend must import ./LAWS.bend');
  assert.equal((await probeWithModules(request('parse','PROOF.bend'),mocks(),noOldAPIs)).status,'ok');
});

test('emission errors stay plain Error diagnostics after validated acceptance',async()=>{
  const result=await probeWithModules(request('js'),mocks(),Object.assign(Object.create(noOldAPIs),{js_book:()=>{throw 'Error: emitter refused';}}));
  assert.equal(result.phase,'compile');assert.equal(result.typeAccepted,true);assert.equal(result.diagnostic,'Error: emitter refused');
});

test('emitted JavaScript receives the fixture basename as argv[0]',async()=>{
  const result=await probeWithModules(request('js','args.bend'),mocks(),Object.assign(Object.create(noOldAPIs),{
    js_book:()=>"console.log(require('node:path').basename(process.argv[1]));\n",
  }));
  assert.equal(result.status,'ok');assert.equal(result.output,'args.cjs\n');
  assert.ok(fs.existsSync(path.join(directory,'args.cjs')));
});

test('interpreter IO eligibility cannot be mislabeled a type rejection',async()=>{
  const B=mocks({load:b=>{b.tlds.main=def();b.order=['main'];}});
  const result=await probeWithModules(request('interpreter'),B,{io_type(){throw 'Error: foreign main';}});
  assert.equal(result.phase,'compile');assert.equal(result.typeAccepted,true);assert.equal(result.proofTrust,'not-assessed');assert.equal(result.diagnostic,'Error: foreign main');
});
