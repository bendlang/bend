// One diagnostic variant per bounded invocation. No performance comparisons.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {supervise, requireExecution} from '../../development/process.mjs';

const [planFile, variant, outArg] = process.argv.slice(2);
const p = JSON.parse(fs.readFileSync(planFile));
const out = path.resolve(outArg);
assert.equal(p.kind, 'phase31-generated-compiler-attribution-plan');
assert.ok(['checked_parent','generated_h'].includes(variant));
assert.equal(p.cpu, '2');
assert.equal(p.timeoutMs, 90000);
const identity = file => ({file:fs.realpathSync(file), sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex'), bytes:fs.statSync(file).size});
const inputs = [...p.inputs, identity(planFile), identity(import.meta.filename)];
const verify = () => {for (const item of inputs) assert.equal(identity(item.file).sha256, item.sha256)};
fs.mkdirSync(out);
const report = {kind:'phase31-generated-compiler-attribution-run', complete:false, pass:false, variant, plan:identity(planFile), inputs, scope:p.scope};
const save = () => fs.writeFileSync(path.join(out,'report.json'), JSON.stringify(report,null,2)+'\n');
save();
fs.copyFileSync(import.meta.filename, path.join(out,'consumed-runner.mjs'));
fs.copyFileSync(p.worker.file, path.join(out,'consumed-worker.mjs'));
const env = {...process.env};
for (const key of Object.keys(env)) if (key.startsWith('BEND_') || ['NODE_OPTIONS','NODE_PATH'].includes(key)) delete env[key];
try {
  verify();
  assert.equal(identity(process.execPath).sha256, p.node.sha256);
  const prepared = JSON.parse(fs.readFileSync(p.prepared.file));
  const requestFile = path.join(out,'request.json');
  const resultFile = path.join(out,'result.json');
  fs.writeFileSync(requestFile, JSON.stringify({plan:p, variant, mode:'trial', prepared:prepared.rows.find(row=>row.variant===variant).observation},null,2)+'\n');
  report.execution = await supervise('taskset',['-c',p.cpu,process.execPath,...p.nodeArgs,p.worker.file,requestFile,resultFile],
    {directory:path.join(out,'process'),env,timeoutMs:p.timeoutMs,maxBytes:4*1024*1024});
  save();
  requireExecution(report.execution);
  const result = JSON.parse(fs.readFileSync(resultFile));
  report.result = identity(resultFile);
  assert.equal(result.complete,true);
  assert.equal(result.pass,true);
  assert.equal(result.affinity.split(':')[1].trim(),p.cpu);
  assert.equal(result.requests.length,3);
  for (const row of result.requests) assert.equal(row.outputSha256,p.expected.sha256);
  verify();
  report.complete=true;
  report.pass=true;
} catch(error) {report.error=String(error.stack??error);process.exitCode=1}
save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,variant,error:report.error}));
