// Diagnostic CPU sampling and top-level API attribution. Not a timing benchmark.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import inspector from 'node:inspector';
import {pathToFileURL} from 'node:url';

const [configArgument, outputArgument] = process.argv.slice(2);
if (!outputArgument) throw Error('Usage: cpu-profile.mjs CONFIG.json NEW_DIRECTORY');
const configFile = fs.realpathSync(configArgument);
const config = JSON.parse(fs.readFileSync(configFile));
const resolve = file => fs.realpathSync(path.resolve(path.dirname(configFile), file));
const out = path.resolve(outputArgument);
fs.mkdirSync(out, {recursive: false});
const sha = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const inputs = new Map();
const capture = file => {
  file = fs.realpathSync(file);
  const item = {file, sha256: sha(file)};
  if (inputs.has(file)) assert.deepEqual(inputs.get(file), item);
  else inputs.set(file, item);
  return file;
};
const verify = () => { for (const item of inputs.values()) assert.equal(sha(item.file), item.sha256, 'Input drift: ' + item.file); };
const save = (name, value) => fs.writeFileSync(path.join(out, name), JSON.stringify(value, null, 2) + '\n');
capture(import.meta.filename); capture(configFile); capture(process.execPath);
const apiFile = capture(resolve(config.api));
const driver = capture(resolve(config.driver));
const base = capture(resolve(config.base));
const runtime = capture(resolve(config.runtime));
const input = capture(resolve(config.input));
for (const name of ['compiler-abi.mjs', 'assemble.mjs', 'native-build.mjs', 'node-resource-args.mjs']) capture(path.join(path.dirname(driver), name));
process.env.BEND_TYPED_API = apiFile;
process.env.BEND_TYPED_RUNTIME = runtime;
process.env.BEND_BASE = base;
delete process.env.BEND_TYPED_TRACE;
const D = await import(pathToFileURL(driver));
const raw = await D.loadApi();
const primeStart = performance.now();
const seed = await D.prepareBase(raw);
const primeMs = performance.now() - primeStart;
assert.equal(seed.validatedBy, 'check_book');
for (const file of D.discoverSources(raw, input, {seed}).files) capture(file);
// Top-level methods run synchronously. Their spans include boundary encode/decode.
const events = [];
const api = Object.fromEntries(Object.entries(raw).map(([name, method]) => [name, (...args) => {
  const begin = performance.now();
  try { return method(...args); }
  finally { events.push({name, beginMs: begin, endMs: performance.now()}); }
}]));
const report = {
  kind: 'phase24-diagnostic-profile', complete: false, started: new Date().toISOString(),
  scope: 'Instrumented one-request profile, after Base preparation and dependency discovery. CPU samples and API spans diagnose costs; instrumentation and warmed discovery mean these are not benchmark samples.',
  node: {path: process.execPath, version: process.version, args: process.execArgv},
  affinity: fs.readFileSync('/proc/self/status', 'utf8').split('\n').find(line => line.startsWith('Cpus_allowed_list:')),
  api: apiFile, input, mode: config.mode ?? 'compile', primeMs,
  samplingIntervalMicroseconds: config.intervalUs ?? 1000,
  inputs: [...inputs.values()], events,
};
save('report.json', report);
const session = new inspector.Session();
session.connect();
const post = (method, params = {}) => new Promise((accept, reject) => session.post(method, params, (error, result) => error ? reject(error) : accept(result)));
let profiling = false;
try {
  if (config.allocations) { await post('HeapProfiler.enable'); await post('HeapProfiler.startSampling', {samplingInterval: config.allocationInterval ?? 1048576, includeObjectsCollectedByMajorGC:true, includeObjectsCollectedByMinorGC:true}); }
  await post('Profiler.enable');
  await post('Profiler.setSamplingInterval', {interval: report.samplingIntervalMicroseconds});
  const origin = performance.now();
  await post('Profiler.start'); profiling = true;
  const started = performance.now();
  const result = await D.inspect(input, {api, mode: report.mode});
  report.requestMs = performance.now() - started;
  const {profile} = await post('Profiler.stop'); profiling = false;
  // Inspector and performance clocks have different epochs. Align at start;
  // startup uncertainty is bounded by the measured Profiler.start round trip.
  report.profileStartUncertaintyMs = started - origin;
  fs.writeFileSync(path.join(out, 'request.cpuprofile'), JSON.stringify(profile));
  if (config.allocations) { const {profile: heap} = await post('HeapProfiler.stopSampling'); const costs=new Map(),todo=[heap.head]; let nodes=0; while(todo.length) { const n=todo.pop(); nodes++; const key=JSON.stringify(n.callFrame); costs.set(key,(costs.get(key)??0)+n.selfSize); for(const c of n.children??[])todo.push(c); } save('allocations.json',{policy:'Aggregate sampled allocation sizes by exact call frame, including collected objects; diagnostic estimates, not retained heap or exhaustive allocation counts.',interval:config.allocationInterval??1048576,nodes,samples:heap.samples,sites:[...costs].filter(([,bytes])=>bytes).sort((a,b)=>b[1]-a[1]).map(([frame,bytes])=>({frame:JSON.parse(frame),bytes}))}); }
  const nodes = new Map(profile.nodes.map(node => [node.id, node]));
  const totals = new Map();
  const perApi = new Map();
  let elapsedUs = 0, eventIndex = 0;
  for (let i = 0; i < (profile.samples?.length ?? 0); i++) {
    const delta = profile.timeDeltas[i]; elapsedUs += delta;
    const timeMs = origin + elapsedUs / 1000;
    while (eventIndex < events.length && events[eventIndex].endMs < timeMs) eventIndex++;
    const event = events[eventIndex];
    const phase = event && event.beginMs <= timeMs && timeMs <= event.endMs ? event.name : '(host/profiler/gap)';
    const frame = nodes.get(profile.samples[i]).callFrame;
    const key = JSON.stringify([frame.functionName || '(anonymous)', frame.url, frame.lineNumber + 1]);
    totals.set(key, (totals.get(key) ?? 0) + delta);
    if (!perApi.has(phase)) perApi.set(phase, new Map());
    const counts = perApi.get(phase); counts.set(key, (counts.get(key) ?? 0) + delta);
  }
  const rank = counts => [...counts].sort((a, b) => b[1] - a[1]).map(([key, microseconds]) => {
    const [functionName, url, line] = JSON.parse(key);
    return {functionName, url, line, sampledMs: microseconds / 1000, fraction: microseconds / elapsedUs};
  });
  report.samples = profile.samples?.length ?? 0;
  report.sampledMs = elapsedUs / 1000;
  report.topFunctions = rank(totals).slice(0, 80);
  report.byApi = [...perApi].map(([name, counts]) => ({name, sampledMs: [...counts.values()].reduce((a,b) => a+b,0)/1000, topFunctions: rank(counts).slice(0,30)}));
  report.apiTotals = Object.entries(Object.groupBy(events, event => event.name)).map(([name, rows]) => ({name, calls: rows.length, wallMs: rows.reduce((n, row) => n + row.endMs - row.beginMs, 0)})).sort((a,b) => b.wallMs-a.wallMs);
  if (result.code !== undefined) {
    const file = path.join(out, 'program.mjs'); fs.writeFileSync(file, result.code);
    report.emitted = {file, bytes: Buffer.byteLength(result.code), sha256: sha(file)};
    delete result.code;
  }
  report.result = result;
  if(config.expectUnsafe) { assert.equal(result.typeAccepted,true); assert.equal(result.proofTrust,'failed'); assert.equal(result.phase,'verdict'); }
  else { assert.equal(result.status,'ok'); assert.equal(result.checked,true); }
  if (config.expectedCodeSha256) assert.equal(report.emitted?.sha256, config.expectedCodeSha256);
  verify(); report.inputsUnchanged = true; report.complete = true;
} catch (error) {
  report.error = error?.stack || String(error); process.exitCode = 1;
} finally {
  if (profiling) { try { const {profile} = await post('Profiler.stop'); fs.writeFileSync(path.join(out, 'failed.cpuprofile'), JSON.stringify(profile)); } catch {} }
  session.disconnect();
  report.finished = new Date().toISOString(); save('report.json', report);
}
console.log(JSON.stringify({complete: report.complete, requestMs: report.requestMs, apiTotals: report.apiTotals, topFunctions: report.topFunctions?.slice(0,15), error: report.error}));
