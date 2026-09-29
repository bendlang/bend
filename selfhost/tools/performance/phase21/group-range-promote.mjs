// Install only the reviewed three-file origin correction after scoped gates.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {identity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';

const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const [manifestArg, outArg] = process.argv.slice(2);
const manifestFile = fs.realpathSync(manifestArg), out = path.resolve(outArg);
const read = p => JSON.parse(fs.readFileSync(p));
const manifest = read(manifestFile);
fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind: 'phase21-local-origins-installation', complete: false, pass: false,
  started: new Date().toISOString(), copies: [], inputs: [identity(import.meta.filename), identity(manifestFile)]};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const verify = x => {
  const actual = identity(x.file);
  assert.equal(actual.sha256, x.sha256, x.file);
  if ('canonicalPath' in x) assert.equal(actual.canonicalPath, x.canonicalPath, x.file);
  if ('bytes' in x) assert.equal(fs.statSync(x.file).size, x.bytes, x.file);
};
save();
try {
  const old = await verifyAttempt(path.join(project, 'build/phase20/import-diagnostic-build-04'));
  const current = await verifyAttempt(manifest.attempt);
  assert.equal(old.api.sha256, '40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c');
  assert.equal(current.api.sha256, manifest.expectedApi);
  assert.equal(current.base.sha256, old.base.sha256);
  assert.equal(current.runtime.sha256, old.runtime.sha256);
  assert.equal(current.config.upstream, old.config.upstream);
  for (const x of manifest.gates) {
    verify(x);
    const gate = read(x.file);
    const passField = x.passField ?? 'pass';
    assert.ok(['pass', 'boundedStructureGatePass', 'boundedGateApproved'].includes(passField));
    assert.ok(gate.complete && gate[passField], x.file);
    assert.ok(JSON.stringify(gate).includes(current.api.sha256), 'Final API absent: ' + x.file);
    for (const input of gate.inputs ?? []) verify(input);
    report.inputs.push(identity(x.file));
  }
  assert.equal(manifest.gates.length, 7);
  const audit = read(manifest.integration.file); verify(manifest.integration);
  assert.ok(audit.complete && audit.pass);
  assert.equal(audit.api.sha256, current.api.sha256);
  assert.deepEqual(audit.frontend.changes, []);
  assert.equal(audit.groups.beforeExact, 136);
  assert.equal(audit.groups.afterExact, 139);
  assert.deepEqual(audit.groups.lost, []);
  audit.inputs.forEach(verify); report.inputs.push(identity(manifest.integration.file));
  const matrix = read(manifest.matrix.file); verify(manifest.matrix);
  assert.ok(matrix.complete && !matrix.error && matrix.unsafeDefinitionSetsAgree);
  assert.equal(matrix.variants.baseline.api.sha256, old.api.sha256);
  assert.equal(matrix.variants.candidate.api.sha256, current.api.sha256);
  assert.equal(matrix.hostDelta.changed, false);
  assert.equal(matrix.rows.length, 6);
  assert.ok(matrix.ratios.candidateProcessReduction >= -0.05, 'Investigate slowdown above5%');
  matrix.inputs.forEach(verify); report.inputs.push(identity(manifest.matrix.file));
  report.previous = verifyRelease(project);
  assert.equal(report.previous.files.find(x => x.path === 'dist/typed-api.mjs').sha256, old.api.sha256);
  const protectedFiles = read(path.join(project, 'build/phase21/group-start-state-01.json')).unrelatedPhase6;
  const checkProtected = () => protectedFiles.forEach(x => {
    assert.equal(identity(path.join(repo, x.path)).sha256, x.sha256);
    assert.equal(execFileSync('git', ['status', '--porcelain=v1', '--untracked-files=all', '--', x.path],
      {cwd: repo, encoding: 'utf8'}).slice(0, 2), x.status);
  });
  checkProtected();
  const inventory = m => new Map(m.snapshot.sources.map(({frozen}) => [path.relative(m.snapshot.root, frozen.file), frozen]));
  const before = inventory(old), after = inventory(current);
  assert.equal(before.size, 214);
  assert.deepEqual([...before.keys()].sort(), [...after.keys()].sort());
  for (const [name, item] of before) assert.equal(identity(path.join(project, name)).sha256, item.sha256, name);
  const changes = [...after].filter(([name, item]) => before.get(name).sha256 !== item.sha256);
  assert.deepEqual(changes.map(([name]) => name).sort(), ['src/front/declarations.bend', 'src/front/parallel.bend', 'src/front/sugar.bend']);
  for (const [relative, source] of changes) {
    const live = path.join(project, relative), backup = path.join(out, 'source-before', relative);
    fs.mkdirSync(path.dirname(backup), {recursive: true}); fs.copyFileSync(live, backup);
    fs.copyFileSync(source.file, live);
    report.copies.push({relative, before: before.get(relative), source, backup: identity(backup), after: identity(live)});
  }
  save();
  report.installed = await installAttempt(manifest.attempt);
  report.release = verifyRelease(project);
  assert.equal(report.release.files.find(x => x.path === 'dist/typed-api.mjs').sha256, current.api.sha256);
  for (const [name, item] of after) assert.equal(identity(path.join(project, name)).sha256, item.sha256, name);
  checkProtected(); report.inputs.forEach(verify);
  report.complete = report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, copies: report.copies.length, error: report.error}));
