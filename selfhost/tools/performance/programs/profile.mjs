// Diagnostic sampling only: never use profiled durations as benchmark ratios.
// Import, first call and warmup finish before the in-process inspector starts.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {Session} from 'node:inspector/promises';
import {pathToFileURL} from 'node:url';

const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const nonnegative = n => Number.isFinite(n) && n >= 0;
const frameKey = frame => JSON.stringify([
  frame.functionName, frame.url, frame.lineNumber, frame.columnNumber]);

// Nodes describe call paths; a frame can occur in several paths, including
// recursive ones. Inclusive totals count each frame once per leaf observation.
function aggregate(nodes, weights, counts, moduleUrl, unit) {
  const parents = new Map(), frames = new Map();
  for (const node of nodes.values()) {
    for (const child of node.children ?? []) {
      assert.ok(nodes.has(child), 'profile contains an unknown child');
      assert.ok(!parents.has(child), 'profile contains more than one parent');
      parents.set(child, node.id);
    }
  }
  const info = node => {
    const f = node.callFrame, key = frameKey(f);
    if (!frames.has(key)) frames.set(key, {
      frame:{functionName:f.functionName || '', url:f.url || '',
        lineNumber:f.lineNumber, columnNumber:f.columnNumber},
      functionName:f.functionName || '(anonymous)', url:f.url || '',
      line:f.lineNumber >= 0 ? f.lineNumber + 1 : null,
      column:f.columnNumber >= 0 ? f.columnNumber + 1 : null,
      category:node.unattributed ? 'unattributed' : f.url === moduleUrl ? 'generated'
        : f.url === import.meta.url ? 'harness'
        : f.functionName === '(garbage collector)' ? 'garbage-collector'
        : f.url?.startsWith('node:') ? 'node' : 'other',
      selfWeight:0, inclusiveWeight:0, selfSamples:0, inclusiveSamples:0,
    });
    return [key, frames.get(key)];
  };
  let totalWeight = 0, sampleCount = 0;
  for (const [id, weight] of weights) {
    assert.ok(nodes.has(id) && nonnegative(weight), 'invalid profile observation');
    const count = counts.get(id) ?? 0;
    totalWeight += weight;
    sampleCount += count;
    const [, self] = info(nodes.get(id));
    self.selfWeight += weight;
    self.selfSamples += count;
    const seenNodes = new Set(), seenFrames = new Set();
    for (let current = id; current !== undefined; current = parents.get(current)) {
      assert.ok(!seenNodes.has(current), 'cycle in profile tree');
      seenNodes.add(current);
      const [key, frame] = info(nodes.get(current));
      if (!seenFrames.has(key)) {
        frame.inclusiveWeight += weight;
        frame.inclusiveSamples += count;
        seenFrames.add(key);
      }
    }
  }
  const all = [...frames.values()].map(frame => ({...frame,
    ...(unit === 'estimated-allocated-bytes'
      ? {selfBytes:frame.selfWeight, inclusiveBytes:frame.inclusiveWeight}
      : {selfUs:frame.selfWeight, inclusiveUs:frame.inclusiveWeight}),
    selfPercent:totalWeight ? frame.selfWeight / totalWeight * 100 : null,
    inclusivePercent:totalWeight ? frame.inclusiveWeight / totalWeight * 100 : null,
  }));
  const categories = {};
  for (const frame of all) {
    const category = categories[frame.category] ??= {selfWeight:0, selfSamples:0};
    category.selfWeight += frame.selfWeight;
    category.selfSamples += frame.selfSamples;
  }
  for (const category of Object.values(categories)) {
    category.selfPercent = totalWeight ? category.selfWeight / totalWeight * 100 : null;
  }
  return {unit, totalWeight, sampleCount, frameCount:all.length, categories,
    frames:all.sort((a,b) => b.selfWeight-a.selfWeight || b.inclusiveWeight-a.inclusiveWeight),
    topSelf:all.filter(f => f.selfWeight > 0).slice(0,30),
    topInclusive:[...all].sort((a,b) => b.inclusiveWeight-a.inclusiveWeight
      || b.selfWeight-a.selfWeight).filter(f => f.inclusiveWeight > 0).slice(0,30)};
}

export function summarizeCpu(profile, moduleUrl) {
  assert.ok(Array.isArray(profile.nodes) && Array.isArray(profile.samples)
    && Array.isArray(profile.timeDeltas), 'invalid CPU profile');
  assert.equal(profile.samples.length, profile.timeDeltas.length, 'CPU sample/delta mismatch');
  const nodes = new Map(profile.nodes.map(node => [node.id, node]));
  assert.equal(nodes.size, profile.nodes.length, 'duplicate CPU node');
  const weights = new Map(), counts = new Map();
  profile.samples.forEach((id, i) => {
    const delta = profile.timeDeltas[i];
    assert.ok(nonnegative(delta), 'invalid CPU time delta');
    weights.set(id, (weights.get(id) ?? 0) + delta);
    counts.set(id, (counts.get(id) ?? 0) + 1);
  });
  const summary = aggregate(nodes, weights, counts, moduleUrl, 'sample-weighted-microseconds');
  return {...summary, profileDurationUs:profile.endTime-profile.startTime,
    weighting:'Each sample is weighted by its preceding time delta; these are sampling estimates, not instrumented function durations.',
    warnings:summary.sampleCount < 20 ? ['Fewer than 20 CPU samples: extend the profile before inferring a hotspot.'] : []};
}

export function summarizeAllocation(profile, moduleUrl) {
  assert.ok(profile.head && Array.isArray(profile.samples), 'invalid allocation profile');
  const nodes = new Map(), weights = new Map(), counts = new Map(), pending = [profile.head];
  let headSelfSizeBytes = 0, unattributedSamples = 0, unattributedEstimatedBytes = 0;
  while (pending.length) {
    const node = pending.pop();
    assert.ok(!nodes.has(node.id), 'duplicate allocation node');
    assert.ok(nonnegative(node.selfSize), 'invalid allocation size');
    nodes.set(node.id, {...node, children:(node.children ?? []).map(child => child.id)});
    headSelfSizeBytes += node.selfSize;
    weights.set(node.id, 0);
    pending.push(...node.children ?? []);
  }
  const unattributedNodeIds = new Set();
  for (const sample of profile.samples) {
    assert.ok(Number.isInteger(sample.nodeId) && nonnegative(sample.size), 'invalid allocation sample');
    // Real V8 output can contain samples whose node is absent from head, and
    // head.selfSize sums can differ from sample sizes even for known nodes.
    // Use one denominator (all sample.size values), keep unknown mass explicit,
    // and retain the tree total separately; never add both representations.
    if (!nodes.has(sample.nodeId)) nodes.set(sample.nodeId, {
      id:sample.nodeId, children:[], unattributed:true,
      callFrame:{functionName:`(unattributed allocation node ${sample.nodeId})`,
        url:'', lineNumber:-1, columnNumber:-1},
    });
    if (nodes.get(sample.nodeId).unattributed) {
      unattributedSamples++;
      unattributedEstimatedBytes += sample.size;
      unattributedNodeIds.add(sample.nodeId);
    }
    weights.set(sample.nodeId, (weights.get(sample.nodeId) ?? 0) + sample.size);
    counts.set(sample.nodeId, (counts.get(sample.nodeId) ?? 0) + 1);
  }
  const summary = aggregate(nodes, weights, counts, moduleUrl, 'estimated-allocated-bytes');
  const nodeWeightDisagreements = [...nodes.values()].filter(node => !node.unattributed
    && node.selfSize !== weights.get(node.id)).map(node => ({nodeId:node.id,
    headSelfSizeBytes:node.selfSize,sampleEstimatedBytes:weights.get(node.id)}));
  const warnings = summary.sampleCount === 0
    ? ['No sampled allocation observations; this does not prove allocation-free execution.']
    : summary.sampleCount < 20 ? ['Fewer than 20 allocation samples: extend the profile before inferring allocation proportions.'] : [];
  if (unattributedSamples) warnings.push(`${unattributedSamples} allocation samples (${unattributedEstimatedBytes} estimated bytes) refer to absent tree nodes; preserved as unattributed, with no inferred call path.`);
  if (nodeWeightDisagreements.length || summary.totalWeight !== headSelfSizeBytes) warnings.push(
    'Allocation sample and tree estimates differ. Frame weights use samples[].size only; both accounting totals and per-node differences are retained. The cause is not established by this profile.');
  return {...summary, estimatedBytes:summary.totalWeight,
    accounting:{weightSource:'samples[].size',sampleEstimatedBytes:summary.totalWeight,
      headSelfSizeBytes,sampleMinusHeadBytes:summary.totalWeight-headSelfSizeBytes,
      unattributedSamples,unattributedEstimatedBytes,unattributedNodeIds:[...unattributedNodeIds],
      nodeWeightDisagreements},
    weighting:'Sum of V8 samples[].size estimates with collected objects included; absent call-tree nodes remain unattributed. Not retained heap, exact allocations, or allocation event counts.',
    warnings};
}

async function main() {
  const [moduleArgument, configFile, outputFile, profileFile] = process.argv.slice(2);
  if (!moduleArgument || !configFile || !outputFile || !profileFile || process.argv.length !== 6) {
    throw new Error('usage: node profile.mjs MODULE POINT_JSON RECEIPT_JSON PROFILE_FILE');
  }
  const started = performance.now(), output = fs.openSync(outputFile, 'wx');
  let rawOutput, session;
  const report = {kind:'program-profile-v1', complete:false, pass:false, stage:'configuration',
    diagnosticOnly:true, node:process.version, execArgv:process.execArgv,
    timingBoundary:'Profiler encloses repeated calls plus result validation and loop control. Import, first call, warmup, profile serialization and final identity checks are outside.'};
  const checkpoint = () => {
    fs.ftruncateSync(output, 0);
    fs.writeSync(output, JSON.stringify(report, null, 2) + '\n', 0, 'utf8');
  };
  checkpoint();
  try {
    // Reserve both files before any generated code executes; never overwrite.
    rawOutput = fs.openSync(profileFile, 'wx');
    const file = fs.realpathSync(moduleArgument), moduleUrl = pathToFileURL(file).href;
    const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
    Object.assign(report, {module:{file, sha256:sha(file)}, config:structuredClone(config),
      configSha256:sha(configFile), toolSha256:sha(import.meta.filename)});
    assert.ok(Array.isArray(config.args), 'args must be an array');
    assert.ok(config.expected === null || ['string','boolean'].includes(typeof config.expected)
      || (typeof config.expected === 'number' && Number.isFinite(config.expected)),
    'expected must be a finite JSON scalar');
    const kind = config.profileKind ?? 'cpu', max = config.maxRepetitions ?? 1000000;
    assert.ok(['cpu','allocation'].includes(kind), 'invalid profileKind');
    assert.ok(Number.isInteger(max) && max >= 1 && max <= 100000000, 'invalid maxRepetitions');
    assert.ok(Number.isInteger(config.warmupCalls) && config.warmupCalls >= 0
      && config.warmupCalls <= 1000000, 'invalid warmupCalls');
    for (const key of ['warmupMs','targetMs']) {
      assert.ok(Number.isFinite(config[key]) && config[key] >= 0 && config[key] <= 600000,
        `invalid ${key}`);
    }
    assert.ok(config.targetMs > 0, 'targetMs must be positive');
    const exportName = config.exportName ?? 'bench';
    assert.equal(typeof exportName, 'string', 'exportName must be a string');
    const samplingInterval = kind === 'cpu' ? config.samplingIntervalUs ?? 1000
      : config.samplingIntervalBytes ?? 32768;
    assert.ok(Number.isInteger(samplingInterval) && samplingInterval >= (kind === 'cpu' ? 100 : 1024)
      && samplingInterval <= 10000000, 'invalid sampling interval');
    report.profileKind = kind;
    report.sampling = kind === 'cpu' ? {intervalMicroseconds:samplingInterval}
      : {intervalBytes:samplingInterval, includeObjectsCollectedByMajorGC:true,
        includeObjectsCollectedByMinorGC:true};
    try {
      report.affinity = fs.readFileSync('/proc/self/status', 'utf8').split('\n')
        .find(line => line.startsWith('Cpus_allowed_list:'));
    } catch { report.affinity = null; }

    report.stage = 'import'; checkpoint();
    const importedAt = performance.now(), mod = await import(moduleUrl);
    report.importMs = performance.now() - importedAt;
    const fn = mod.default?.[exportName] ?? mod[exportName];
    assert.equal(typeof fn, 'function', `missing function export ${exportName}`);
    const invoke = () => {
      const value = fn(...config.args);
      if (!Object.is(value, config.expected)) {
        assert.equal(value, config.expected, `wrong result during ${report.stage}`);
      }
      return value;
    };
    report.stage = 'first-call'; checkpoint();
    const firstAt = performance.now();
    report.firstResult = invoke();
    report.firstCallMs = performance.now() - firstAt;
    report.firstCalls = 1;
    report.stage = 'warmup'; checkpoint();
    const warmAt = performance.now();
    report.warmup = {calls:0, ms:0};
    while (report.warmup.calls < config.warmupCalls || performance.now() - warmAt < config.warmupMs) {
      invoke(); report.warmup.calls++;
    }
    report.warmup.ms = performance.now() - warmAt;
    report.stage = 'profiler-start'; checkpoint();
    session = new Session(); session.connect();
    if (kind === 'cpu') {
      await session.post('Profiler.enable');
      await session.post('Profiler.setSamplingInterval', {interval:samplingInterval});
    } else await session.post('HeapProfiler.enable');
    report.stage = 'profiling';
    report.repetitions = 0; report.checksum = 0;
    // Limit clock overhead on tiny exports. Use a conservative first-call
    // estimate; slow exports still execute one call per deadline check.
    report.batchCalls = Math.min(128, Math.max(1,
      Math.floor(1 / Math.max(report.firstCallMs, 0.000001))));
    checkpoint();
    if (kind === 'cpu') await session.post('Profiler.start');
    else await session.post('HeapProfiler.startSampling', {
      samplingInterval, includeObjectsCollectedByMajorGC:true, includeObjectsCollectedByMinorGC:true,
    });
    const profileAt = performance.now();
    let failure, repetitions = 0, checksum = 0;
    try {
      do {
        const end = Math.min(max, repetitions + report.batchCalls);
        while (repetitions < end) {
          const value = invoke();
          checksum = (checksum + (typeof value === 'string' ? value.length : Number(value))) >>> 0;
          repetitions++;
        }
      } while (repetitions < max && performance.now() - profileAt < config.targetMs);
    } catch (error) { failure = error; }
    finally {
      report.repetitions = repetitions; report.checksum = checksum;
      report.profiledLoopMs = performance.now() - profileAt;
      report.targetReached = report.profiledLoopMs >= config.targetMs;
      report.maxRepetitionsReached = report.repetitions === max;
      try {
        const {profile} = await session.post(kind === 'cpu' ? 'Profiler.stop' : 'HeapProfiler.stopSampling');
        fs.writeSync(rawOutput, JSON.stringify(profile) + '\n');
        fs.closeSync(rawOutput); rawOutput = undefined;
        report.profile = {file:fs.realpathSync(profileFile), path:fs.realpathSync(profileFile), sha256:sha(profileFile),
          bytes:fs.statSync(profileFile).size};
        report.summary = kind === 'cpu' ? summarizeCpu(profile, moduleUrl)
          : summarizeAllocation(profile, moduleUrl);
        if (!report.targetReached) report.summary.warnings.push(
          'Requested profile duration was not reached; inspect the repetition cap and completion status.');
      } catch (error) {
        report.profilerStopError = error.stack ?? String(error);
        failure ??= error;
      }
    }
    if (failure) throw failure;
    report.stage = 'identity-check';
    assert.equal(sha(file), report.module.sha256, 'module changed during execution');
    assert.equal(sha(configFile), report.configSha256, 'point changed during execution');
    assert.equal(sha(import.meta.filename), report.toolSha256, 'worker changed during execution');
    report.stage = 'done';
    report.complete = report.pass = true;
  } catch (error) {
    report.error = error.stack ?? String(error);
    process.exitCode = 1;
  } finally {
    session?.disconnect();
    if (rawOutput !== undefined) fs.closeSync(rawOutput);
    report.wallMs = performance.now() - started;
    report.resourceUsage = process.resourceUsage();
    report.peakRssKiB = report.resourceUsage.maxRSS;
    report.memory = process.memoryUsage();
    checkpoint(); fs.closeSync(output);
  }
}

if (process.argv[1] && fs.realpathSync(process.argv[1]) === import.meta.filename) await main();
