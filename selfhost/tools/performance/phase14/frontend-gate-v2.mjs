// Full frontend gate: preserve acceptance, improve law trust, audit every delta.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity, verifyIdentity, observationHealth} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';
import {compareReports} from '../../conformance/compare-artifacts.mjs';

const [attemptArg, outArg] = process.argv.slice(2);
const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const attempt = fs.realpathSync(attemptArg), out = path.resolve(outArg), m = await verifyAttempt(attempt);
fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const candidateFile = path.join(out, 'candidate.json');
const referenceFile = path.join(project, 'build/phase8/reference-frontend-01/reference.json');
const baselineFile = path.join(project, 'build/phase12/frontend-03/candidate.json');
const compare = path.join(project, 'tools/conformance/compare-artifacts.mjs');
const triage = path.join(repo, 'implementation/phase8/conformance-harness-evidence/frontend-triage.mjs');
const inputs = [import.meta.filename, process.execPath, referenceFile, baselineFile, compare, triage,
  path.join(attempt, 'attempt.json')].map(identity);
const report = {kind: 'phase14-full-frontend-gate-v2', complete: false, pass: false,
  started: new Date().toISOString(), inputs, api: m.api, phases: [],
  scope: 'Full fresh candidate parse/check inventory. Exact unchanged-pin comparisons; every Phase12 delta classified. No kernel proof or backend equivalence claim.',
  policy: {positiveTypeAcceptance: 1001, validationNegativeRefusals: 482, proofTrustRefusals: 11,
    observations: 2996, baselineExactDifferences: 730,
    allowedChanges: ['New exact reference match', 'Four named imported-law cases reach intended parse/trust phase',
      'import/alias_decl.bend restores reference parser refusal with existing exact diagnostic gap',
      'Checker diagnostic adds only caret rows, all semantic/output fields unchanged'],
    forbidden: ['Lost exact reference match', 'Unexpected semantic delta', 'Missing observation', 'Input drift', 'Failed launch or resource gate']}};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const env = {...process.env};
for (const key of Object.keys(env)) if (key.startsWith('BEND_') || ['NODE_OPTIONS', 'NODE_PATH'].includes(key)) delete env[key];
Object.assign(env, {BEND_TYPED_API: m.api.file, BEND_TYPED_RUNTIME: m.runtime.file,
  BEND_BASE: m.base.file, BEND_UPSTREAM: m.config.upstream});
const read = file => JSON.parse(fs.readFileSync(file));
const key = row => row.id + '\0' + row.lane;
const laws = new Set(['derived', 'fill', 'own', 'unused'].map(s => 'import/unsafe_law_' + s + '.bend'));
const stripCarets = text => typeof text === 'string' ? text.split('\n').filter(line => !/^[ \t]*\|[ \t]*\^+[ \t]*$/.test(line)).join('\n') : text;
const semantic = row => Object.fromEntries(['status', 'phase', 'checked', 'typeAccepted', 'proofTrust',
  'kernelChecked', 'unsafeDefinitions', 'exitCode', 'output'].map(k => [k, row[k]]));
async function run(name, script, args, exits = [0]) {
  const execution = await supervise(process.execPath, [script, ...args],
    {directory: path.join(out, name), env, timeoutMs: 1800000});
  report.phases.push({name, execution}); save(); requireExecution(execution, exits);
}
save();
try {
  inputs.forEach(verifyIdentity);
  await run('frontend', path.join(m.snapshot.root, 'tools/conformance/run.mjs'), [
    '--upstream', m.config.upstream, '--adapter', path.join(m.snapshot.root, 'tools/conformance/adapters/typed.mjs'),
    '--output', candidateFile, '--jobs', '4', '--timeout', '30000', '--worker-mode', 'persistent',
    '--recycle-after', '64', '--rss-limit-mb', '4096', '--lanes', 'parse,check', '--stack-kb', '4096',
    '--heap-mb', '4096', '--retain', 'failed', '--selected-exit', '1'], [0, 1]);
  const candidate = read(candidateFile), reference = read(referenceFile), baseline = read(baselineFile);
  assert.ok(observationHealth(candidate), 'Incomplete or unhealthy observations');
  assert.equal(candidate.results.length, 2996); assert.equal(candidate.inventory.total, 1498);
  await run('reference-comparison', compare, ['--strict-paths', referenceFile, candidateFile, path.join(out, 'reference-comparison.json')]);
  await run('baseline-comparison', compare, ['--strict-paths', baselineFile, candidateFile, path.join(out, 'baseline-comparison.json')]);
  await run('semantic-triage', triage, [referenceFile, candidateFile, path.join(out, 'semantic-triage.json')]);
  const prior = compareReports(reference, baseline, {strictPaths: true});
  const current = read(path.join(out, 'reference-comparison.json'));
  const delta = read(path.join(out, 'baseline-comparison.json'));
  const priorMismatches = new Set(prior.changes.map(key)), currentMismatches = new Set(current.changes.map(key));
  const referenceRows = new Map(reference.results.map(row => [key(row), row]));
  assert.equal(prior.changes.length, 730);
  assert.equal(current.missing.length, 0); assert.equal(delta.missing.length, 0);
  report.delta = [];
  for (const change of delta.changes) {
    const k = key(change), a = change.before, b = change.after;
    let reason = null;
    if (!currentMismatches.has(k)) reason = 'new-exact-reference-match';
    else if (!priorMismatches.has(k)) reason = 'regressed-exact-reference-match';
    else if (laws.has(change.id)) {
      const r = referenceRows.get(k).result;
      const required = change.lane === 'parse'
        ? {status: 'ok', phase: 'parse', exitCode: 0, checked: false, typeAccepted: false, proofTrust: 'not-assessed', kernelChecked: false}
        : {status: 'error', phase: 'verdict', exitCode: 1, checked: true, typeAccepted: true, proofTrust: 'failed', kernelChecked: false};
      assert.deepEqual(Object.fromEntries(Object.keys(required).map(k => [k, b[k]])), required);
      if (change.lane === 'check') assert.deepEqual([...b.unsafeDefinitions].sort(), [...r.unsafeDefinitions].sort());
      reason = 'imported-law-intended-phase';
    } else if (change.id === 'import/alias_decl.bend') {
      const r = referenceRows.get(k).result;
      assert.deepEqual(semantic(b), semantic(r), 'Alias declaration must restore exact reference semantic/output axes');
      assert.equal(b.status, 'error'); assert.equal(b.phase, 'parse');
      reason = 'import-alias-declaration-parse-refusal';
    } else if (change.lane === 'check' && a.phase === 'check' && b.phase === 'check' &&
      JSON.stringify(semantic(a)) === JSON.stringify(semantic(b)) && typeof b.diagnostic === 'string' &&
      b.diagnostic !== a.diagnostic && stripCarets(b.diagnostic) === a.diagnostic) {
      reason = 'checker-caret-only';
    }
    report.delta.push({id: change.id, lane: change.lane, reason, referenceExact: !currentMismatches.has(k)});
  }
  report.unexpected = report.delta.filter(row => !row.reason || row.reason === 'regressed-exact-reference-match');
  report.triage = read(path.join(out, 'semantic-triage.json'));
  report.exact = {before: prior.changes.length, after: current.changes.length,
    improved: [...priorMismatches].filter(k => !currentMismatches.has(k)).length,
    regressed: [...currentMismatches].filter(k => !priorMismatches.has(k)).length};
  report.candidate = identity(candidateFile); report.summary = candidate.summary;
  report.complete = true; save();
  assert.equal(report.unexpected.length, 0, 'Every changed observation needs a scoped explanation');
  const t = report.triage;
  assert.equal(t.positive.candidateAccepted, 1001);
  assert.equal(t.validationNegative.candidateRefused, 482);
  assert.equal(t.validationNegative.unexpectedTypeAcceptance.length, 0);
  assert.equal(t.validationNegative.unresolved.length, 0);
  assert.equal(t.proofTrust.candidateRefusals, 11);
  assert.equal(t.deferredErrors.unexpected.length, 0);
  assert.equal(report.exact.regressed, 0);
  assert.ok(report.exact.after < 730, 'The selected diagnostic correction must improve exact conformance');
  await verifyAttempt(attempt); inputs.forEach(verifyIdentity);
  report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, exact: report.exact,
  unexpected: report.unexpected?.length, error: report.error}));
