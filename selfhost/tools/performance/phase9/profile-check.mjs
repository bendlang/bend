// A diagnostic sampling run, separate from uninstrumented timing comparisons.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity, verifyIdentity, validatedCache} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

const [attemptArg, outArg, cpu = '0', intervalUs = '1000'] = process.argv.slice(2);
assert.match(cpu, /^\d+$/);
assert.match(intervalUs, /^\d+$/); assert.ok(Number(intervalUs) >= 100 && Number(intervalUs) <= 1000000);
const summarizer = new URL('./profile-summary.py', import.meta.url);
const attempt = fs.realpathSync(attemptArg), out = path.resolve(outArg);
const m = await verifyAttempt(attempt);
fs.mkdirSync(out);
const bootstrap = JSON.parse(fs.readFileSync(m.bootstrapReport.file));
const worker = path.join(out, 'worker.mjs');
fs.copyFileSync(new URL('../phase8/check-worker.mjs', import.meta.url), worker);
const cache = validatedCache(path.join(m.snapshot.root, 'build/typed/cache'), m.api.file, m.base.file);
const files = [worker, import.meta.filename, summarizer.pathname, process.execPath, bootstrap.source,
  m.api.file, m.base.file, m.runtime.file, cache.file,
  ...m.snapshot.sources.map(x => x.frozen.file),
  ...bootstrap.provenance.inputs.map(x => x.file)];
const inputs = [...new Set(files)].map(identity);
const workdir = path.join(out, 'work'); fs.mkdirSync(workdir);
const request = {variant: 'bend', source: bootstrap.source, api: m.api.file,
  base: m.base.file, runtime: m.runtime.file, upstream: m.config.upstream,
  adapter: path.join(m.snapshot.root, 'tools/conformance/adapters/typed.mjs'),
  workdir, timeoutMs: 600000, inputs};
const requestFile = path.join(out, 'request.json'), resultFile = path.join(out, 'result.json');
fs.writeFileSync(requestFile, JSON.stringify(request, null, 2) + '\n', {flag: 'wx'});
const report = {kind: 'phase9-checker-cpu-profile', complete: false,
  started: new Date().toISOString(), intervalUs: Number(intervalUs), attempt: identity(path.join(attempt, 'attempt.json')),
  inputs, scope: 'Concurrent diagnostic CPU sampling, including process startup; excluded from uninstrumented speed ratios.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  report.execution = await supervise('taskset', ['-c', cpu, process.execPath,
    '--stack-size=4096', '--max-old-space-size=4096', '--cpu-prof',
    '--cpu-prof-interval=' + intervalUs, '--cpu-prof-dir=' + out, '--cpu-prof-name=checking.cpuprofile',
    worker, requestFile, resultFile], {directory: path.join(out, 'process'),
    env: process.env, timeoutMs: 600000});
  requireExecution(report.execution);
  report.result = identity(resultFile);
  assert.equal(JSON.parse(fs.readFileSync(resultFile)).pass, true);
  for (const item of inputs) verifyIdentity(item);
  await verifyAttempt(attempt);
  const profileFile = path.join(out, 'checking.cpuprofile');
  report.profile = identity(profileFile);
  const summaryFile = path.join(out, 'summary.json');
  report.summarization = await supervise('python3', [summarizer.pathname, profileFile, summaryFile],
    {directory: path.join(out, 'summary-process'), env: process.env, timeoutMs: 600000});
  requireExecution(report.summarization);
  report.summary = identity(summaryFile);
  report.complete = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
