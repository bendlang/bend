// Install only the reviewed, fully gated Phase15 attempt; preserve the old release.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {verifyRelease, installAttempt} from '../../development/release.mjs';
const project = path.resolve(import.meta.dirname, '../../..');
const phase = path.join(project, 'build/phase15'), out = path.join(phase, 'promotion-01');
fs.mkdirSync(out); fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const read = file => JSON.parse(fs.readFileSync(file));
const gates = ['frontend-01/report.json', 'helper-gates-01/report.json',
  'integration-audit-02.json', 'behavior-final-audit-04/report.json',
  'trace-component-01/report.json', 'combined-02/validation-001/report.json'];
const report = {kind: 'phase15-gated-release-installation', complete: false, pass: false,
  started: new Date().toISOString(), inputs: [identity(import.meta.filename)], copies: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  for (const name of gates) {
    const file = path.join(phase, name), gate = read(file); report.inputs.push(identity(file));
    assert.equal(gate.complete, true, name);
    if (name !== 'trace-component-01/report.json') assert.equal(gate.pass, true, name);
    else { assert.equal(gate.status, 0); assert.equal(gate.signal, null); assert.ok(!gate.error); }
  }
  const timingFile = path.join(phase, 'check-matrix-01/report.json'), timing = read(timingFile);
  report.inputs.push(identity(timingFile));
  assert.ok(timing.complete && !timing.error && timing.unsafeDefinitionSetsAgree);
  assert.equal(timing.rows.length, 6); assert.ok(timing.ratios.candidateProcessReduction > 0);
  const attempt = path.join(phase, 'combined-02'), m = await verifyAttempt(attempt);
  assert.equal(m.api.sha256, 'b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d');
  report.previous = verifyRelease(project);
  assert.equal(report.previous.files.find(f => f.path === 'dist/typed-api.mjs').sha256,
    '9136be92928eda4b3b8e9c99e4e35d62504a825b458ff237c514d4e99f21206b');
  const base = path.join(project, 'build/phase14/combined-01/snapshot');
  const names = ['src/core/term.bend', 'src/front/parser.bend', 'src/front/declarations.bend',
    'src/front/sugar.bend', 'src/front/validate.bend', 'src/load/imports.bend',
    'src/load/graph.bend', 'tools/typed-driver.mjs', 'tests/frontend/phase2-rules/cases.json',
    ...['dotted_path', 'hub_head_local', 'hub_head_path', 'tilde_path'].map(n =>
      'tests/frontend/phase2-rules/phase15-' + n + '.bend')];
  for (const name of names) {
    const live = path.join(project, name), original = path.join(base, name);
    if (fs.existsSync(original)) assert.equal(identity(live).sha256, identity(original).sha256, name);
    else assert.ok(!fs.existsSync(live), name);
  }
  for (const name of names) {
    const live = path.join(project, name), frozen = path.join(m.snapshot.root, name);
    const before = fs.existsSync(live) ? identity(live) : null;
    fs.copyFileSync(frozen, live);
    report.copies.push({relative: name, before, source: identity(frozen), after: identity(live)});
  }
  save(); report.installed = await installAttempt(attempt);
  report.release = verifyRelease(project); report.inputs.forEach(verifyIdentity);
  assert.equal(report.release.files.find(f => f.path === 'dist/typed-api.mjs').sha256, m.api.sha256);
  report.complete = true; report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, error: report.error}));
