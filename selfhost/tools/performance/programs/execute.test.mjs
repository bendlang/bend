// Tiny worker controls; run serially, without compiling any Bend source.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'bend-program-worker-'));
const worker = fileURLToPath(new URL('./execute.mjs', import.meta.url));
const defaults = {args:[7], expected:49, warmupCalls:3, warmupMs:1,
  calibrationMs:1, targetMs:2, maxRepetitions:1000};
const cases = [];
function run(name, source, point = {}, extension = 'mjs') {
  const module = path.join(directory, `${name}.${extension}`);
  const config = path.join(directory, `${name}.json`), output = path.join(directory, `${name}.out.json`);
  fs.writeFileSync(module, source);
  fs.writeFileSync(config, JSON.stringify({...defaults,...point}));
  const result = spawnSync(process.execPath, ['--max-old-space-size=128', worker, module, config, output],
    {encoding:'utf8', timeout:5000});
  assert.ifError(result.error);
  const report = JSON.parse(fs.readFileSync(output));
  cases.push({name,status:result.status,stage:report.stage,pass:report.pass});
  return {result, report, module, config, output};
}
try {
  const good = run('esm', 'console.log("incidental stdout"); export default {bench:n=>n*n};');
  assert.equal(good.result.status, 0);
  assert.equal(good.report.complete, true);
  assert.equal(good.report.firstResult, 49);
  assert.ok(good.result.stdout.includes('incidental stdout'));
  assert.ok(good.report.warmup.calls >= 3 && good.report.warmup.ms >= 1);
  assert.ok(good.report.repetitions >= 1 && good.report.repetitions <= 1000);
  assert.equal(good.report.halves.reduce((n,x) => n+x.calls, 0), good.report.repetitions);
  assert.equal(good.report.checksum, (49*good.report.repetitions)>>>0);
  assert.ok(good.report.calibration.length > 0 && good.report.msPerCall >= 0);
  assert.ok(good.report.importMs >= 0 && good.report.firstCallMs >= 0 && good.report.peakRssKiB > 0);
  assert.equal(run('named', 'export const bench = n => n*n;').result.status, 0);
  assert.equal(run('cjs', 'module.exports={bench:n=>n*n};', {}, 'cjs').result.status, 0);
  const wrong = run('wrong', 'export default {bench:()=>0};');
  assert.equal(wrong.result.status, 1);
  assert.equal(wrong.report.complete, false);
  assert.equal(wrong.report.stage, 'first-call');
  assert.match(wrong.report.error, /wrong result during first-call/);
  const mutation = run('mutation', 'export default {bench:x=>++x.n};', {args:[{n:0}],expected:1});
  assert.equal(mutation.result.status, 1);
  assert.equal(mutation.report.stage, 'warmup');
  assert.match(mutation.report.error, /wrong result during warmup/);
  const minimal = {warmupCalls:0, warmupMs:0, calibrationMs:0, maxRepetitions:1};
  const calibration = run('calibration-result',
    'let calls=0; export default {bench:()=>++calls<2 ? 49 : 0};', minimal);
  assert.equal(calibration.result.status, 1);
  assert.equal(calibration.report.stage, 'calibration');
  const timed = run('timed-result',
    'let calls=0; export default {bench:()=>++calls<3 ? 49 : 0};', minimal);
  assert.equal(timed.result.status, 1);
  assert.equal(timed.report.stage, 'timing');
  assert.equal(timed.report.pass, false);
  assert.equal(run('missing', 'export default {};').report.stage, 'import');
  assert.equal(run('invalid', 'export default {bench:n=>n*n};', {maxRepetitions:0}).report.stage, 'configuration');
  const original = fs.readFileSync(good.output);
  const repeat = spawnSync(process.execPath, ['--max-old-space-size=128', worker,
    good.module, good.config, good.output], {encoding:'utf8',timeout:5000});
  assert.notEqual(repeat.status, 0);
  assert.deepEqual(fs.readFileSync(good.output), original);
  console.log(JSON.stringify({pass:true,cases,retainedReceipt:true}));
} finally {
  fs.rmSync(directory, {recursive:true,force:true});
}
