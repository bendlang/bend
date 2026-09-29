// Same-source comparison with an exact, reviewed list of every changed host file.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity, verifyIdentity, validatedCache} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

const [configArg, outArg] = process.argv.slice(2);
const configFile = fs.realpathSync(configArg), config = JSON.parse(fs.readFileSync(configFile));
for (const key of Object.keys(config)) assert.ok(['baseline', 'candidate', 'source', 'cpu', 'mode', 'hostReview'].includes(key), 'Unknown setting: ' + key);
const resolve = s => fs.realpathSync(path.resolve(path.dirname(configFile), s));
const cpu = String(config.cpu ?? 0), mode = config.mode ?? 'measure';
assert.match(cpu, /^\d+$/); assert.ok(['preflight', 'measure'].includes(mode));
const attempts = {baseline: resolve(config.baseline), candidate: resolve(config.candidate)};
const manifests = {};
for (const [name, dir] of Object.entries(attempts)) manifests[name] = await verifyAttempt(dir);
const final = manifests.candidate, baseline = manifests.baseline;
assert.equal(final.base.sha256, baseline.base.sha256, 'Same pinned Base required');
assert.equal(final.runtime.sha256, baseline.runtime.sha256, 'Same output runtime required');
assert.equal(final.config.upstream, baseline.config.upstream, 'Same pinned checkout required');
const hostFiles = m => new Map(m.snapshot.sources
  .map(({frozen}) => [path.relative(m.snapshot.root, frozen.file), frozen])
  .filter(([name]) => name.startsWith('tools/')));
const oldHosts = hostFiles(baseline), newHosts = hostFiles(final);
assert.deepEqual([...newHosts.keys()].sort(), [...oldHosts.keys()].sort(), 'Host file membership drift');
assert.ok(config.hostReview, 'Explicit prospective host review required');
const reviewFile = resolve(config.hostReview), review = JSON.parse(fs.readFileSync(reviewFile));
assert.equal(review.pass, true);
assert.ok(Array.isArray(review.changes));
const changed = [...newHosts].filter(([name, item]) => item.sha256 !== oldHosts.get(name).sha256).map(([name]) => name).sort();
assert.deepEqual(review.changes.map(x => x.relative).sort(), changed, 'Exact reviewed host delta required; no ignored changes');
for (const change of review.changes) {
  assert.equal(change.before.sha256, oldHosts.get(change.relative).sha256, 'Reviewed baseline host required');
  assert.equal(change.after.sha256, newHosts.get(change.relative).sha256, 'Reviewed candidate host required');
  assert.equal(fs.realpathSync(change.before.file), oldHosts.get(change.relative).canonicalPath);
  assert.equal(fs.realpathSync(change.after.file), newHosts.get(change.relative).canonicalPath);
  for (const item of [change.before, change.after, change.patch]) verifyIdentity(item);
}
const hostDelta = {changed: changed.length > 0, review: identity(reviewFile), changes: review.changes,
  scope: 'Complete same-source workflows; every changed frozen host file is explicitly reviewed and hashed. All unlisted host bytes and all host file membership must agree.'};
const bootstrap = JSON.parse(fs.readFileSync(final.bootstrapReport.file));
const source = config.source ? resolve(config.source) : bootstrap.source;
const out = path.resolve(outArg); fs.mkdirSync(out);
const worker = path.join(out, 'worker.mjs');
fs.copyFileSync(new URL('../phase8/check-worker.mjs', import.meta.url), worker);
const inputs = new Map(), add = file => { const i = identity(file); inputs.set(i.file, i); return i; };
for (const file of [configFile, reviewFile, ...review.changes.map(x => x.patch.file), import.meta.filename, worker, process.execPath, source]) add(file);
const variants = {};
for (const [name, m] of Object.entries(manifests)) {
  const cache = validatedCache(path.join(m.snapshot.root, 'build/typed/cache'), m.api.file, m.base.file);
  variants[name] = {attempt: add(path.join(attempts[name], 'attempt.json')), api: m.api,
    artifactKind: m.artifactKind, cache};
  for (const i of [m.api, m.base, m.runtime, cache, m.bootstrapReport,
    ...m.artifacts, ...m.snapshot.sources.map(x => x.frozen)]) add(i.file);
}
for (const file of ['bend.ts', 'comp.ts', 'main.ts', 'base.bend']) add(path.join(final.config.upstream, 'bend2', file));
const report = {kind: 'phase16-full-source-check-comparison', mode, complete: false,
  started: new Date().toISOString(), source: identity(source), config: identity(configFile),
  variants, inputs: [...inputs.values()], cpu, hostDelta, rows: [],
  scope: 'Same-source checking/trust reporting using each release workflow, with an explicit reviewed host delta if present, no emission. Fresh processes; separately validated Bend Base caches; TypeScript checks Base; OS caches not flushed.',
  timingBoundary: 'Request wraps adapter.probe and includes lazy API loading; adapter import is outside request. Process wall includes startup, hashing and output capture.',
  order: mode === 'measure' ? ['typescript', 'baseline', 'candidate', 'candidate', 'baseline', 'typescript'] : ['typescript', 'candidate']};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const verify = () => report.inputs.forEach(verifyIdentity);
save();
try {
  for (const [index, variant] of report.order.entries()) {
    verify();
    const m = variant === 'typescript' ? final : manifests[variant];
    const prefix = path.join(out, `${index}-${variant}`), workdir = prefix + '-work'; fs.mkdirSync(workdir);
    const request = {variant, source, api: m.api.file, base: m.base.file,
      runtime: m.runtime.file, upstream: m.config.upstream, workdir, timeoutMs: 600000,
      adapter: path.join(m.snapshot.root, 'tools/conformance/adapters', variant === 'typescript' ? 'upstream.mjs' : 'typed.mjs'),
      inputs: report.inputs};
    const requestFile = prefix + '.request.json', resultFile = prefix + '.result.json';
    fs.writeFileSync(requestFile, JSON.stringify(request, null, 2) + '\n', {flag: 'wx'});
    const execution = await supervise('taskset', ['-c', cpu, process.execPath,
      '--stack-size=4096', '--max-old-space-size=4096', worker, requestFile, resultFile],
      {directory: prefix + '-process', env: process.env, timeoutMs: 600000});
    const row = {index, variant, execution, observation: fs.existsSync(resultFile) ? JSON.parse(fs.readFileSync(resultFile)) : null};
    report.rows.push(row); save(); requireExecution(execution);
    assert.equal(row.observation.pass, true, 'Ordinary type/trust gate');
    assert.equal(row.observation.affinity.split(':')[1].trim(), cpu);
    verify();
  }
  for (const dir of Object.values(attempts)) await verifyAttempt(dir);
  const sets = report.rows.map(r => [...r.observation.result.unsafeDefinitions].sort());
  report.unsafeDefinitionSetsAgree = sets.every(x => JSON.stringify(x) === JSON.stringify(sets[0]));
  assert.ok(report.unsafeDefinitionSetsAgree);
  if (mode === 'measure') {
    const mean = xs => xs.reduce((a, b) => a + b, 0) / xs.length;
    report.statistics = Object.fromEntries(['typescript', 'baseline', 'candidate'].map(v => {
      const rows = report.rows.filter(r => r.variant === v); assert.equal(rows.length, 2);
      return [v, {samples: rows.length, meanRequestMs: mean(rows.map(r => r.observation.requestMs)),
        meanProcessWallMs: mean(rows.map(r => r.execution.wallMs)),
        maxRssKiB: Math.max(...rows.map(r => r.observation.maxRssKiB))}];
    }));
    const s = report.statistics;
    report.ratios = {baselineToTs: s.baseline.meanProcessWallMs / s.typescript.meanProcessWallMs,
      candidateToTs: s.candidate.meanProcessWallMs / s.typescript.meanProcessWallMs,
      baselineToCandidate: s.baseline.meanProcessWallMs / s.candidate.meanProcessWallMs,
      candidateProcessReduction: 1 - s.candidate.meanProcessWallMs / s.baseline.meanProcessWallMs,
      candidateRequestReduction: 1 - s.candidate.meanRequestMs / s.baseline.meanRequestMs};
  }
  report.complete = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
