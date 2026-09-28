// A diagnostic sampling run, separate from uninstrumented timing comparisons.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity, verifyIdentity, validatedCache} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

const [attemptArg, outArg, cpu = '0'] = process.argv.slice(2);
assert.match(cpu, /^\d+$/);
const attempt = fs.realpathSync(attemptArg), out = path.resolve(outArg);
const m = await verifyAttempt(attempt);
fs.mkdirSync(out);
const bootstrap = JSON.parse(fs.readFileSync(m.bootstrapReport.file));
const worker = path.join(out, 'worker.mjs');
fs.copyFileSync(new URL('../phase8/check-worker.mjs', import.meta.url), worker);
const cache = validatedCache(path.join(m.snapshot.root, 'build/typed/cache'), m.api.file, m.base.file);
const files = [worker, import.meta.filename, process.execPath, bootstrap.source,
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
  started: new Date().toISOString(), attempt: identity(path.join(attempt, 'attempt.json')),
  inputs, scope: 'Concurrent diagnostic CPU sampling, including process startup; excluded from uninstrumented speed ratios.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  report.execution = await supervise('taskset', ['-c', cpu, process.execPath,
    '--stack-size=4096', '--max-old-space-size=4096', '--cpu-prof',
    '--cpu-prof-interval=1000', '--cpu-prof-dir=' + out, '--cpu-prof-name=checking.cpuprofile',
    worker, requestFile, resultFile], {directory: path.join(out, 'process'),
    env: process.env, timeoutMs: 600000});
  requireExecution(report.execution);
  report.result = identity(resultFile);
  assert.equal(JSON.parse(fs.readFileSync(resultFile)).pass, true);
  for (const item of inputs) verifyIdentity(item);
  await verifyAttempt(attempt);
  const profileFile = path.join(out, 'checking.cpuprofile');
  report.profile = identity(profileFile);
  const p = JSON.parse(fs.readFileSync(profileFile)), nodes = new Map(p.nodes.map(n => [n.id, n]));
  const parents = new Map();
  for (const n of p.nodes) for (const id of n.children ?? []) parents.set(id, n.id);
  const key = n => JSON.stringify([n.callFrame.functionName, n.callFrame.url, n.callFrame.lineNumber]);
  const costs = new Map(); let totalUs = 0;
  for (let i = 0; i < p.samples.length; i++) {
    const dt = p.timeDeltas[i]; totalUs += dt;
    let id = p.samples[i], leaf = true; const seen = new Set();
    while (id !== undefined) {
      const n = nodes.get(id), k = key(n);
      if (!costs.has(k)) costs.set(k, {function: n.callFrame.functionName,
        file: n.callFrame.url, line: n.callFrame.lineNumber + 1, selfUs: 0, inclusiveUs: 0});
      const row = costs.get(k);
      if (leaf) row.selfUs += dt;
      if (!seen.has(k)) row.inclusiveUs += dt;
      seen.add(k); leaf = false; id = parents.get(id);
    }
  }
  const rows = [...costs.values()].map(r => ({...r, selfPercent: 100 * r.selfUs / totalUs,
    inclusivePercent: 100 * r.inclusiveUs / totalUs}));
  const summary = {samples: p.samples.length, totalSampleUs: totalUs,
    note: 'Time-weighted samples, not call counts. Inclusive rows overlap; recursive occurrences of a function are counted once per sample.',
    self: [...rows].sort((a, b) => b.selfUs - a.selfUs).slice(0, 50),
    inclusive: [...rows].sort((a, b) => b.inclusiveUs - a.inclusiveUs).slice(0, 50)};
  fs.writeFileSync(path.join(out, 'summary.json'), JSON.stringify(summary, null, 2) + '\n');
  report.complete = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
