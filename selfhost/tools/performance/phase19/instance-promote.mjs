// Install the coherent live checker after exact semantic, execution, history and cost gates.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';

const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const phase = path.join(project, 'build/phase19'), out = path.join(phase, 'instance-promotion-01');
const expected = 'a15d150a920b89d9c0781372356424e559edabef3246ca281741069b0fe739b6';
const previous = '66d6ce45c0c6ea8947190ff210274f1e6f0c7bf85f7ad3f215076f8820acd7c7';
const read = file => JSON.parse(fs.readFileSync(file));
const verifyRecorded = x => { assert.equal(identity(x.file ?? path.join(repo, x.path)).sha256, x.sha256, x.file ?? x.path); };
fs.mkdirSync(out); fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind: 'phase19-live-checker-installation', complete: false, pass: false,
  started: new Date().toISOString(), expectedApi: expected, inputs: [identity(import.meta.filename)], copies: [],
  scope: 'Shared live-instance checking and checked output; six reviewed source files. Contextual parser remains uninstalled. No new fixed-point or generated-code speed claim.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  const attempt = path.join(phase, 'instance-build-03'), m = await verifyAttempt(attempt);
  const old = await verifyAttempt(path.join(phase, 'prefix-build-01'));
  assert.equal(m.api.sha256, expected); assert.equal(old.api.sha256, previous);
  assert.equal(m.base.sha256, old.base.sha256); assert.equal(m.runtime.sha256, old.runtime.sha256);
  const gate = name => {
    const file = path.join(phase, name), value = read(file);
    assert.equal(value.complete, true, name); assert.equal(value.pass, true, name);
    (value.inputs ?? []).forEach(verifyRecorded); report.inputs.push(identity(file)); return value;
  };
  gate('instance-build-03/validation-001/report.json');
  const frontend = gate('instance-frontend-01/report.json');
  assert.equal(frontend.api.sha256, expected); assert.equal(frontend.exact.after, 2);
  assert.deepEqual(frontend.sincePrevious.lost, []); assert.deepEqual(frontend.unexpected, []);
  for (const name of ['instance-paired-02', 'instance-let-paired-03',
    'instance-recursion-paired-01', 'instance-memo-02', 'instance-backend-01',
    'instance-literal-execution-01', 'instance-helper-01']) {
    const r = gate(name + '/report.json'); assert.equal(r.api.sha256, expected, name);
  }
  for (const name of ['instance-key61-01', 'instance-direct-02']) {
    const r = gate(name + '/report.json'); assert.equal(r.productionAPI.sha256, expected, name);
  }
  gate('instance-parsed29-01/report.json');
  const boundary = gate('instance-boundary-candidate-03/result/report.json');
  assert.equal(boundary.api.sha256, expected); assert.equal(boundary.rows.length, 104);
  const history = gate('instance-history-01/report.json');
  assert.equal(history.baseline.sha256, previous); assert.equal(history.candidate.sha256, expected);
  assert.equal(history.exactPairedCompleteResults, true);
  const sameFile = path.join(phase, 'instance-frontend-parent-comparison-01.json'), same = read(sameFile);
  assert.ok(same.complete && same.pass); assert.equal(same.observations, 2996);
  assert.deepEqual(same.changes, []); assert.deepEqual(same.missing, []); assert.deepEqual(same.extra, []);
  same.inputs.forEach(verifyRecorded); report.inputs.push(identity(sameFile));
  // The unchanged public18 historical oracle has six deliberate differences:
  // eager instance checking and completion-order publication. Keep its raw fail.
  const publicFile = path.join(phase, 'instance-public18-01/report.json'), pub = read(publicFile);
  assert.ok(pub.complete); assert.equal(pub.pass, false); assert.equal(pub.rows.length, 18);
  assert.equal(pub.rows.filter(r => r.pass).length, 12);
  pub.inputs.forEach(verifyRecorded); report.inputs.push(identity(publicFile));
  const timingFile = path.join(phase, 'instance-matrix-01/report.json'), timing = read(timingFile);
  assert.ok(timing.complete && !timing.error && timing.unsafeDefinitionSetsAgree);
  assert.equal(timing.rows.length, 6); assert.equal(timing.variants.candidate.api.sha256, expected);
  assert.equal(timing.variants.baseline.api.sha256, previous); assert.equal(timing.hostDelta.changed, false);
  assert.ok(timing.ratios.candidateProcessReduction >= -0.05, 'Investigate cost regression above 5%');
  timing.inputs.forEach(verifyIdentity); report.inputs.push(identity(timingFile));
  report.previous = verifyRelease(project);
  assert.equal(report.previous.files.find(x => x.path === 'dist/typed-api.mjs').sha256, previous);
  const unrelated = read(path.join(project, 'build/phase16/start-state.json')).unrelatedPhase6;
  const verifyUnrelated = () => unrelated.forEach(x => {
    assert.equal(identity(path.join(repo, x.path)).sha256, x.sha256);
    assert.equal(execFileSync('git', ['status', '--porcelain=v1', '--untracked-files=all', '--', x.path], {cwd: repo, encoding: 'utf8'}).slice(0, 2), x.status);
  });
  verifyUnrelated();
  const inventory = x => new Map(x.snapshot.sources.map(({frozen}) => [path.relative(x.snapshot.root, frozen.file), frozen]));
  const a = inventory(old), b = inventory(m);
  assert.equal(a.size, 214); assert.deepEqual([...a.keys()].sort(), [...b.keys()].sort());
  for (const [name, before] of a) assert.equal(identity(path.join(project, name)).sha256, before.sha256, name);
  const changes = [...b].filter(([name, after]) => after.sha256 !== a.get(name).sha256);
  assert.deepEqual(changes.map(([name]) => name).sort(), ['src/check/annotate.bend', 'src/check/kernel.bend', 'src/check/specialize.bend', 'src/diagnostic/produce.bend', 'src/diagnostic/trace.bend', 'src/driver/api.bend']);
  for (const [relative, source] of changes) {
    const live = path.join(project, relative), backup = path.join(out, 'source-before', relative);
    fs.mkdirSync(path.dirname(backup), {recursive: true}); fs.copyFileSync(live, backup); fs.copyFileSync(source.file, live);
    report.copies.push({relative, before: a.get(relative), backup: identity(backup), source, after: identity(live)});
  }
  save(); report.installed = await installAttempt(attempt); report.release = verifyRelease(project);
  assert.equal(report.release.files.find(x => x.path === 'dist/typed-api.mjs').sha256, expected);
  report.inputs.forEach(verifyIdentity); verifyUnrelated(); report.complete = report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, copies: report.copies.length, error: report.error}));
