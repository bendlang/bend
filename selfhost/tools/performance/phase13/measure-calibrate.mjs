// Reuse the proven Phase12 replay without rewriting its historical evidence.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity, verifyIdentity, verifyAttempt, validatedCache} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

const repo = path.resolve(import.meta.dirname, '../../../..');
const out = path.resolve(process.argv[2]), cpu = process.argv[3] ?? '3';
assert.equal(process.cwd(), repo, 'Historical tool requires repository-root cwd');
assert.equal(cpu, '3', 'The unchanged predecessor also declares CPU3');
assert.equal(process.version, 'v24.18.0');
fs.mkdirSync(out);
const attempt = path.join(repo, 'selfhost/build/phase12/integrated-03');
const m = await verifyAttempt(attempt);
assert.equal(m.api.sha256, '0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697');
const originalTool = path.join(repo, 'selfhost/tools/performance/phase12/call-prefix-noseed.mjs');
const cases = [
  {name: 'history-53', request: 'frontend-02/candidate.json.artifacts/477/request.json', previous: 'call-leaf-noseed-prefix-01/report.json', count: 53},
  {name: 'history-60', request: 'call-prefix-input-01/phase11-passing-request.json', previous: 'call-leaf-noseed-prefix-02/report.json', count: 60},
];
const files = new Map(), add = file => { const row = identity(file); files.set(row.file, row); return row; };
for (const file of [import.meta.filename, process.execPath, originalTool, path.join(attempt, 'attempt.json'), m.api.file, m.runtime.file, m.base.file]) add(file);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
fs.copyFileSync(originalTool, path.join(out, 'consumed-phase12-prefix-tool.mjs'));
for (const item of cases) {
  item.request = path.join(repo, 'selfhost/build/phase12', item.request);
  item.previous = path.join(repo, 'selfhost/build/phase12', item.previous);
  add(item.request); add(item.previous);
  const previous = JSON.parse(fs.readFileSync(item.previous));
  const oldTool = previous.inputs.find(row => row.file === originalTool);
  assert.equal(oldTool?.sha256, identity(originalTool).sha256, 'Historical launcher bytes changed');
  assert.ok(previous.complete && previous.inputsVerified);
  assert.equal(previous.rows.length, 1);
  assert.equal(previous.rows[0].requests.length, item.count);
}
const project = path.join(out, 'fresh-project'); fs.mkdirSync(project);
for (const name of ['src', 'tools']) fs.cpSync(path.join(m.snapshot.root, name), path.join(project, name), {recursive: true});
const sourceCache = validatedCache(path.join(m.snapshot.root, 'build/typed/cache'), m.api.file, m.base.file);
const cacheDir = path.join(project, 'build/typed/cache'); fs.mkdirSync(cacheDir, {recursive: true});
fs.copyFileSync(sourceCache.file, path.join(cacheDir, path.basename(sourceCache.file)));
const cache = validatedCache(cacheDir, m.api.file, m.base.file);
add(sourceCache.file); add(cache.file);
for (const {frozen} of m.snapshot.sources) {
  const relative = path.relative(m.snapshot.root, frozen.file), copied = path.join(project, relative);
  if (!fs.existsSync(copied)) continue;
  assert.equal(identity(copied).sha256, frozen.sha256, 'Copied host drift'); add(copied);
}
const report = {kind: 'phase13-current-baseline-stack-calibration', complete: false, pass: false,
  scope: 'Fresh string plus exact released Phase12 53/60 histories. Correctness calibration only; inherited tool timings are not performance samples.',
  api: m.api, attempt: identity(path.join(attempt, 'attempt.json')), cpu, node: identity(process.execPath),
  resources: {stackKiB: 4096, heapMiB: 4096, requestDeadlineMs: 30000, recycleAfter: 64, rssLimitMiB: 4096},
  cache, inputs: [...files.values()], steps: [], histories: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const verify = () => report.inputs.forEach(verifyIdentity);
save();
async function run(name, args, env, timeoutMs) {
  verify();
  const execution = await supervise('taskset', ['-c', cpu, process.execPath, ...args], {directory: path.join(out, name), env, timeoutMs});
  report.steps.push({name, execution}); save(); requireExecution(execution); verify();
}
try {
  const env = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('BEND_') && !['NODE_OPTIONS', 'NODE_PATH'].includes(key)));
  Object.assign(env, {BEND_TYPED_API: m.api.file, BEND_TYPED_RUNTIME: m.runtime.file, BEND_BASE: m.base.file, BEND_UPSTREAM: m.config.upstream, BEND_TYPED_TRACE: '1'});
  const fresh = path.join(out, 'fresh.json');
  await run('fresh-process', [path.join(project, 'tools/conformance/run.mjs'), '--upstream', m.config.upstream,
    '--adapter', path.join(project, 'tools/conformance/adapters/typed.mjs'), '--output', fresh,
    '--jobs', '1', '--timeout', '30000', '--worker-mode', 'isolated', '--lanes', 'check',
    '--filter', '^check/string_literal_long\\.bend$', '--stack-kb', '4096', '--heap-mb', '4096', '--retain', 'all', '--selected-exit', '1'], env, 60000);
  const observed = JSON.parse(fs.readFileSync(fresh));
  assert.equal(observed.results.length, 1); assert.equal(observed.results[0].status, 'pass');
  assert.equal(observed.results[0].result.phase, 'check'); assert.equal(observed.results[0].result.typeAccepted, true);
  assert.equal(observed.results[0].result.proofTrust, 'passed');
  assert.equal(observed.changedInputs.length, 0); assert.equal(observed.identity.changedArtifacts.length, 0);
  assert.equal(observed.identity.adapterChangedDuringRun, false);
  report.fresh = {report: identity(fresh), observation: observed.results[0]}; save();
  for (const item of cases) {
    const directory = path.join(out, item.name);
    await run(item.name + '-process', [originalTool, item.request, directory, 'leaf'], env, 300000);
    const current = JSON.parse(fs.readFileSync(path.join(directory, 'report.json'))), previous = JSON.parse(fs.readFileSync(item.previous));
    assert.ok(current.complete && current.inputsVerified); assert.equal(current.rows.length, 1);
    const row = current.rows[0]; assert.equal(row.requests.length, item.count); assert.ok(row.complete && row.prefixExact);
    const comparisons = row.requests.map((request, index) => ({index, id: request.id, lane: request.lane,
      historicalDigest: request.originalResultDigest, currentDigest: request.resultDigest,
      phase12Digest: previous.rows[0].requests[index].resultDigest,
      exactPhase12: JSON.stringify(request.result) === JSON.stringify(previous.rows[0].requests[index].result),
      exactHistorical: request.exactOriginal}));
    report.histories.push({name: item.name, report: identity(path.join(directory, 'report.json')), original: current.original, comparisons}); save();
    assert.ok(comparisons.every(value => value.exactPhase12), 'Released Phase12 history changed');
    assert.equal(row.target.result.status, 'ok'); assert.equal(row.target.result.phase, 'check');
    assert.equal(row.target.result.typeAccepted, true); assert.equal(row.target.result.proofTrust, 'passed');
  }
  verify(); await verifyAttempt(attempt); report.complete = true; report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, histories: report.histories.map(row => ({name: row.name, requests: row.comparisons.length}))}));
