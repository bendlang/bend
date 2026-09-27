import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';

const [action, candidate, supplied] = process.argv.slice(2);
if (!['prepare', 'run'].includes(action) || !candidate || !supplied) throw Error('usage: node benchmark.mjs prepare|run CHECKED_ATTEMPT FRESH_BENCHMARK_DIR');
const dir = path.resolve(supplied), source = path.resolve(candidate);
const hash = file => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const write = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
if (action === 'prepare') {
  if (fs.existsSync(dir)) throw Error('Fresh benchmark directory required');
  for (const phase of ['build', 'test']) if (!JSON.parse(fs.readFileSync(path.join(source, phase + '.json'))).pass) throw Error('Candidate must pass build and controls');
  fs.mkdirSync(dir, {recursive: true});
  for (const file of ['benchmark.mjs', 'benchmark-worker.mjs']) fs.copyFileSync(path.join(import.meta.dirname, file), path.join(dir, file));
  fs.copyFileSync(path.join(source, 'api.mjs'), path.join(dir, 'api.mjs'));
  write(path.join(dir, 'plan.json'), {kind: 'P7-A02 serial operation microbenchmark', candidate: source,
    order: ['old', 'new', 'new', 'old', 'old', 'new', 'new', 'old'], cpu: '0',
    node: process.version, executable: process.execPath, stackKiB: 4096, heapMiB: 4096,
    workloads: ['closed constructor Pack with128 Pair fields', '64 applied lambda binders, retaining first and last variables'],
    warmups: 10, samples: 3, repetitions: {closed: 100, beta: 50},
    boundary: 'Entire public strong(emptyBook,input) versus sv_observe(input).term, including scope guard, max-ID initialization and observation counters; setup/import/exact-oracle comparisons excluded',
    limits: 'Empty book and named grammar only; not whole-compiler throughput, TypeScript comparison or emitted user-code benchmark',
    memory: 'Per fresh Node worker process.resourceUsage().maxRSS; includes imports, controls and both workloads',
    identities: ['benchmark.mjs', 'benchmark-worker.mjs', 'api.mjs'].map(file => ({file, sha256: hash(path.join(dir, file))})),
    nodeSha256: hash(process.execPath), prepared: new Date().toISOString()});
  console.log(JSON.stringify({prepared: dir}));
} else {
  const plan = JSON.parse(fs.readFileSync(path.join(dir, 'plan.json')));
  const verify = () => {
    if (hash(process.execPath) !== plan.nodeSha256) throw Error('Node changed');
    for (const input of plan.identities) if (hash(path.join(dir, input.file)) !== input.sha256) throw Error('Frozen benchmark input changed: ' + input.file);
  };
  verify();
  const workers = [];
  for (const [index, variant] of plan.order.entries()) {
    const stem = String(index).padStart(2, '0') + '-' + variant;
    const result = path.join(dir, stem + '.json');
    if (fs.existsSync(result)) throw Error('Do not overwrite a prior sample');
    const args = ['-c', plan.cpu, process.execPath, '--stack-size=4096', '--max-old-space-size=4096', path.join(dir, 'benchmark-worker.mjs'), path.join(dir, 'api.mjs'), variant, result];
    const start = performance.now();
    const child = spawnSync('taskset', args, {encoding: 'utf8', timeout: 60000, maxBuffer: 1024 * 1024});
    fs.writeFileSync(path.join(dir, stem + '.stdout'), child.stdout || '');
    fs.writeFileSync(path.join(dir, stem + '.stderr'), child.stderr || '');
    const execution = {index, variant, command: 'taskset', args, exitCode: child.status, signal: child.signal,
      error: child.error?.message || null, elapsedMs: performance.now() - start};
    write(path.join(dir, stem + '.execution.json'), execution);
    workers.push({...execution, observation: fs.existsSync(result) ? JSON.parse(fs.readFileSync(result)) : null});
    if (child.status !== 0 || child.error) break;
  }
  verify();
  const median = numbers => { const sorted = [...numbers].sort((a, b) => a - b); return (sorted[Math.floor((sorted.length - 1) / 2)] + sorted[Math.ceil((sorted.length - 1) / 2)]) / 2; };
  const pass = workers.length === plan.order.length && workers.every(worker => worker.exitCode === 0 && worker.observation?.pass);
  const summaries = pass ? workers[0].observation.results.map((first, position) => {
    const values = variant => workers.filter(worker => worker.variant === variant).map(worker => median(worker.observation.results[position].samples.map(sample => sample.perRequestMs)));
    const old = values('old'), candidate = values('new');
    return {workload: first.name, oldWorkerMediansMs: old, newWorkerMediansMs: candidate,
      oldMedianMs: median(old), newMedianMs: median(candidate), ratio: median(candidate) / median(old),
      inputHashes: [...new Set(workers.map(worker => worker.observation.results[position].inputHash))]};
  }) : [];
  const memory = pass ? {oldKiB: workers.filter(worker => worker.variant === 'old').map(worker => worker.observation.resourceUsage.maxRSS),
    newKiB: workers.filter(worker => worker.variant === 'new').map(worker => worker.observation.resourceUsage.maxRSS)} : null;
  write(path.join(dir, 'report.json'), {pass, plan, summaries, memory, workers});
  console.log(JSON.stringify({pass, summaries, memory}));
  if (!pass) process.exitCode = 1;
}
