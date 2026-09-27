import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';

const [api, variant, output] = process.argv.slice(2);
const {default: K} = await import(pathToFileURL(api));
const nil = {$: 'Nil'};
const list = xs => xs.reduceRight((tail, head) => ({$: 'Con', head, tail}), nil);
const t = (tag, name = '', id = 0, kids = []) => ({$: 'KTerm', tag, name, id, quant: tag === 'Lam' ? 1 : 0, kids: list(kids), removed: nil});
const variable = id => t('Var', 'x', id);
const app = (f, x) => t('App', '', 0, [f, x]);
const A = t('Ctr', 'A'), B = t('Ctr', 'B');
const closed = t('Ctr', 'Pack', 0, Array.from({length: 128}, () => t('Ctr', 'Pair', 0, [A, B])));
let beta = t('Ctr', 'Pair', 0, [variable(1000), variable(1063)]);
for (let id = 1063; id >= 1000; id--) beta = t('Lam', 'x', id, [beta]);
for (let id = 1000; id <= 1063; id++) beta = app(beta, id % 2 === 0 ? A : B);
const workloads = [{name: 'closed-constructor-data', input: closed, repetitions: 100}, {name: '64-dependent-environment-beta-steps', input: beta, repetitions: 50}];
const hash = value => crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
const results = [];
for (const {name, input, repetitions} of workloads) {
  const inputHash = hash(input);
  const expected = K.strong(nil, input);
  assert.equal(K.sv_supported(input), true);
  assert.equal(K.compare(nil, K.sv_observe(input).term, expected, false), true);
  const run = variant === 'old' ? () => K.strong(nil, input) : () => K.sv_observe(input).term;
  for (let warm = 0; warm < 10; warm++) run();
  const samples = [];
  for (let sample = 0; sample < 3; sample++) {
    let result;
    const start = performance.now();
    for (let i = 0; i < repetitions; i++) result = run();
    const elapsedMs = performance.now() - start;
    assert.equal(K.compare(nil, result, expected, false), true);
    samples.push({sample, repetitions, elapsedMs, perRequestMs: elapsedMs / repetitions});
  }
  assert.equal(hash(input), inputHash, 'input mutation');
  results.push({name, inputHash, warmups: 10, samples});
}
const report = {variant, pass: true, node: process.version, apiSha256: crypto.createHash('sha256').update(fs.readFileSync(api)).digest('hex'),
  results, resourceUsage: process.resourceUsage(), memoryUsage: process.memoryUsage()};
fs.writeFileSync(output, JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({variant, pass: true, rssKiB: report.resourceUsage.maxRSS}));
