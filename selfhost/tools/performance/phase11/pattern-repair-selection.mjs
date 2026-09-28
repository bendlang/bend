import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const input = path.resolve(process.argv[2]);
const out = path.resolve(process.argv[3]);
fs.mkdirSync(out);
const original = JSON.parse(fs.readFileSync(input, 'utf8'));
const full = structuredClone(original);
for (const row of full.cases) {
  if (row.id === 'p11/open-array-refusal') {
    delete row.accept;
    delete row.rejectPhase;
    row.expected = 'Error: an open Array element type\nexit 1';
  }
  if (row.id === 'p11/nat_literal_pattern_arity') row.rejectPhase = 'parse';
}
const retry = { cases: full.cases.flatMap(row => {
  if (row.id === 'p11/open-array-refusal' || row.id === 'p11/nat_literal_pattern_arity') return [row];
  return row.lanes.includes('native') ? [{ ...row, lanes: ['native'] }] : [];
}) };
for (const [name, selection] of [['full', full], ['retry', retry]]) {
  fs.writeFileSync(path.join(out, `${name}.json`), JSON.stringify(selection, null, 2) + '\n');
}
const identity = file => ({ file, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') });
fs.writeFileSync(path.join(out, 'manifest.json'), JSON.stringify({
  reason: 'Preserve the first complete observation vector. Compile refusal needs an exact execution oracle, not unsupported check-only acceptance. Malformed pattern fails parsing before checking. Retry only affected or sandbox-blocked rows.',
  inputs: [input, import.meta.filename, path.join(import.meta.dirname, 'pattern-fixtures.mjs')].map(identity),
  fullRows: full.cases.reduce((n, row) => n + row.lanes.length, 0),
  retryRows: retry.cases.reduce((n, row) => n + row.lanes.length, 0),
}, null, 2) + '\n');
