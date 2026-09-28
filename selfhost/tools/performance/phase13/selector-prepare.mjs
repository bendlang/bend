import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {transform} from './selector-fusion.mjs';

const [outArg, ...families] = process.argv.slice(2), out = path.resolve(outArg);
assert.ok(outArg);
fs.mkdirSync(out);
const parentAttempt = path.resolve('selfhost/build/phase12/integrated-03');
const parent = await verifyAttempt(parentAttempt);
const helper = path.join(import.meta.dirname, 'selector-fusion.mjs');
const helperInputs = [helper, ...['rewriter-structure.mjs', 'rewriter-v5.mjs'].map(f => path.join(import.meta.dirname, f)),
  path.join(parent.snapshot.root, 'tools/development/equality.mjs')].map(identity);
const options = {families: families.length ? families : ['$norm_eval_node$']};
const inputs = [import.meta.filename, path.resolve('experiments/phase13/P13-005-selector-fusion.md'),
  path.join(parentAttempt, 'attempt.json'), parent.checkedApi.file, parent.api.file,
  parent.base.file, parent.runtime.file, process.execPath].map(identity);
const report = {kind: 'phase13-structured-selector-candidate', complete: false, parentAttempt,
  checkedApi: parent.checkedApi, baselineApi: parent.api, base: parent.base, runtime: parent.runtime,
  helper: identity(helper), helperInputs, options, inputs,
  scope: 'Explicit tag-selector derivative of a verified checked compiler. Selected body arrows remain. No new bootstrap, general stack proof or performance claim.'};
const save = () => fs.writeFileSync(path.join(out, 'manifest.json'), JSON.stringify(report, null, 2) + '\n');
save();
const consumed = path.join(out, 'consumed');
fs.mkdirSync(consumed);
for (const input of [...helperInputs, ...inputs.filter(x => /\.(mjs|md)$/.test(x.file))])
  fs.copyFileSync(input.file, path.join(consumed, path.basename(input.file)));
try {
  const result = transform(fs.readFileSync(parent.checkedApi.file, 'utf8'), options);
  const api = path.join(out, 'api.mjs'), metadata = path.join(out, 'transform.json');
  fs.writeFileSync(api, result.source);
  fs.writeFileSync(metadata, JSON.stringify(result.report, null, 2) + '\n');
  report.api = identity(api);
  report.transformReport = result.report;
  report.transformReportIdentity = identity(metadata);
  [...inputs, ...helperInputs].forEach(verifyIdentity);
  report.complete = true;
  report.inputsVerified = true;
} catch (error) {
  report.error = String(error.stack ?? error);
  process.exitCode = 1;
}
save();
console.log(JSON.stringify({complete: report.complete, api: report.api,
  removedIntermediateSelectors: report.transformReport?.removedIntermediateSelectors, error: report.error}));
