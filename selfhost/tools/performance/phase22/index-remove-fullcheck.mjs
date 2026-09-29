// Uninstrumented correctness observation; concurrent time is not a benchmark.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt, identity, verifyIdentity} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

const [attemptArg,outArg,sourceArg,expectedArg]=process.argv.slice(2);
const cpu='0';
const attempt = fs.realpathSync(attemptArg), out = path.resolve(outArg);
const m = await verifyAttempt(attempt);
fs.mkdirSync(out);
const bootstrap = JSON.parse(fs.readFileSync(m.bootstrapReport.file));
const source = sourceArg ? fs.realpathSync(sourceArg) : bootstrap.source;
const {validatedCache} = await import(pathToFileURL(path.join(m.snapshot.root, 'tools/development/workflow.mjs')));
const worker = path.join(out, 'worker.mjs');
fs.copyFileSync(new URL('../phase8/check-worker.mjs', import.meta.url), worker);
const cache = validatedCache(path.join(m.snapshot.root, 'build/typed/cache'), m.api.file, m.base.file);
const files = [worker, import.meta.filename, expectedArg, process.execPath, source,
  m.api.file, m.base.file, m.runtime.file, cache.file,
  ...m.snapshot.sources.map(x => x.frozen.file),
  ...bootstrap.provenance.inputs.map(x => x.file)];
const inputs = [...new Set(files)].map(identity);
const workdir = path.join(out, 'work'); fs.mkdirSync(workdir);
const request = {variant: 'bend', source, api: m.api.file,
  base: m.base.file, runtime: m.runtime.file, upstream: m.config.upstream,
  adapter: path.join(m.snapshot.root, 'tools/conformance/adapters/typed.mjs'),
  workdir, timeoutMs: 600000, inputs};
const requestFile = path.join(out, 'request.json'), resultFile = path.join(out, 'result.json');
fs.writeFileSync(requestFile, JSON.stringify(request, null, 2) + '\n', {flag: 'wx'});
const report = {kind: 'phase22-index-remove-fullsource-observation', complete: false,
  started: new Date().toISOString(), attempt: identity(path.join(attempt, 'attempt.json')),
  inputs, scope: 'Concurrent complete source correctness observation; no timing comparison.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  report.execution = await supervise('taskset', ['-c', cpu, process.execPath,
    '--stack-size=4096', '--max-old-space-size=4096',
    worker, requestFile, resultFile], {directory: path.join(out, 'process'),
    env: process.env, timeoutMs: 600000});
  requireExecution(report.execution);
  report.result = identity(resultFile);
  assert.equal(JSON.parse(fs.readFileSync(resultFile)).pass, true);
  for (const item of inputs) verifyIdentity(item);
  await verifyAttempt(attempt);
  const actual=JSON.parse(fs.readFileSync(resultFile)).result,expected=JSON.parse(fs.readFileSync(expectedArg)).result;
  assert.deepEqual(actual,expected);report.exactObservation=true;
  report.complete = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
