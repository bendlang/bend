// Promote only the one-file lookup worker after its exact image gates.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';

const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const phase = path.join(project, 'build/phase17'), out = path.join(phase, 'find-worker-promotion-01');
const expected = '9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6';
const previous = '35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315';
const read = file => JSON.parse(fs.readFileSync(file));
const verifyRecorded = item => {
  const actual = identity(item.file);
  assert.equal(actual.sha256, item.sha256, item.file);
  if (item.canonicalPath !== undefined) assert.equal(actual.canonicalPath, item.canonicalPath);
  if (item.bytes !== undefined) assert.equal(fs.statSync(item.file).size, item.bytes);
};
fs.mkdirSync(out); fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind: 'phase17-lookup-worker-installation', complete: false, pass: false,
  started: new Date().toISOString(), expectedApi: expected, inputs: [identity(import.meta.filename)],
  copies: [], scope: 'One frontend lookup worker; source/runtime/host membership verified. Known conformance gaps remain. No new fixed-point, kernel or emitted-program runtime claim.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  const attempt = path.join(phase, 'find-worker-build-01');
  const m = await verifyAttempt(attempt);
  const old = await verifyAttempt(path.join(project, 'build/phase16/compact-final-build-01'));
  assert.equal(m.api.sha256, expected); assert.equal(old.api.sha256, previous);
  assert.equal(m.runtime.sha256, old.runtime.sha256); assert.equal(m.base.sha256, old.base.sha256);
  const gates = ['find-worker-build-01/validation-001', 'find-worker-frontend-01',
    'find-worker-backend-01', 'find-worker-history-01', 'find-worker-helper-01',
    'find-worker-standalone-01', 'find-worker-context-supplied-01', 'find-worker-context-host-01',
    'find-demand-01'];
  const results = {};
  for (const name of gates) {
    const file = path.join(phase, name, 'report.json'), gate = read(file);
    assert.equal(gate.complete, true, name); assert.equal(gate.pass, true, name);
    (gate.inputs ?? []).forEach(verifyRecorded);
    // Every named gate binds the final API either directly or through its inputs/lanes.
    assert.ok(JSON.stringify(gate).includes(expected), 'Final image missing: ' + name);
    results[name] = gate; report.inputs.push(identity(file));
  }
  const frontend = results['find-worker-frontend-01'];
  assert.equal(frontend.api.sha256, expected); assert.equal(frontend.exact.after, 2);
  assert.deepEqual(frontend.sincePrevious.lost, []); assert.deepEqual(frontend.unexpected, []);
  const history = results['find-worker-history-01'];
  assert.equal(history.candidate.sha256, expected); assert.equal(history.exactPairedCompleteResults, true);
  assert.deepEqual(history.histories.map(h => h.rows.map(r => r.requests.length)), [[53, 53], [60, 60]]);
  const demand = results['find-demand-01'];
  assert.equal(demand.lanes.find(x => x.label === 'candidate').api.sha256, expected);
  assert.equal(demand.comparisons.length, 23);
  const timingFile = path.join(phase, 'find-worker-matrix-01/report.json'), timing = read(timingFile);
  assert.ok(timing.complete && !timing.error && timing.unsafeDefinitionSetsAgree);
  assert.equal(timing.rows.length, 6); assert.ok(timing.ratios.candidateProcessReduction > 0.03);
  assert.equal(timing.variants.candidate.api.sha256, expected);
  assert.equal(timing.variants.baseline.api.sha256, previous);
  assert.equal(timing.hostDelta.changed, false); timing.inputs.forEach(verifyIdentity);
  report.inputs.push(identity(timingFile));
  report.previous = verifyRelease(project);
  assert.equal(report.previous.files.find(f => f.path === 'dist/typed-api.mjs').sha256, previous);
  const unrelated = read(path.join(project, 'build/phase16/start-state.json')).unrelatedPhase6;
  const verifyUnrelated = () => unrelated.forEach(x => assert.equal(identity(path.join(repo, x.path)).sha256, x.sha256));
  verifyUnrelated();
  const inventory = manifest => new Map(manifest.snapshot.sources.map(({frozen}) =>
    [path.relative(manifest.snapshot.root, frozen.file), frozen]));
  const a = inventory(old), b = inventory(m);
  assert.equal(a.size, 214); assert.deepEqual([...a.keys()].sort(), [...b.keys()].sort());
  for (const [relative, before] of a) assert.equal(identity(path.join(project, relative)).sha256, before.sha256, relative);
  const changed = [...b].filter(([name, item]) => item.sha256 !== a.get(name).sha256);
  assert.deepEqual(changed.map(([name]) => name), ['src/front/declarations.bend']);
  for (const [relative, source] of changed) {
    const live = path.join(project, relative), backup = path.join(out, 'source-before', relative);
    fs.mkdirSync(path.dirname(backup), {recursive: true}); fs.copyFileSync(live, backup);
    fs.copyFileSync(source.file, live);
    report.copies.push({relative, before: a.get(relative), backup: identity(backup), source, after: identity(live)});
  }
  save();
  report.installed = await installAttempt(attempt);
  report.release = verifyRelease(project);
  assert.equal(report.release.files.find(f => f.path === 'dist/typed-api.mjs').sha256, expected);
  report.inputs.forEach(verifyIdentity); verifyUnrelated();
  report.complete = report.pass = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, copies: report.copies.length, error: report.error}));
