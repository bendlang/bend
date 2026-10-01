// Serial synthetic controls; root runs these with an explicit small Node heap.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {summarizeCpu, summarizeAllocation} from './profile.mjs';

const moduleUrl = 'file:///fixture.mjs';
const frame = (functionName, lineNumber = 1, url = moduleUrl) =>
  ({functionName, url, lineNumber, columnNumber:2, scriptId:'1'});
const nodes = [
  {id:1,callFrame:frame('(root)',-1,''),children:[2]},
  {id:2,callFrame:frame('recursive'),children:[3,4]},
  {id:3,callFrame:frame('recursive'),children:[]},
  {id:4,callFrame:frame('same-name-different-site',2),children:[]},
];
const cpu = summarizeCpu({nodes, samples:[3,4,4], timeDeltas:[10,20,30],
  startTime:100,endTime:160}, moduleUrl);
assert.equal(cpu.sampleCount, 3);
assert.equal(cpu.totalWeight, 60);
assert.equal(cpu.categories.generated.selfWeight, 60);
assert.equal(cpu.frames.find(f => f.functionName === 'recursive').selfWeight, 10);
assert.equal(cpu.frames.find(f => f.functionName === 'recursive').inclusiveWeight, 60);
assert.equal(cpu.frames.find(f => f.functionName === 'recursive').inclusiveSamples, 3);
assert.equal(cpu.frames.find(f => f.functionName === 'recursive').line, 2);
assert.equal(cpu.frames.find(f => f.functionName === 'recursive').frame.lineNumber, 1);
assert.equal(cpu.topSelf[0].functionName, 'same-name-different-site');
assert.ok(cpu.warnings.length);
const distinct = summarizeCpu({nodes:[
  {id:1,callFrame:frame('(root)',-1,''),children:[2,3]},
  {id:2,callFrame:frame('duplicate',1),children:[]},
  {id:3,callFrame:frame('duplicate',2),children:[]},
],samples:[2,3],timeDeltas:[10,20],startTime:0,endTime:30}, moduleUrl);
assert.equal(distinct.frames.filter(f => f.functionName === 'duplicate').length, 2);
assert.throws(() => summarizeCpu({nodes,samples:[99],timeDeltas:[1]}, moduleUrl),
  /invalid profile observation/);
assert.throws(() => summarizeCpu({nodes,samples:[2],timeDeltas:[]}, moduleUrl),
  /sample\/delta mismatch/);
assert.throws(() => summarizeCpu({nodes,samples:[2],timeDeltas:[-1]}, moduleUrl),
  /invalid CPU time delta/);

const allocation = summarizeAllocation({head:{id:1,callFrame:frame('(root)',-1,''),selfSize:0,
  children:[{id:2,callFrame:frame('allocate'),selfSize:128,children:[]}]},
  samples:[{nodeId:2,size:128,ordinal:1}]}, moduleUrl);
assert.equal(allocation.estimatedBytes, 128);
assert.equal(allocation.sampleCount, 1);
assert.equal(allocation.topSelf[0].selfBytes, 128);
assert.equal(allocation.topInclusive.find(f => f.functionName === '(root)').inclusiveBytes, 128);
assert.match(summarizeAllocation({head:{id:1,callFrame:frame('(root)',-1,''),selfSize:0,
  children:[]},samples:[]}, moduleUrl).warnings[0], /does not prove allocation-free/);
// Reduced control from the retained fast-01 failure: one tail sample references
// absent node 38, and even mapped samples differ from the tree's selfSize total.
const orphan = summarizeAllocation({head:{id:1,callFrame:frame('(root)',-1,''),selfSize:0,
  children:[{id:2,callFrame:frame('allocate'),selfSize:255891848,children:[]}]},
  samples:[{nodeId:2,size:255874080,ordinal:1},{nodeId:38,size:35136,ordinal:7802}]}, moduleUrl);
assert.equal(orphan.sampleCount, 2);
assert.equal(orphan.estimatedBytes, 255909216);
assert.equal(orphan.accounting.headSelfSizeBytes, 255891848);
assert.equal(orphan.accounting.sampleMinusHeadBytes, 17368);
assert.equal(orphan.accounting.unattributedSamples, 1);
assert.equal(orphan.accounting.unattributedEstimatedBytes, 35136);
assert.deepEqual(orphan.accounting.unattributedNodeIds, [38]);
assert.equal(orphan.categories.unattributed.selfWeight, 35136);
assert.equal(orphan.topInclusive.find(f => f.functionName === '(root)').inclusiveBytes, 255874080,
  'An orphan sample must not acquire an invented parent call path');
assert.ok(orphan.warnings.some(s => s.includes('absent tree nodes')));
assert.ok(orphan.warnings.some(s => s.includes('sample and tree estimates differ')));
assert.throws(() => summarizeAllocation({head:{id:1,callFrame:frame('(root)',-1,''),selfSize:0,
  children:[]},samples:[{nodeId:38,size:-1,ordinal:1}]}, moduleUrl), /invalid allocation sample/);

const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'bend-program-profile-'));
const worker = fileURLToPath(new URL('./profile.mjs', import.meta.url));
const defaults = {args:[7],expected:49,warmupCalls:1,warmupMs:1,targetMs:20,
  maxRepetitions:1000000};
const cases = [];
const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
function run(name, source, point = {}, extension = 'mjs') {
  const module = path.join(directory, `${name}.${extension}`);
  const config = path.join(directory, `${name}.json`);
  const output = path.join(directory, `${name}.receipt.json`);
  const profile = path.join(directory, `${name}.profile.json`);
  fs.writeFileSync(module, source);
  fs.writeFileSync(config, JSON.stringify({...defaults,...point}));
  const result = spawnSync(process.execPath, ['--max-old-space-size=128', worker,
    module, config, output, profile], {encoding:'utf8',timeout:10000});
  assert.ifError(result.error);
  const report = JSON.parse(fs.readFileSync(output));
  cases.push({name,status:result.status,stage:report.stage,pass:report.pass});
  return {result,report,module,config,output,profile};
}
try {
  const good = run('cpu', 'console.log("incidental stdout"); export default {bench:n=>n*n};');
  assert.equal(good.result.status, 0, good.report.error);
  assert.equal(good.report.complete, true);
  assert.equal(good.report.diagnosticOnly, true);
  assert.equal(good.report.firstCalls, 1);
  assert.equal(good.report.firstResult, 49);
  assert.ok(good.report.warmup.calls >= 1 && good.report.warmup.ms >= 1);
  assert.ok(good.report.repetitions > 0 && good.report.repetitions <= 1000000);
  assert.equal(good.report.checksum, (49*good.report.repetitions)>>>0);
  assert.ok(good.report.summary.sampleCount > 0);
  assert.equal(good.report.profile.sha256, sha(good.profile));
  assert.equal(good.report.module.sha256, sha(good.module));
  assert.equal(good.report.configSha256, sha(good.config));
  assert.equal(good.report.toolSha256, sha(worker));
  assert.ok(JSON.parse(fs.readFileSync(good.profile)).nodes.length > 0);
  assert.ok(good.report.peakRssKiB > 0);
  assert.equal(good.report.msPerCall, undefined);
  assert.ok(good.result.stdout.includes('incidental stdout'));
  assert.equal(run('named', 'export const bench = n => n*n;').result.status, 0);
  assert.equal(run('cjs', 'module.exports={bench:n=>n*n};', {}, 'cjs').result.status, 0);
  const allocated = run('allocation',
    'let latest; export default {bench:n=>{latest=Array.from({length:1000},(_,i)=>({i,n})); return n*n}};',
    {profileKind:'allocation',samplingIntervalBytes:1024,targetMs:30});
  assert.equal(allocated.result.status, 0, allocated.report.error);
  assert.ok(allocated.report.summary.estimatedBytes > 0);
  assert.ok(allocated.report.summary.sampleCount > 0);
  assert.equal(allocated.report.sampling.includeObjectsCollectedByMajorGC, true);
  assert.equal(allocated.report.sampling.includeObjectsCollectedByMinorGC, true);
  assert.ok(JSON.parse(fs.readFileSync(allocated.profile)).head);
  const capped = run('capped', 'export default {bench:n=>n*n};',
    {warmupCalls:0,warmupMs:0,targetMs:1000,maxRepetitions:1});
  assert.equal(capped.result.status, 0);
  assert.equal(capped.report.targetReached, false);
  assert.equal(capped.report.maxRepetitionsReached, true);
  assert.ok(capped.report.summary.warnings.some(s => s.includes('duration was not reached')));
  const wrong = run('wrong-first', 'export default {bench:()=>0};');
  assert.equal(wrong.result.status, 1);
  assert.equal(wrong.report.stage, 'first-call');
  assert.equal(wrong.report.complete, false);
  const warm = run('wrong-warm', 'let n=0; export default {bench:()=>++n===1?49:0};');
  assert.equal(warm.result.status, 1);
  assert.equal(warm.report.stage, 'warmup');
  for (const profileKind of ['cpu','allocation']) {
    const bad = run(`wrong-${profileKind}`,
      'let n=0; export default {bench:()=>++n===1?49:0};',
      {profileKind,warmupCalls:0,warmupMs:0});
    assert.equal(bad.result.status, 1);
    assert.equal(bad.report.stage, 'profiling');
    assert.equal(bad.report.complete, false);
    assert.equal(bad.report.pass, false);
    assert.equal(bad.report.repetitions, 0);
    assert.ok(bad.report.profile.bytes > 0, 'partial raw profile must survive wrong output');
    assert.equal(bad.report.profile.sha256, sha(bad.profile));
    assert.match(bad.report.error, /wrong result during profiling/);
  }
  const mutation = run('mutated-argument', 'export default {bench:x=>++x.n};',
    {args:[{n:0}],expected:1});
  assert.equal(mutation.result.status, 1);
  assert.equal(mutation.report.stage, 'warmup');
  assert.equal(run('invalid', 'export default {bench:n=>n*n};',
    {profileKind:'bogus'}).report.stage, 'configuration');
  assert.equal(run('missing', 'export default {};').report.stage, 'import');
  const changed = run('changed-module',
    'import fs from "node:fs"; let n=0; export default {bench:()=>{if(++n===2) fs.appendFileSync(import.meta.filename,"\\n");return 49}};',
    {warmupCalls:0,warmupMs:0,maxRepetitions:1});
  assert.equal(changed.result.status, 1);
  assert.equal(changed.report.stage, 'identity-check');
  assert.match(changed.report.error, /module changed/);
  const originalReceipt = fs.readFileSync(good.output), originalProfile = fs.readFileSync(good.profile);
  const repeat = spawnSync(process.execPath, ['--max-old-space-size=128', worker,
    good.module,good.config,good.output,good.profile], {encoding:'utf8',timeout:5000});
  assert.notEqual(repeat.status, 0);
  assert.deepEqual(fs.readFileSync(good.output), originalReceipt);
  assert.deepEqual(fs.readFileSync(good.profile), originalProfile);
  const freshReceipt = path.join(directory, 'existing-profile.receipt.json');
  const preserved = spawnSync(process.execPath, ['--max-old-space-size=128',worker,
    good.module,good.config,freshReceipt,good.profile], {encoding:'utf8',timeout:5000});
  assert.notEqual(preserved.status, 0);
  assert.equal(JSON.parse(fs.readFileSync(freshReceipt)).stage, 'configuration');
  assert.deepEqual(fs.readFileSync(good.profile), originalProfile);
  console.log(JSON.stringify({pass:true,aggregationControls:true,cases,
    retainedReceipt:true,retainedProfile:true}));
} finally {
  fs.rmSync(directory,{recursive:true,force:true});
}
