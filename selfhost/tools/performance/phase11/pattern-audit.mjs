import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const initial = path.resolve(process.argv[2]), retry = path.resolve(process.argv[3]), out = path.resolve(process.argv[4]);
fs.mkdirSync(out);
const inputs = [import.meta.filename], variants = {};
const key = row => `${row.id}/${row.lane}`;
for (const variant of ['reference', 'candidate']) {
  const rows = new Map();
  for (const directory of [initial, retry]) {
    const file = path.join(directory, 'selected', variant + '.json');
    inputs.push(file);
    const report = JSON.parse(fs.readFileSync(file, 'utf8'));
    for (const row of report.results) rows.set(key(row), { ...row, observationSource: file });
  }
  variants[variant] = [...rows.values()];
}
const exactRefusals = [];
for (const lane of ['js', 'native']) {
  const expected = { status: 'error', phase: 'compile', checked: true, typeAccepted: true, exitCode: 1, diagnostic: 'Error: an open Array element type' };
  for (const variant of ['reference', 'candidate']) {
    const row = variants[variant].find(row => row.id === 'p11/open-array-refusal' && row.lane === lane);
    const actual = Object.fromEntries(Object.keys(expected).map(field => [field, row.result[field]]));
    exactRefusals.push({ variant, lane, actual, expected, pass: JSON.stringify(actual) === JSON.stringify(expected) });
  }
}
const counts = Object.fromEntries(Object.entries(variants).map(([variant, rows]) => [variant, { total: rows.length, passing: rows.filter(row => row.status === 'pass').length }]));
const identity = file => ({ file, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') });
const report = {
  scope: 'An explicit union of the retained first vector and only the corrected/blocked retries; not a claim that the first validation invocation passed. Each row retains its actual source report.',
  inputs: inputs.map(identity), counts, exactRefusals, variants,
  pass: Object.values(counts).every(count => count.total === 37 && count.passing === 37) && exactRefusals.every(row => row.pass),
};
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ pass: report.pass, counts }));
if (!report.pass) process.exitCode = 1;
