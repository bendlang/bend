// Full frontend observations with unchanged Phase10 and pinned upstream vectors.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity, verifyIdentity} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

const [attemptArg, outArg] = process.argv.slice(2);
const project = path.resolve(import.meta.dirname, '../../..');
const repo = path.dirname(project), attempt = fs.realpathSync(attemptArg), out = path.resolve(outArg);
const m = await verifyAttempt(attempt); fs.mkdirSync(out);
const candidate = path.join(out, 'candidate.json');
const reference = path.join(project, 'build/phase8/reference-frontend-01/reference.json');
const baseline = path.join(project, 'build/phase10/frontend-01/candidate.json');
const compare = path.join(project, 'tools/conformance/compare-artifacts.mjs');
const triage = path.join(repo, 'implementation/phase8/conformance-harness-evidence/frontend-triage.mjs');
const inputs = [import.meta.filename, process.execPath, reference, baseline, compare, triage, path.join(attempt, 'attempt.json')].map(identity);
const report = {kind: 'phase11-full-frontend-gate', started: new Date().toISOString(), complete: false,
  inputs, api: m.api, scope: 'Full fresh candidate parse/check vector; retained unchanged-pin reference and Phase10 vector. Exact and semantic comparisons are separate.', phases: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const env = {...process.env, BEND_TYPED_API: m.api.file, BEND_TYPED_RUNTIME: m.runtime.file, BEND_BASE: m.base.file, BEND_UPSTREAM: m.config.upstream};
save();
async function run(name, script, args, exits = [0]) {
  const execution = await supervise(process.execPath, [script, ...args], {directory: path.join(out, name), env, timeoutMs: 1800000});
  report.phases.push({name, execution}); save(); requireExecution(execution, exits);
}
try {
  await run('frontend', path.join(m.snapshot.root, 'tools/conformance/run.mjs'), [
    '--upstream', m.config.upstream, '--adapter', path.join(m.snapshot.root, 'tools/conformance/adapters/typed.mjs'),
    '--output', candidate, '--jobs', '4', '--timeout', '30000', '--worker-mode', 'persistent',
    '--recycle-after', '64', '--rss-limit-mb', '4096', '--lanes', 'parse,check', '--stack-kb', '4096',
    '--heap-mb', '4096', '--retain', 'failed', '--selected-exit', '1'], [0, 1]);
  const r = JSON.parse(fs.readFileSync(candidate));
  assert.ok(r.finished && !r.changedInputs.length && !r.identity.changedArtifacts.length && !r.identity.adapterChangedDuringRun);
  assert.ok(!r.workers?.some(w => w.errors?.length));
  assert.equal(r.results.length, r.inventory.total * 2);
  await run('reference-comparison', compare, ['--strict-paths', reference, candidate, path.join(out, 'reference-comparison.json')]);
  await run('baseline-comparison', compare, ['--strict-paths', baseline, candidate, path.join(out, 'baseline-comparison.json')]);
  await run('semantic-triage', triage, [reference, candidate, path.join(out, 'semantic-triage.json')]);
  await verifyAttempt(attempt); inputs.forEach(verifyIdentity);
  report.candidate = identity(candidate); report.summary = r.summary; report.complete = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
report.finished = new Date().toISOString(); save();
