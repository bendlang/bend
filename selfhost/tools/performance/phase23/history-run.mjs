// Paired fresh/check-history correctness gate for explicitly derived experimental images.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {bindCandidate, prepareVariant, repo, identity, verifyIdentity, supervise, requireExecution} from './history-inputs.mjs';
import {createPersistentRunner, resultDigest, validatePersistentReplay} from '../../conformance/persistent-probe.mjs';

function pairedPayload(result, variant) {
  assert.deepEqual(result.hostProvenance, variant.hostProvenance, 'Result host provenance is not the actual bound host');
  const {hostProvenance, ...payload} = result;
  return {...payload, hostProvenance: {adapterSha256: hostProvenance.adapterSha256}};
}

const [manifestArg, outArg, cpu = '1'] = process.argv.slice(2), out = path.resolve(outArg);
assert.equal(cpu, '1'); fs.mkdirSync(out);
const report = {kind: 'phase23-own-host-paired-history-gate', complete: false, pass: false, cpu,
  scope: 'Correctness only. Two genuine checked B1/equality-v6 attempts on new pin0187512/Base. Original history requests, fixture bytes, order and resources retained. Each own snapshot/runtime is explicit; hostProvenance independently validated, with all other payload fields exact and no diagnostic exception. Historical Phase12 failures remain recorded.',
  resources: {stackKiB: 4096, heapMiB: 4096, requestDeadlineMs: 30000, recycleAfter: 64, rssLimitMiB: 4096},
  inputs: [], variants: {}, fresh: [], histories: [], launches: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n'); save();
try {
  const binding = await bindCandidate(manifestArg), {parent, candidate, add, inputs} = binding;
  report.manifest = binding.manifest; report.baseline = parent.api; report.candidate = candidate.api; report.ownHostBindings = binding.hostChecks;

  add(import.meta.filename); add(path.resolve(import.meta.dirname, '../../conformance/persistent-probe.mjs'));
  fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
  fs.copyFileSync(path.join(import.meta.dirname, 'history-inputs.mjs'), path.join(out, 'consumed-inputs.mjs'));
  const verify = () => {report.inputs = [...inputs.values()]; report.inputs.forEach(verifyIdentity);};
  const histories = [
    {name: 'history-53', request: 'frontend-02/candidate.json.artifacts/477/request.json', previous: 'call-leaf-noseed-prefix-01/report.json', count: 53},
    {name: 'history-60', request: 'call-prefix-input-01/phase11-passing-request.json', previous: 'call-leaf-noseed-prefix-02/report.json', count: 60},
  ];
  for (const h of histories) {
    h.requestFile = path.join(repo, 'selfhost/build/phase12', h.request);
    h.previousFile = path.join(repo, 'selfhost/build/phase12', h.previous);
    h.request = JSON.parse(fs.readFileSync(h.requestFile)); h.previous = JSON.parse(fs.readFileSync(h.previousFile));
    h.originalIdentity = JSON.parse(fs.readFileSync(h.request.identityFile)); h.session = JSON.parse(fs.readFileSync(h.request.workerSession.file));
    validatePersistentReplay(h.request, h.session, h.originalIdentity.workerNodeArgs);
    assert.equal(h.originalIdentity.node, process.execPath); assert.equal(h.originalIdentity.nodeVersion, process.version);
    assert.deepEqual(h.originalIdentity.workerNodeArgs, ['--stack-size=4096', '--max-old-space-size=4096']);
    assert.equal(h.request.workerSession.index + 1, h.count); assert.equal(h.session.recycleAfter, 64); assert.equal(h.session.rssLimitMb, 4096);
    assert.equal(h.previous.rows[0].requests.length, h.count);
    for (const f of [h.requestFile, h.previousFile, h.request.identityFile, h.request.workerSession.file, h.session.worker]) add(f);
    for (const [file, sha] of Object.entries(h.originalIdentity.inputHashes)) {
      assert.equal(fs.existsSync(file) ? identity(file).sha256 : null, sha, 'Original input changed: ' + file); if (sha) add(file);
    }
    for (const [file, canonical] of Object.entries(h.originalIdentity.inputPaths ?? {})) assert.equal(fs.existsSync(file) ? fs.realpathSync(file) : null, canonical);
    const originalDir = path.join(out, h.name + '-original'); fs.mkdirSync(originalDir);
    for (const [name, file] of [['request.json', h.requestFile], ['identity.json', h.request.identityFile], ['session.json', h.request.workerSession.file], ['phase12-replay.json', h.previousFile]]) fs.copyFileSync(file, path.join(originalDir, name));
  }
  const freshFixture=path.join(parent.config.upstream,'tests/check/string_literal_long.bend'); assert.equal(identity(freshFixture).sha256,histories[0].request.test.sha256); add(freshFixture);
  for (const name of ['baseline', 'candidate']) {
    verify(); report.variants[name] = await prepareVariant(binding, name, path.join(out, name), cpu); verify(); save();
  }
  for (const name of ['baseline', 'candidate']) {
    const v = report.variants[name], fresh = path.join(v.directory, 'fresh.json'); verify();
    const execution = await supervise('taskset', ['-c', cpu, process.execPath, path.join(v.project, 'tools/conformance/run.mjs'), '--upstream', parent.config.upstream,
      '--adapter', v.adapter, '--output', fresh, '--jobs', '1', '--timeout', '30000', '--worker-mode', 'isolated', '--lanes', 'check',
      '--filter', '^check/string_literal_long\\.bend$', '--stack-kb', '4096', '--heap-mb', '4096', '--retain', 'all', '--selected-exit', '1'],
      {directory: path.join(v.directory, 'fresh-process'), env: v.environment, timeoutMs: 60000});
    report.launches.push({name: name + '-fresh', execution}); save(); requireExecution(execution);
    const observed = JSON.parse(fs.readFileSync(fresh)); assert.equal(observed.results.length, 1);
    const row = observed.results[0]; report.fresh.push({name, report: identity(fresh), observation: row}); save();
    assert.equal(row.status, 'pass'); assert.equal(row.result.phase, 'check'); assert.equal(row.result.typeAccepted, true); assert.equal(row.result.proofTrust, 'passed');
    assert.equal(observed.changedInputs.length, 0); assert.equal(observed.identity.changedArtifacts.length, 0); assert.equal(observed.identity.adapterChangedDuringRun, false); verify();
  }
  assert.deepEqual(pairedPayload(report.fresh[0].observation.result, report.variants.baseline), pairedPayload(report.fresh[1].observation.result, report.variants.candidate), 'Fresh result changed beyond bound driver identity');
  for (const h of histories) {
    const history = {name: h.name, original: {request: identity(h.requestFile), identity: identity(h.request.identityFile), session: identity(h.request.workerSession.file), targetIndex: h.count - 1}, rows: []}; report.histories.push(history); save();
    for (const name of ['baseline', 'candidate']) {
      const v = report.variants[name], directory = path.join(v.directory, h.name); fs.mkdirSync(directory);
      const historicalHost = [{role:'adapter',before:{file:h.request.adapter,sha256:h.session.adapterSha256},after:identity(v.adapter)}];
      for(const tool of ['typed-driver.mjs','compiler-abi.mjs','node-resource-args.mjs']) historicalHost.push({role:tool,before:identity(path.resolve(path.dirname(h.request.adapter),'../..',tool)),after:identity(path.join(v.project,'tools',tool))});
      for(const row of historicalHost){row.same=row.before.sha256===row.after.sha256;add(row.before.file);add(row.after.file);}
      const environment = {...h.originalIdentity.environment, BEND_TYPED_API: v.api.file, BEND_TYPED_RUNTIME: v.runtime.file, BEND_BASE: v.base.file, BEND_UPSTREAM: v.upstream};
      const identityFile = path.join(directory, 'substitution.json');
      fs.writeFileSync(identityFile, JSON.stringify({kind: 'phase23-explicit-migrated-history-substitution', original: history.original, manifest: binding.manifest, api: v.api, cache: v.cache, project: v.project, adapter: identity(v.adapter), runtime: v.runtime, base: v.base, historicalRuntime: h.originalIdentity.identity.artifacts.runtime, historicalBase: h.originalIdentity.identity.artifacts.base, environment, changes: ['compiler image', 'own verified snapshot host project (all baseline/candidate/historical differences listed)', 'new upstream0187512 and Base from original b2111cf', 'own runtime including explicitly listed TCP/array changes; parse/check lanes only', 'validated per-image cache', 'output paths'], historicalHost}, null, 2) + '\n'); add(identityFile);
      for (const key of h.originalIdentity.environmentKeys) delete process.env[key]; delete process.env.NODE_OPTIONS; Object.assign(process.env, environment);
      verify(); const runner = createPersistentRunner({directory: path.join(directory, 'worker'), workerNodeArgs: h.originalIdentity.workerNodeArgs, worker: h.session.worker, recycleAfter: 64, rssLimitMb: 4096});
      const row = {name, complete: false, historicalHost, requests: [], changedFromPhase12: []}; history.rows.push(row); save();
      try {
        for (let i = 0; i < h.count; i++) {
          const recorded = h.session.requests[i], workdir = path.join(directory, 'request-' + i); fs.mkdirSync(workdir);
          assert.equal(recorded.request.timeoutMs, 30000); assert.ok(['parse','check'].includes(recorded.request.lane)); assert.equal(identity(recorded.request.test.file).sha256,recorded.request.test.sha256);
          const request = {...recorded.request, adapter: v.adapter, project: v.project, upstream: v.upstream, identityFile, workdir, response: path.join(workdir, 'response.json'), workerSession: undefined};
          for (const key of ['done', 'workerStdout', 'workerStderr']) delete request[key];
          const execution = await runner.run(request), result = execution.result, digest = resultDigest(result);
          row.requests.push({index: i, id: recorded.request.test.id, lane: recorded.request.lane, result, worker: execution.worker, resultDigest: digest, originalResultDigest: recorded.resultDigest,
            phase12ResultDigest: h.previous.rows[0].requests[i].resultDigest, exactOriginal: digest === recorded.resultDigest,
            exactPhase12: JSON.stringify(result) === JSON.stringify(h.previous.rows[0].requests[i].result)}); save();
          assert.ok(!['crash', 'timeout'].includes(result.status), 'Worker error: ' + JSON.stringify(result));
          assert.equal(execution.worker.index, i); assert.equal(execution.worker.generation, 1);
          if(!row.requests.at(-1).exactPhase12)row.changedFromPhase12.push({index:i,id:recorded.request.test.id,lane:recorded.request.lane,oldResult:h.previous.rows[0].requests[i].result,currentResult:result});
          pairedPayload(result, v);
          if (name === 'candidate') {
            const actual=pairedPayload(result,v),expected=pairedPayload(history.rows[0].requests[i].result,report.variants.baseline);
            assert.deepEqual(actual,expected,'Paired result changed beyond bound driver identity at '+i);
          }
        }
        const target = row.requests.at(-1).result; assert.equal(target.status, 'ok'); assert.equal(target.phase, 'check'); assert.equal(target.typeAccepted, true); assert.equal(target.proofTrust, 'passed');
        assert.equal(runner.errors.length, 0); verify(); row.complete = true;
      } finally {runner.close(); row.runner = {stats: runner.stats, errors: runner.errors}; save();}
      console.log(JSON.stringify({history: h.name, variant: name, complete: row.complete, requests: row.requests.length}));
    }
  }
  verify(); binding.replay(); report.exactPairedPayloadExceptBoundHostProvenance = true; report.pairedObservations=report.histories.reduce((n,h)=>n+h.rows.reduce((k,r)=>k+r.requests.length,0),0); assert.equal(report.pairedObservations,226); assert.equal(report.fresh.length,2); report.inputsVerified = true; report.complete = true; report.pass = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
report.finished = new Date().toISOString(); save(); console.log(JSON.stringify({complete: report.complete, pass: report.pass, error: report.error}));
