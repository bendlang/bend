import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import childProcess,{spawnSync} from 'node:child_process';
import {syncBuiltinESMExports} from 'node:module';
import test from 'node:test';
import {inventory,probes,PIN} from '../../tools/conformance/inventory.mjs';
const project=path.resolve(import.meta.dirname,'../..');
const upstream=process.env.BEND_UPSTREAM||path.join(project,'.bootstrap/upstream-phase23');
const available=fs.existsSync(path.join(upstream,'tests'));
test('successful git status never masks a subprocess capture error',context=>{
  const mocked=context.mock.method(childProcess,'spawnSync',()=>({status:0,signal:null,error:new Error('spawnSync git EPERM')}));
  syncBuiltinESMExports();
  try {assert.throws(()=>inventory('/unused'),/verification failed: spawnSync git EPERM/);}
  finally {mocked.mock.restore();syncBuiltinESMExports();}
});
test('pinned corpus is exhaustive and includes every negative namespace',{skip:!available},()=>{
  const inv=inventory(upstream);
  assert.equal(PIN,'018751270e800bc222a93dad7f257083ee53a5f7');
  assert.equal(inv.revision,PIN);
  assert.equal(inv.total,1513);
  assert.equal(inv.bendSourceCount,1524);
  assert.equal(inv.supportSources.length,11);
  assert.ok(inv.supportSources.every(t=>!t.hasExpectation));
  assert.equal(inv.tests.filter(t=>!t.negative).length,1016);
  assert.equal(Object.keys(inv.namespaces).length,24);
  assert.equal(inv.tests.filter(t=>t.negative).length,497);
  assert.equal(inv.tests.filter(t=>!t.hasExpectation).length,0);
  assert.equal(new Set(inv.tests.map(t=>t.id)).size,inv.total);
  assert.equal(inv.effects.length,68);
  for(const fixture of inv.tests) {
    assert.ok(probes(fixture).some(p=>p.lane==='check'));
    if(fixture.main) assert.ok(probes(fixture).some(p=>p.lane==='interpreter')); 
    if(fixture.foreign.length) {
      for(const lane of fixture.backends) assert.ok(fixture.foreign.some(f=>f.backend===lane));
    }
  }
});
test('infinite compiler probe is killed and filtered run cannot claim completeness',{skip:!available},()=>{
  const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'bend-harness-test-'));
  try {
    const adapter=path.join(temporary,'hang.mjs'),output=path.join(temporary,'result.json');
    fs.writeFileSync(adapter,"export const capabilities={parse:true}; export async function probe(){while(true){}}\n");
    const id=inventory(upstream).tests[0].id.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
    const child=spawnSync(process.execPath,[path.join(project,'tools/conformance/run.mjs'),'--upstream',upstream,'--adapter',adapter,
      '--output',output,'--filter','^'+id+'$','--lanes','parse','--timeout','100','--jobs','1'],
      {encoding:'utf8',timeout:10000});
    assert.equal(child.status,1,child.stderr);
    const report=JSON.parse(fs.readFileSync(output,'utf8'));
    assert.equal(report.complete,false);
    assert.equal(report.summary.excludedTests,1512);
    assert.equal(report.results[0].status,'timeout');
  } finally {fs.rmSync(temporary,{recursive:true,force:true});}
});
test('explicit stack and heap limits reach isolated compiler workers and the report',{skip:!available},()=>{
  const temporary=fs.mkdtempSync(path.join(os.tmpdir(),'bend-harness-limits-'));
  try {
    const adapter=path.join(temporary,'limits.mjs'),output=path.join(temporary,'result.json');
    fs.writeFileSync(adapter,"export const capabilities={parse:true}; export async function probe(){return {status:'ok',phase:'parse',exitCode:0,checked:false,args:process.execArgv}}\n");
    const id=inventory(upstream).tests[0].id.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
    const child=spawnSync(process.execPath,[path.join(project,'tools/conformance/run.mjs'),'--upstream',upstream,'--adapter',adapter,
      '--output',output,'--filter','^'+id+'$','--lanes','parse','--timeout','3000','--jobs','1','--stack-kb','4096','--heap-mb','1024'],
      {encoding:'utf8',timeout:10000});
    assert.equal(child.status,1,child.stderr); // Filtered coverage remains incomplete.
    const report=JSON.parse(fs.readFileSync(output,'utf8'));
    assert.deepEqual(report.host.workerNodeArgs,['--stack-size=4096','--max-old-space-size=1024']);
    assert.deepEqual(report.results[0].result.args,report.host.workerNodeArgs);
  } finally {fs.rmSync(temporary,{recursive:true,force:true});}
});
