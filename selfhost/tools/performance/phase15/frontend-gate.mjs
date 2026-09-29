// Full frontend gate: preserve acceptance/trust and audit parser/load/caret deltas.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity, verifyIdentity, observationHealth} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';
import {compareReports} from '../../conformance/compare-artifacts.mjs';

const [attemptArg, outArg, priorArg] = process.argv.slice(2);
const project = path.resolve(import.meta.dirname, '../../..'), repo = path.dirname(project);
const attempt = fs.realpathSync(attemptArg), out = path.resolve(outArg), m = await verifyAttempt(attempt);
fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const candidateFile = path.join(out, 'candidate.json');
const referenceFile = path.join(project, 'build/phase8/reference-frontend-01/reference.json');
const baselineFile = path.join(project, 'build/phase14/frontend-audit-02/candidate.json');
const compare = path.join(project, 'tools/conformance/compare-artifacts.mjs');
const triage = path.join(repo, 'implementation/phase8/conformance-harness-evidence/frontend-triage.mjs');
const inputs = [import.meta.filename, process.execPath, referenceFile, baselineFile, compare, triage,
  path.join(attempt, 'attempt.json')].map(identity);
const report = {kind: 'phase15-full-frontend-gate', complete: false, pass: false,
  started: new Date().toISOString(), inputs, api: m.api, phases: [],
  scope: 'Full fresh candidate parse/check inventory. Exact unchanged-pin comparisons; every Phase14 delta classified. No kernel proof or backend equivalence claim.',
  policy: {positiveTypeAcceptance: 1001, validationNegativeRefusals: 482, proofTrustRefusals: 11,
    observations: 2996, baselineExactDifferences: 603,
    allowedChanges: ['New exact reference match', 'Ten named parser/load fixtures restore reference semantic/output axes',
      'Parser diagnostic adds only caret rows, all semantic/output fields unchanged'],
    forbidden: ['Lost exact reference match', 'Unexpected semantic delta', 'Missing observation', 'Input drift', 'Failed launch or resource gate']}};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const env = {...process.env};
for (const key of Object.keys(env)) if (key.startsWith('BEND_') || ['NODE_OPTIONS', 'NODE_PATH'].includes(key)) delete env[key];
Object.assign(env, {BEND_TYPED_API: m.api.file, BEND_TYPED_RUNTIME: m.runtime.file,
  BEND_BASE: m.base.file, BEND_UPSTREAM: m.config.upstream});
const read = file => JSON.parse(fs.readFileSync(file));
const key = row => row.id + '\0' + row.lane;
const behavior = new Set(['import/cross_file_io.bend', 'import/cross_file_proof.bend',
  'import/cycle_terminates.bend', 'import/diamond_dedup.bend', 'import/dotted_path.bend',
  'import/hub_head_local.bend', 'import/hub_head_path.bend', 'import/path_canonical.bend',
  'import/tilde_path.bend', 'parse/prefix_operator_dead.bend']);
const stripCarets = text => typeof text === 'string' ? text.split('\n').filter(line => !/^[ \t]*\|[ \t]*\^+[ \t]*$/.test(line)).join('\n') : text;
const semantic = row => Object.fromEntries(['status', 'phase', 'checked', 'typeAccepted', 'proofTrust',
  'kernelChecked', 'unsafeDefinitions', 'exitCode', 'output'].map(k => [k, k === 'output' ? row.output ?? row.stdout ?? null : row[k] ?? null]));
async function run(name, script, args, exits = [0]) {
  const execution = await supervise(process.execPath, [script, ...args],
    {directory: path.join(out, name), env, timeoutMs: 1800000});
  report.phases.push({name, execution}); save(); requireExecution(execution, exits);
}
save();
try {
  inputs.forEach(verifyIdentity);
  if (priorArg) {
    const priorDir = fs.realpathSync(priorArg), priorFile = path.join(priorDir, 'report.json'), prior = read(priorFile);
    assert.equal(prior.api.sha256, m.api.sha256); assert.equal(prior.api.canonicalPath, m.api.canonicalPath);
    prior.inputs.forEach(verifyIdentity);
    const phase = prior.phases.find(p => p.name === 'frontend'); assert.ok(phase); requireExecution(phase.execution, [0, 1]);
    const oldCandidate = path.join(priorDir, 'candidate.json');
    const recoveryInputs = [identity(priorFile), identity(oldCandidate)]; inputs.push(...recoveryInputs);
    report.reusedFrontend = {inputs: recoveryInputs, execution: phase.execution, scope: 'Reaudit the same healthy full vector after an explicitly diagnosed postprocessing failure; no fixture rerun or oracle change.'};
    fs.copyFileSync(oldCandidate, candidateFile); save();
  } else await run('frontend', path.join(m.snapshot.root, 'tools/conformance/run.mjs'), [
    '--upstream', m.config.upstream, '--adapter', path.join(m.snapshot.root, 'tools/conformance/adapters/typed.mjs'),
    '--output', candidateFile, '--jobs', '4', '--timeout', '30000', '--worker-mode', 'persistent',
    '--recycle-after', '64', '--rss-limit-mb', '4096', '--lanes', 'parse,check', '--stack-kb', '4096',
    '--heap-mb', '4096', '--retain', 'failed', '--selected-exit', '1'], [0, 1]);
  const candidate = read(candidateFile), reference = read(referenceFile), baseline = read(baselineFile);
  assert.ok(observationHealth(candidate), 'Incomplete or unhealthy observations');
  const expectedArtifacts = {compiler: m.api, runtime: m.runtime, base: m.base,
    driver: identity(path.join(m.snapshot.root, 'tools/typed-driver.mjs')),
    compilerManifest: identity(path.join(m.snapshot.root, 'src/compiler.json'))};
  for (const [name, expected] of Object.entries(expectedArtifacts)) {
    assert.equal(fs.realpathSync(candidate.identity.artifacts[name].file), expected.canonicalPath);
    assert.equal(candidate.identity.artifacts[name].sha256, expected.sha256);
    assert.equal(candidate.identity.finalArtifactHashes[name], expected.sha256);
  }
  const adapter = identity(path.join(m.snapshot.root, 'tools/conformance/adapters/typed.mjs'));
  assert.equal(fs.realpathSync(candidate.options.adapter), adapter.canonicalPath);
  assert.equal(candidate.identity.adapterSha256, adapter.sha256);
  assert.equal(candidate.identity.finalAdapterSha256, adapter.sha256);
  assert.equal(candidate.options.upstream, m.config.upstream);
  assert.equal(String(candidate.options['stack-kb']), '4096');
  assert.equal(String(candidate.options['heap-mb']), '4096');
  assert.equal(candidate.results.length, 2996); assert.equal(candidate.inventory.total, 1498);
  await run('reference-comparison', compare, ['--strict-paths', referenceFile, candidateFile, path.join(out, 'reference-comparison.json')]);
  await run('baseline-comparison', compare, ['--strict-paths', baselineFile, candidateFile, path.join(out, 'baseline-comparison.json')]);
  await run('semantic-triage', triage, [referenceFile, candidateFile, path.join(out, 'semantic-triage.json')]);
  const prior = compareReports(reference, baseline, {strictPaths: true});
  const current = read(path.join(out, 'reference-comparison.json'));
  const delta = read(path.join(out, 'baseline-comparison.json'));
  const priorMismatches = new Set(prior.changes.map(key)), currentMismatches = new Set(current.changes.map(key));
  const referenceRows = new Map(reference.results.map(row => [key(row), row]));
  const candidateRows = new Map(candidate.results.map(row => [key(row), row]));
  for (const id of behavior) for (const lane of ['parse', 'check']) {
    const k = id + '\0' + lane, row = candidateRows.get(k)?.result, ref = referenceRows.get(k)?.result;
    assert.ok(row && ref, 'Every targeted parser/load observation must exist');
    assert.deepEqual(semantic(row), semantic(ref), 'Every targeted parser/load behavior must match reference');
    assert.equal(row.status, 'error'); assert.equal(row.phase, 'parse');
  }
  assert.equal(prior.changes.length, 603);
  assert.equal(current.missing.length, 0); assert.equal(delta.missing.length, 0);
  report.delta = [];
  for (const change of delta.changes) {
    const k = key(change), a = change.before, b = change.after;
    let reason = null;
    if (!currentMismatches.has(k)) reason = 'new-exact-reference-match';
    else if (!priorMismatches.has(k)) reason = 'regressed-exact-reference-match';
    else if (behavior.has(change.id)) {
      const r = referenceRows.get(k).result;
      assert.deepEqual(semantic(b), semantic(r), 'Named parser/load fixture must restore reference semantic/output axes');
      assert.equal(b.status, 'error'); assert.equal(b.phase, 'parse');
      reason = 'parser-load-intended-reference-phase';
    } else if (a.phase === 'parse' && b.phase === 'parse' &&
      JSON.stringify(semantic(a)) === JSON.stringify(semantic(b)) && typeof b.diagnostic === 'string' &&
      b.diagnostic !== a.diagnostic && stripCarets(b.diagnostic) === a.diagnostic) {
      reason = 'parser-caret-only';
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
  assert.equal(t.proofTrust.exactPasses, 11);
  assert.equal(t.deferredErrors.unexpected.length, 0);
  assert.equal(report.exact.regressed, 0);
  assert.ok(report.exact.after < 603, 'The selected corrections must improve exact conformance');
  await verifyAttempt(attempt); inputs.forEach(verifyIdentity);
  report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, exact: report.exact,
  unexpected: report.unexpected?.length, error: report.error}));
