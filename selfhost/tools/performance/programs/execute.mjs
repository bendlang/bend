// One fresh process performs import, first call, warmup, calibration and timing.
// The parent supplies hard wall/RSS limits; all stages check every result.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [moduleArgument, configFile, outputFile] = process.argv.slice(2);
if (!moduleArgument || !configFile || !outputFile || process.argv.length !== 5) {
  throw new Error('usage: node execute.mjs MODULE POINT_JSON OUTPUT_JSON');
}
const sha = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const started = performance.now();
const report = {kind:'program-execution-v1', complete:false, pass:false, stage:'configuration',
  node:process.version, execArgv:process.execArgv, calibration:[]};
// Refuse to replace any earlier receipt, including an interrupted one.
const output = fs.openSync(outputFile, 'wx');
fs.writeSync(output, JSON.stringify(report, null, 2) + '\n');
try {
  const file = fs.realpathSync(moduleArgument);
  const config = JSON.parse(fs.readFileSync(configFile, 'utf8'));
  Object.assign(report, {module:{file, sha256:sha(file)}, config:structuredClone(config), configSha256:sha(configFile),
    toolSha256:sha(import.meta.filename)});
  assert.ok(Array.isArray(config.args), 'args must be an array');
  assert.ok(config.expected === null || ['string','boolean'].includes(typeof config.expected)
    || (typeof config.expected === 'number' && Number.isFinite(config.expected)),
  'expected must be a finite JSON scalar');
  const max = config.maxRepetitions ?? 1000000;
  assert.ok(Number.isInteger(max) && max >= 1 && max <= 1000000, 'invalid maxRepetitions');
  assert.ok(Number.isInteger(config.warmupCalls) && config.warmupCalls >= 0
    && config.warmupCalls <= 1000000, 'invalid warmupCalls');
  for (const key of ['warmupMs','calibrationMs','targetMs']) {
    assert.ok(Number.isFinite(config[key]) && config[key] >= 0 && config[key] <= 600000,
      `invalid ${key}`);
  }
  assert.ok(config.targetMs > 0, 'targetMs must be positive');
  const exportName = config.exportName ?? 'bench';
  assert.equal(typeof exportName, 'string', 'exportName must be a string');
  try {
    report.affinity = fs.readFileSync('/proc/self/status', 'utf8').split('\n')
      .find(line => line.startsWith('Cpus_allowed_list:'));
  } catch { report.affinity = null; }

  report.stage = 'import';
  const importedAt = performance.now();
  const mod = await import(pathToFileURL(file));
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
  report.stage = 'first-call';
  const firstAt = performance.now();
  report.firstResult = invoke();
  report.firstCallMs = performance.now() - firstAt;

  report.stage = 'warmup';
  const warmAt = performance.now();
  report.warmup = {calls:0, ms:0};
  while (report.warmup.calls < config.warmupCalls || performance.now() - warmAt < config.warmupMs) {
    invoke();
    report.warmup.calls++;
  }
  report.warmup.ms = performance.now() - warmAt;
  const batch = repetitions => {
    let checksum = 0, from = 0;
    const halves = [], begin = performance.now();
    for (const end of repetitions > 1 ? [Math.floor(repetitions/2), repetitions] : [repetitions]) {
      const at = performance.now();
      for (let i = from; i < end; i++) {
        const value = invoke();
        checksum = (checksum + (typeof value === 'string' ? value.length : Number(value))) >>> 0;
      }
      halves.push({calls:end-from, ms:performance.now()-at});
      from = end;
    }
    return {repetitions, executionMs:performance.now()-begin, checksum, halves};
  };
  report.stage = 'calibration';
  for (let repetitions = 1;; repetitions = Math.min(max, repetitions*2)) {
    const trial = batch(repetitions);
    report.calibration.push(trial);
    if (trial.executionMs >= config.calibrationMs || repetitions === max) break;
  }
  const calibration = report.calibration.at(-1);
  const repetitions = Math.min(max, Math.max(1,
    Math.ceil(config.targetMs * calibration.repetitions / Math.max(calibration.executionMs, 0.000001))));
  report.stage = 'timing';
  Object.assign(report, batch(repetitions));
  report.msPerCall = report.executionMs / repetitions;
  report.halfDriftPercent = report.halves.length === 2 && report.halves[0].ms > 0
    ? 100 * ((report.halves[1].ms/report.halves[1].calls)/(report.halves[0].ms/report.halves[0].calls)-1)
    : null;
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
  report.wallMs = performance.now() - started;
  report.resourceUsage = process.resourceUsage();
  report.peakRssKiB = report.resourceUsage.maxRSS;
  report.memory = process.memoryUsage();
  fs.ftruncateSync(output, 0);
  fs.writeSync(output, JSON.stringify(report, null, 2) + '\n', 0, 'utf8');
  fs.closeSync(output);
}
