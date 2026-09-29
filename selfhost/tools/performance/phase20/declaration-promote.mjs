// One-file declaration checkpoint release; frozen focused manifest plus broad audit.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';
const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const phase = path.join(project, 'build/phase20');
const [manifestArg, outArg] = process.argv.slice(2);
const manifestFile = fs.realpathSync(manifestArg), out = path.resolve(outArg);
const read = p => JSON.parse(fs.readFileSync(p));
const manifest = read(manifestFile);
fs.mkdirSync(out); fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind: 'phase20-declaration-checkpoints-installation', complete: false, pass: false,
  started: new Date().toISOString(), inputs: [identity(import.meta.filename), identity(manifestFile)], copies: [],
  scope: 'One reviewed declaration module; same checked lineage workflow, host, runtime and Base. Contextual parser remains private. Separate cost screen; no new fixed-point claim.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  const previous = 'a15d150a920b89d9c0781372356424e559edabef3246ca281741069b0fe739b6';
  const old = await verifyAttempt(path.join(project, 'build/phase19/instance-build-03'));
  const m = await verifyAttempt(manifest.attempt);
  assert.equal(old.api.sha256, previous); assert.equal(m.api.sha256, manifest.expectedApi);
  assert.equal(m.base.sha256, old.base.sha256); assert.equal(m.runtime.sha256, old.runtime.sha256);
  assert.equal(m.config.upstream, old.config.upstream);
  for (const x of manifest.gates) {
    verifyIdentity(x); const gate = read(x.file);
    assert.equal(gate.complete, true, x.file); assert.equal(gate.pass, true, x.file);
    assert.equal(gate.api.sha256, m.api.sha256, x.file);
    report.inputs.push(identity(x.file));
  }
  assert.deepEqual(manifest.gates.map(x => path.relative(phase, x.file)).sort(), [
    'import-diagnostic-build-04/validation-001/report.json',
    'import-diagnostic-first-focused-04/report.json', 'import-diagnostic-type-focused-04/report.json',
    'import-diagnostic-brace-focused-04/report.json', 'import-diagnostic-focused-04/report.json',
    'import-diagnostic-supplied-04/report.json', 'import-diagnostic-host-04/report.json',
    'declaration-programs-01/report.json'].sort());
  verifyIdentity(manifest.owner); const owner = read(manifest.owner.file);
  assert.ok(owner.complete && owner.pass); assert.equal(owner.api.sha256, m.api.sha256);
  for (const x of owner.inputs) { verifyIdentity(x); report.inputs.push(identity(x.file)); }
  report.inputs.push(identity(manifest.owner.file));
  const auditFile = path.join(phase, 'declaration-integration-audit-03/report.json'), audit = read(auditFile);
  assert.ok(audit.complete && audit.pass); assert.equal(audit.api.sha256, m.api.sha256);
  assert.equal(audit.frontend.observations, 2996); assert.deepEqual(audit.frontend.changes, []);
  assert.equal(audit.groups.afterExact, 136); assert.deepEqual(audit.groups.lost, []);
  audit.inputs.forEach(verifyIdentity); report.inputs.push(identity(auditFile));
  verifyIdentity(manifest.review); const review = read(manifest.review.file);
  assert.ok(review.complete && review.pass); report.inputs.push(identity(manifest.review.file));
  // The review must name the final candidate bytes, in addition to its earlier ablation.
  assert.ok(JSON.stringify(review).includes(m.api.sha256), 'Final candidate absent from independent review');
  for (const x of review.inputs ?? []) verifyIdentity(x);
  const matrixFile = path.join(phase, 'declaration-matrix-01/report.json'), matrix = read(matrixFile);
  assert.ok(matrix.complete && !matrix.error && matrix.unsafeDefinitionSetsAgree);
  assert.equal(matrix.variants.candidate.api.sha256, m.api.sha256);
  assert.equal(matrix.variants.baseline.api.sha256, previous);
  assert.equal(matrix.hostDelta.changed, false); assert.equal(matrix.rows.length, 6);
  assert.ok(matrix.ratios.candidateProcessReduction >= -0.05, 'Investigate process regression above 5%');
  matrix.inputs.forEach(verifyIdentity); report.inputs.push(identity(matrixFile));
  report.previous = verifyRelease(project);
  assert.equal(report.previous.files.find(x => x.path === 'dist/typed-api.mjs').sha256, previous);
  const protectedFiles = read(path.join(project, 'build/phase16/start-state.json')).unrelatedPhase6;
  const checkProtected = () => protectedFiles.forEach(x => {
    assert.equal(identity(path.join(repo, x.path)).sha256, x.sha256);
    assert.equal(execFileSync('git', ['status', '--porcelain=v1', '--untracked-files=all', '--', x.path], {cwd: repo, encoding: 'utf8'}).slice(0, 2), x.status);
  });
  checkProtected();
  const inventory = a => new Map(a.snapshot.sources.map(({frozen}) => [path.relative(a.snapshot.root, frozen.file), frozen]));
  const before = inventory(old), after = inventory(m);
  assert.equal(before.size, 214); assert.deepEqual([...before.keys()].sort(), [...after.keys()].sort());
  for (const [name, x] of before) assert.equal(identity(path.join(project, name)).sha256, x.sha256, name);
  const changes = [...after].filter(([name, x]) => x.sha256 !== before.get(name).sha256);
  assert.deepEqual(changes.map(([name]) => name), ['src/front/declarations.bend']);
  for (const [relative, source] of changes) {
    const live = path.join(project, relative), backup = path.join(out, 'source-before', relative);
    fs.mkdirSync(path.dirname(backup), {recursive: true}); fs.copyFileSync(live, backup); fs.copyFileSync(source.file, live);
    report.copies.push({relative, before: before.get(relative), source, backup: identity(backup), after: identity(live)});
  }
  save(); report.installed = await installAttempt(manifest.attempt); report.release = verifyRelease(project);
  assert.equal(report.release.files.find(x => x.path === 'dist/typed-api.mjs').sha256, m.api.sha256);
  report.inputs.forEach(verifyIdentity); checkProtected(); report.complete = report.pass = true;
} catch (e) { report.error = String(e.stack ?? e); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, copies: report.copies.length, error: report.error}));
