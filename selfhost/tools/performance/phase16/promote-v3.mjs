// Install the exact gated compact-term image; preserve the previous release.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';

const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const phase = path.join(project, 'build/phase16'), out = path.join(phase, 'promotion-03');
const expected = '35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315';
const previous = 'b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d';
const read = file => JSON.parse(fs.readFileSync(file));
// Some independent gates record SHA/file without a canonical-path claim.
// Verify every field actually recorded; never edit their original manifests.
function verifyRecorded(item) {
  const actual = identity(item.file);
  assert.equal(actual.sha256, item.sha256, item.file);
  if (item.canonicalPath !== undefined) assert.equal(actual.canonicalPath, item.canonicalPath, item.file);
  if (item.bytes !== undefined) assert.equal(fs.statSync(item.file).size, item.bytes, item.file);
}
fs.mkdirSync(out); fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind: 'phase16-gated-compact-release-installation', complete: false, pass: false,
  started: new Date().toISOString(), expectedApi: expected, inputs: [identity(import.meta.filename)],
  copies: [], knownScope: 'Two main frontend diagnostic differences and enumerated independent-control gaps remain; no full-conformance, new fixed-point or kernel claim.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  const priorFailure = path.join(phase, 'promotion-01/report.json');
  const prior = read(priorFailure); assert.equal(prior.copies.length, 0);
  report.inputs.push(identity(priorFailure));
  report.correctedSetup = 'Previous setup applied a canonicalPath-required verifier to SHA/file-only gate identities; all original bytes match. No source was copied by the failed attempt.';
  const attempt = path.join(phase, 'compact-final-build-01');
  const m = await verifyAttempt(attempt), old = await verifyAttempt(path.join(project, 'build/phase15/combined-02'));
  assert.equal(m.api.sha256, expected); assert.equal(old.api.sha256, previous);
  const gates = ['compact-final-build-01/validation-001', 'compact-final-frontend-01',
    'compact-final-checks-01', 'compact-final-helper-01', 'compact-final-standalone-01',
    'compact-final-history-01', 'compact-final-context-supplied-01', 'compact-final-context-host-01',
    'compact-final-context-namespace-01', 'compact-final-term-host-01', 'compact-final-program-host-01',
    'marked-pattern-integrated-demand-01',
    'checker-compact-final-backend-01', 'checker-compact-final-execution-01',
    'checker-compact-final-growth-01', 'checker-compact-final-literals-01',
    'checker-compact-final-instances-01', 'checker-compact-final-key-direct-01'];
  for (const name of gates) {
    const file = path.join(phase, name, 'report.json'), gate = read(file);
    assert.equal(gate.complete, true, name); assert.equal(gate.pass, true, name);
    if (gate.inputs) gate.inputs.forEach(verifyRecorded);
    report.inputs.push(identity(file));
  }
  // This known partial suite intentionally retains the same main-corpus failure.
  // Its raw oracle remains failed; require the separate prospective preservation gate.
  const partialFile = path.join(phase, 'marked-pattern-integrated-01/report.json');
  const partial = read(partialFile); assert.equal(partial.complete, true);
  assert.equal(partial.pass, false); partial.inputs.forEach(verifyRecorded);
  const vectorFile = path.join(phase, 'marked-pattern-integrated-01/selected/candidate.json');
  const vector = read(vectorFile); assert.equal(vector.results.length, 114);
  const failures = vector.results.filter(r => r.status === 'fail').map(r => ({id:r.id,lane:r.lane}));
  assert.deepEqual(failures, [{id:'check/monad_do_destructure.bend',lane:'check'}]);
  const auditFile = path.join(phase, 'marked-pattern-integration-audit-01.json'), audit = read(auditFile);
  assert.ok(audit.complete && audit.pass); audit.identities.forEach(verifyRecorded);
  assert.equal(audit.observations, 114); assert.equal(audit.beforeExact, 71); assert.equal(audit.afterExact, 71);
  for (const key of ['lostExact','changedOutcomes','primitiveChanges']) assert.deepEqual(audit[key], []);
  for (const side of ['reference','candidate']) for (const worker of partial[side].workers) {
    assert.deepEqual(worker.errors, []); assert.equal(worker.stats.failures, 0); assert.equal(worker.stats.timeouts, 0);
  }
  report.partialConformance = {rawOraclePass:false, observations:114, exact:71, strictDifferences:43,
    rawFailures:failures, noRegressionAudit:identity(auditFile), scope:'Known monad diagnostic gap remains; no full selected-conformance claim.'};
  for (const file of [partialFile,vectorFile,auditFile,path.join(phase,'promotion-02/report.json')]) report.inputs.push(identity(file));
  const frontend = read(path.join(phase, 'compact-final-frontend-01/report.json'));
  assert.equal(frontend.api.sha256, expected); assert.equal(frontend.exact.after, 2);
  assert.equal(frontend.exact.regressed, 0); assert.deepEqual(frontend.unexpected, []);
  const history = read(path.join(phase, 'compact-final-history-01/report.json'));
  assert.equal(history.candidate.sha256, expected); assert.equal(history.exactPairedCompleteResults, true);
  assert.deepEqual(history.histories.map(h => h.rows.map(r => r.requests.length)), [[53, 53], [60, 60]]);
  const timingFile = path.join(phase, 'compact-final-matrix-01/report.json'), timing = read(timingFile);
  report.inputs.push(identity(timingFile));
  assert.ok(timing.complete && !timing.error && timing.unsafeDefinitionSetsAgree);
  assert.equal(timing.rows.length, 6); assert.ok(timing.ratios.candidateProcessReduction > 0.03);
  assert.equal(timing.variants.candidate.api.sha256, expected);
  assert.equal(timing.variants.baseline.api.sha256, previous);
  timing.inputs.forEach(verifyIdentity);
  report.previous = verifyRelease(project);
  assert.equal(report.previous.files.find(f => f.path === 'dist/typed-api.mjs').sha256, previous);
  const unrelated = read(path.join(phase, 'start-state.json')).unrelatedPhase6;
  for (const row of unrelated) assert.equal(identity(path.join(repo, row.path)).sha256, row.sha256);
  const inventory = manifest => new Map(manifest.snapshot.sources.map(({frozen}) =>
    [path.relative(manifest.snapshot.root, frozen.file), frozen]));
  const a = inventory(old), b = inventory(m);
  assert.deepEqual([...a.keys()].sort(), [...b.keys()].sort());
  for (const [relative, before] of a) assert.equal(identity(path.join(project, relative)).sha256, before.sha256, relative);
  const changed = [...b].filter(([name, item]) => item.sha256 !== a.get(name).sha256);
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
  report.inputs.forEach(verifyIdentity);
  for (const row of unrelated) assert.equal(identity(path.join(repo, row.path)).sha256, row.sha256);
  report.complete = report.pass = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, copies: report.copies.length, error: report.error}));
