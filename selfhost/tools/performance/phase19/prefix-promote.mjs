// Install only the isolated exact-prefix correction after its named gates.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';

const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const phase = path.join(project, 'build/phase19'), out = path.join(phase, 'prefix-promotion-01');
const expected = '66d6ce45c0c6ea8947190ff210274f1e6f0c7bf85f7ad3f215076f8820acd7c7';
const previous = '9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6';
const read = file => JSON.parse(fs.readFileSync(file));
const verifyRecorded = x => { assert.equal(identity(x.file).sha256, x.sha256, x.file); };
fs.mkdirSync(out); fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind: 'phase19-exact-prefix-installation', complete: false, pass: false,
  started: new Date().toISOString(), expectedApi: expected, inputs: [identity(import.meta.filename)], copies: [],
  scope: 'Two-line cached-prefix syntax correction; no live-checker/parser prototype installed. No new fixed-point or generated-code speed claim.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  const attempt = path.join(phase, 'prefix-build-01'), m = await verifyAttempt(attempt);
  const old = await verifyAttempt(path.join(project, 'build/phase17/find-worker-build-01'));
  assert.equal(m.api.sha256, expected); assert.equal(old.api.sha256, previous);
  assert.equal(m.base.sha256, old.base.sha256); assert.equal(m.runtime.sha256, old.runtime.sha256);
  const gate = name => {
    const file = path.join(phase, name), value = read(file);
    assert.equal(value.complete, true, name); assert.equal(value.pass, true, name);
    (value.inputs ?? []).forEach(verifyRecorded); report.inputs.push(identity(file)); return value;
  };
  gate('prefix-build-01/validation-001/report.json');
  const frontend = gate('prefix-frontend-01/report.json');
  assert.equal(frontend.api.sha256, expected); assert.equal(frontend.exact.after, 2);
  assert.deepEqual(frontend.sincePrevious.lost, []); assert.deepEqual(frontend.unexpected, []);
  const exact = gate('instance-boundary-exact-candidate-01/result/report.json');
  assert.equal(exact.api.sha256, expected); assert.equal(exact.rows.length, 12);
  assert.ok(exact.rows.every(x => x.pass));
  const proof = gate('instance-boundary-proof-candidate-01/result/report.json');
  assert.equal(proof.api.sha256, expected); assert.equal(proof.acceptedInvalidCachedProof, false);
  assert.equal(proof.results.changedExactPrefix, false);
  const parentProofFile = path.join(phase, 'instance-boundary-proof-parent-01/result/report.json');
  const parentProof = read(parentProofFile); assert.equal(parentProof.complete, true);
  assert.equal(parentProof.api.sha256, previous); assert.equal(parentProof.acceptedInvalidCachedProof, true);
  parentProof.inputs.forEach(verifyRecorded); report.inputs.push(identity(parentProofFile));
  const sameFile = path.join(phase, 'prefix-frontend-parent-comparison-01.json'), same = read(sameFile);
  assert.deepEqual(same.changes, []); assert.deepEqual(same.missing, []); report.inputs.push(identity(sameFile));
  const timingFile = path.join(phase, 'prefix-matrix-01/report.json'), timing = read(timingFile);
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
  assert.deepEqual(changes.map(([name]) => name), ['src/check/prefix.bend']);
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
