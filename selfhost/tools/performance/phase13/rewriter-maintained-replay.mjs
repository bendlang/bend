// Exact authentic history and profile6 image replay; no compiler execution/timing.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity, verifyIdentity} from '../../development/workflow.mjs';
import * as original from '../../../build/phase12/integrated-03/snapshot/tools/development/equality.mjs';

const [helperArg, candidateArg, outArg] = process.argv.slice(2), out = path.resolve(outArg);
fs.mkdirSync(out);
const candidate = JSON.parse(fs.readFileSync(candidateArg));
assert.ok(candidate.complete && candidate.inputsVerified);
const helper = await import(pathToFileURL(path.resolve(helperArg)));
const oldHelper = path.resolve('selfhost/build/phase12/integrated-03/snapshot/tools/development/equality.mjs');
const inputs = [import.meta.filename, helperArg, candidateArg, oldHelper, process.execPath,
  path.resolve('design/phase13/integration.md'), candidate.checkedApi.file, candidate.api.file].map(identity);
const consumed = path.join(out, 'consumed'); fs.mkdirSync(consumed);
fs.copyFileSync(import.meta.filename, path.join(consumed, 'replay.mjs'));
fs.copyFileSync(helperArg, path.join(consumed, 'candidate-equality.mjs'));
fs.copyFileSync(oldHelper, path.join(consumed, 'historical-equality.mjs'));
const report = {kind: 'phase13-self-contained-maintained-feasibility-replay', complete: false, pass: false,
  scope: 'Authentic versions1–5 verified by both maintained implementations; exact source and JSON statistics. New profile6 reproduces the frozen six-owner derivative. No checked build, compiler conformance or performance result.',
  inputs, rows: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
const cases = [
  [1, 'selfhost/build/phase8/release-verification-01/legacy/dist/release-lineage/derivation.json'],
  [2, 'selfhost/build/phase9/equality-derivation-01/api.mjs.derivation.json'],
  [3, 'selfhost/build/phase10/release-smoke-02/relocated/dist/release-lineage/derivation.json'],
  [4, 'selfhost/build/phase11/release-smoke-01/relocated/dist/release-lineage/derivation.json'],
  [5, 'selfhost/build/phase12/integrated-03/equality/api.mjs.derivation.json'],
];
try {
  for (const [version, file] of cases) {
    const verified = original.verifyEqualityDerivation(path.resolve(file)), metadata = verified.metadata;
    helper.verifyEqualityDerivation(path.resolve(file));
    assert.equal(metadata.transform.version, version);
    inputs.push(...[file, metadata.original.api.file, metadata.output.file].map(identity));
    const source = fs.readFileSync(metadata.original.api.file, 'utf8');
    const expected = original.transformEquality(source, version), actual = helper.transformEquality(source, version);
    const directory = path.join(out, 'version-' + version); fs.mkdirSync(directory);
    const api = path.join(directory, 'api.mjs'); fs.writeFileSync(api, actual.source);
    fs.writeFileSync(path.join(directory, 'stats.json'), JSON.stringify(actual.stats, null, 2) + '\n');
    const row = {version, authentic: identity(metadata.output.file), output: identity(api),
      exactSource: actual.source === expected.source && actual.source === fs.readFileSync(metadata.output.file, 'utf8'),
      exactStats: JSON.stringify(actual.stats) === JSON.stringify(expected.stats) && JSON.stringify(actual.stats) === JSON.stringify(metadata.transform)};
    report.rows.push(row); save(); assert.ok(row.exactSource && row.exactStats);
  }
  const checked = fs.readFileSync(candidate.checkedApi.file, 'utf8');
  const actual = helper.transformEquality(checked), explicit = helper.transformEquality(checked, 6);
  assert.equal(actual.stats.version, 6); assert.deepEqual(actual, explicit);
  const api = path.join(out, 'profile6-api.mjs'); fs.writeFileSync(api, actual.source);
  fs.writeFileSync(path.join(out, 'profile6-stats.json'), JSON.stringify(actual.stats, null, 2) + '\n');
  const {checkedInputSha256, baselineStats, ...selectorReport} = candidate.transformReport;
  assert.deepEqual(actual.stats.selectors, selectorReport);
  assert.equal(actual.source, fs.readFileSync(candidate.api.file, 'utf8'));
  const raw = fs.readFileSync(helperArg, 'utf8');
  const imports = raw.split('\n').filter(line => line.startsWith('import '));
  assert.ok(imports.every(line => /from 'node:/.test(line)));
  report.profile6 = {output: identity(api), exactCandidate: true, exactSelectorReport: true, defaultsTo6: true};
  report.complexity = {physical: raw.split('\n').length - Number(raw.endsWith('\n')),
    nonblank: raw.split('\n').filter(line => line.trim()).length, bytes: Buffer.byteLength(raw), imports,
    includesAllHistoricalProfiles: true, importedHistoricalHelpers: 0};
  inputs.forEach(verifyIdentity); report.inputsVerified = true; report.complete = true; report.pass = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
save(); console.log(JSON.stringify({complete: report.complete, pass: report.pass, history: report.rows, profile6: report.profile6, complexity: report.complexity, error: report.error}));
