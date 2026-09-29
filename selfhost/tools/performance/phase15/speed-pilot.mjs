// Root-authorized serial ABBA check timing for an explicitly derived pilot image.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {bindCandidate, identity, verifyIdentity, validatedCache, supervise, requireExecution} from '../phase14/dispatch-paired-inputs.mjs';

const [configArg, outArg] = process.argv.slice(2), configFile = fs.realpathSync(configArg), config = JSON.parse(fs.readFileSync(configFile));
for (const key of Object.keys(config)) assert.ok(['manifest', 'gate', 'source', 'cpu', 'authorization'].includes(key), 'Unknown setting: ' + key);
assert.equal(config.authorization, 'root-exclusive-pilot', 'Run only after root authorizes an exclusive pilot timing window');
const resolve = value => fs.realpathSync(path.resolve(path.dirname(configFile), value)), out = path.resolve(outArg), cpu = String(config.cpu);
assert.match(cpu, /^\d+$/); fs.mkdirSync(out);
const report = {kind: 'phase15-lookup-workers-same-source-pilot', complete: false, pass: false, started: new Date().toISOString(), cpu,
  scope: 'Isolated genuine checked B1 with unchanged equality v5. Same source, unchanged host and runtime, separately validated API-specific Base caches; no cache preparation or transform work inside timed workers. OS caches are not flushed.',
  timingBoundary: 'Unchanged Phase8 worker: request wraps adapter.probe including lazy API loading; adapter import is outside request. Process wall includes startup, identity verification, and output capture.',
  order: ['baseline', 'candidate', 'candidate', 'baseline'], inputs: [], variants: {}, rows: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n'); save();
try {
  const binding = await bindCandidate(resolve(config.manifest)), {candidate, parent, add, inputs} = binding;
  const gateFile = resolve(config.gate), gate = JSON.parse(fs.readFileSync(gateFile));
  assert.equal(gate.kind, 'phase14-combined-dispatch-ablation-history-gate'); assert.ok(gate.complete && gate.pass && gate.inputsVerified);
  assert.deepEqual(gate.manifest, binding.manifest); assert.deepEqual(gate.baseline, parent.api); assert.deepEqual(gate.candidate, candidate.api);
  gate.inputs.forEach(verifyIdentity); add(gateFile); add(configFile); add(import.meta.filename);
  const source = resolve(config.source), bootstrap = JSON.parse(fs.readFileSync(parent.bootstrapReport.file));
  assert.equal(identity(source).sha256, identity(bootstrap.source).sha256, 'Pilot must check exact parent compiler source');
  report.source = add(source); report.config = identity(configFile); report.manifest = binding.manifest; report.gate = identity(gateFile);
  for (const row of [parent.bootstrapReport, ...parent.artifacts, ...parent.snapshot.sources.map(value => value.frozen)]) add(row.file);
  for (const file of ['bend.ts', 'comp.ts', 'main.ts', 'base.bend']) add(path.join(parent.config.upstream, 'bend2', file));
  const worker = path.join(out, 'worker.mjs'); fs.copyFileSync(new URL('../phase8/check-worker.mjs', import.meta.url), worker); add(worker);
  fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
  fs.copyFileSync(path.join(import.meta.dirname, '../phase14/dispatch-paired-inputs.mjs'), path.join(out, 'consumed-inputs.mjs'));
  for (const name of ['baseline', 'candidate']) {
    const v = gate.variants[name], api = name === 'baseline' ? parent.api : candidate.api;
    assert.deepEqual(v.api, api);
    const cache = validatedCache(path.join(v.project, 'build/typed/cache'), api.file, parent.base.file);
    assert.deepEqual(cache, v.cache); add(cache.file);
    for (const {frozen} of parent.snapshot.sources) {
      const copied = path.join(v.project, path.relative(parent.snapshot.root, frozen.file));
      if (fs.existsSync(copied)) {assert.equal(identity(copied).sha256, frozen.sha256); add(copied);}
    }
    report.variants[name] = {api, cache, adapter: v.adapter, project: v.project, artifactKind: name === 'baseline' ? parent.artifactKind : candidate.artifactKind};
  }
  report.inputs = [...inputs.values()]; const verify = () => report.inputs.forEach(verifyIdentity); save();
  for (const [index, name] of report.order.entries()) {
    verify(); const v = report.variants[name], prefix = path.join(out, `${index}-${name}`), workdir = prefix + '-work'; fs.mkdirSync(workdir);
    const request = {variant: name, source, api: v.api.file, base: parent.base.file, runtime: parent.runtime.file, upstream: parent.config.upstream, workdir, timeoutMs: 600000, adapter: v.adapter, inputs: report.inputs};
    const requestFile = prefix + '.request.json', resultFile = prefix + '.result.json'; fs.writeFileSync(requestFile, JSON.stringify(request, null, 2) + '\n', {flag: 'wx'});
    const execution = await supervise('taskset', ['-c', cpu, process.execPath, '--stack-size=4096', '--max-old-space-size=4096', worker, requestFile, resultFile], {directory: prefix + '-process', env: process.env, timeoutMs: 600000});
    const observation = fs.existsSync(resultFile) ? JSON.parse(fs.readFileSync(resultFile)) : null;
    report.rows.push({index, variant: name, execution, observation}); save(); requireExecution(execution);
    assert.equal(observation.pass, true); assert.equal(observation.inputsVerified, true); assert.equal(observation.affinity.split(':')[1].trim(), cpu);
    assert.equal(observation.result.typeAccepted, true); assert.equal(observation.result.proofTrust, 'failed'); assert.equal(observation.result.phase, 'verdict'); assert.equal(observation.result.exitCode, 1);
    if (index) assert.deepEqual(observation.result, report.rows[0].observation.result, 'Complete ordinary compiler result changed'); verify();
  }
  binding.replay(); gate.inputs.forEach(verifyIdentity);
  const mean = values => values.reduce((a, b) => a + b, 0) / values.length;
  report.statistics = Object.fromEntries(['baseline', 'candidate'].map(name => {
    const rows = report.rows.filter(row => row.variant === name); assert.equal(rows.length, 2);
    return [name, {samples: 2, meanRequestMs: mean(rows.map(row => row.observation.requestMs)), meanProcessWallMs: mean(rows.map(row => row.execution.wallMs)), maxRssKiB: Math.max(...rows.map(row => row.observation.maxRssKiB))}];
  }));
  const {baseline, candidate: result} = report.statistics;
  report.ratios = {baselineToCandidateProcess: baseline.meanProcessWallMs / result.meanProcessWallMs, processReduction: 1 - result.meanProcessWallMs / baseline.meanProcessWallMs, requestReduction: 1 - result.meanRequestMs / baseline.meanRequestMs};
  report.exactCompleteResults = true; report.inputsVerified = true; report.complete = true; report.pass = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
report.finished = new Date().toISOString(); save(); console.log(JSON.stringify({complete: report.complete, pass: report.pass, error: report.error, ratios: report.ratios}));
