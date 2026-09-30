// Exact complete-state oracle on generic runtime variants; no timing or mutation.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [dirArg, outArg] = process.argv.slice(2), dir = path.resolve(dirArg), out = path.resolve(outArg);
fs.mkdirSync(out);
const identity = file => ({file: path.resolve(file), sha256: createHash('sha256').update(fs.readFileSync(file)).digest('hex'), bytes: fs.statSync(file).size});
const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'derive.json'))), points = JSON.parse(fs.readFileSync(path.join(dir, 'points.json')));
assert.equal(manifest.complete, true);
const inputs = [identity(import.meta.filename), identity(path.join(dir, 'derive.json')), identity(path.join(dir, 'points.json')), ...Object.values(manifest.variants), ...manifest.inputs];
const report = {kind: 'phase30-runtime-row-complete-state-controls', complete: false, pass: false, inputs, rows: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const verify = () => { for (const item of inputs) assert.deepEqual(identity(item.file), item); };
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-controls.mjs')); save();
try {
  verify();
  for (const [name, item] of Object.entries(manifest.variants)) {
    const module = await import(pathToFileURL(item.file));
    for (const point of points) {
      const actual = module.default.bench(...point.args);
      report.rows.push({variant: name, args: point.args, actual, expected: point.expected, pass: actual === point.expected});
      assert.equal(actual, point.expected, name + ' ' + point.args.join(','));
    }
    save();
  }
  verify(); report.complete = true; report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
save();
