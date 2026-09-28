// Instrumented operation counts only; these images are never timing samples.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity, verifyIdentity} from '../../development/workflow.mjs';
import {moduleView} from './rewriter-structure.mjs';

const [manifestArg, outArg] = process.argv.slice(2), out = path.resolve(outArg);
assert.equal(process.version, 'v24.18.0'); fs.mkdirSync(out);
const manifest = JSON.parse(fs.readFileSync(manifestArg));
assert.ok(manifest.complete && manifest.inputsVerified);
const inputs = [import.meta.filename, process.execPath, manifestArg,
  new URL('./rewriter-structure.mjs', import.meta.url).pathname,
  manifest.baselineApi.file, manifest.api.file].map(identity);
for (const row of [...manifest.helperInputs, manifest.baselineApi, manifest.api]) verifyIdentity(row);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
fs.copyFileSync(new URL('./rewriter-structure.mjs', import.meta.url), path.join(out, 'consumed-structure.mjs'));
const once = (source, before, after) => { assert.equal(source.split(before).length, 2); return source.replace(before, () => after); };
const list = xs => xs.reduceRight((tail, head) => ({$: 'Con', head, tail}), {$: 'Nil'});
const report = {kind: 'phase13-worker-operation-counts', complete: false, inputs,
  scope: 'Counters on isolated generated images, not checked candidates or speed measurements. Dispatch slot totals count every trampoline iteration, including explicit worker packets.',
  variants: [], rows: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  const variants = [];
  for (const [name, file] of [['baseline', manifest.baselineApi.file], ['workers', manifest.api.file]]) {
    let source = fs.readFileSync(file, 'utf8');
    const view = moduleView(source), sites = new Map();
    if (name === 'baseline') {
      for (const family of manifest.options.families) {
        const owner = view.functions.get(family); assert.ok(owner);
        for (let i = owner.body + 1; i < owner.end; i++) {
          const site = view.returnedChoice(i); if (site) sites.set(i, site);
        }
      }
      assert.equal(sites.size, manifest.transformReport.sites);
      source = view.program(sites, (site, render) => 'p13counts.selectedClosures++; return ' + render(site.first + 1, site.end));
    } else {
      const insertions = manifest.transformReport.workers.map(worker => {
        const fn = view.functions.get(worker.name); assert.ok(fn);
        return {at: view.ts[fn.body].end, text: '\np13counts.workerEntries++; p13counts.captureElements += ' + worker.captures.length + ';'};
      }).sort((a, b) => b.at - a.at);
      for (const {at, text} of insertions) source = source.slice(0, at) + text + source.slice(at);
    }
    source = once(source, 'function run_tail(f, x) {', 'function run_tail(f, x) {\n  p13counts.runTail++;');
    source = once(source, '    r = r.f(...r.x);', '    p13counts.dispatches++; p13counts.dispatchSlots += r.x.length;\n    r = r.f(...r.x);');
    source = 'let p13counts = {selectedClosures:0,workerEntries:0,captureElements:0,runTail:0,dispatches:0,dispatchSlots:0};\n' + source;
    source += '\nexport function p13reset() {for (const key of Object.keys(p13counts)) p13counts[key]=0;} export function p13get() {return {...p13counts};}\n';
    const instrumented = path.join(out, name + '.mjs'); fs.writeFileSync(instrumented, source, {flag: 'wx'});
    variants.push({name, K: await import(pathToFileURL(instrumented))});
    report.variants.push({name, original: identity(file), instrumented: identity(instrumented)});
  }
  for (const n of [4, 16, 64]) {
    const dep = 'type Bit is Data:\n  O{}\n  I{}\n' + Array.from({length: n}, (_, i) => `def value${i}() -> Bit:\n  O{}\n`).join('');
    const main = 'import dep.bend as dep\n' + Array.from({length: n}, (_, i) => `def copy${i}() -> dep.Bit:\n  dep.value${i}\n`).join('');
    const fixture = {name: 'module-' + n, n, sources: [{$: 'FSource', name: 'main', path: '/main.bend', text: main}, {$: 'FSource', name: 'dep', path: '/dep.bend', text: dep}]};
    const fixtureFile = path.join(out, fixture.name + '.json'); fs.writeFileSync(fixtureFile, JSON.stringify(fixture, null, 2) + '\n'); inputs.push(identity(fixtureFile));
    let expected, baselineCounts;
    for (const {name, K} of variants) {
      K.p13reset(); const loaded = K.default.f_load_graph('/main.bend', list(fixture.sources)); const loadCounts = K.p13get();
      assert.equal(loaded.error, ''); K.p13reset(); const checked = K.default.check_book(loaded.book); const checkCounts = K.p13get(); assert.equal(checked, '');
      const observed = {loaded, checked};
      if (name === 'baseline') {expected = observed; baselineCounts = {load: loadCounts, check: checkCounts};}
      else {
        assert.deepEqual(observed, expected);
        for (const [phase, counts] of [['load', loadCounts], ['check', checkCounts]]) {
          const baseline = baselineCounts[phase];
          assert.equal(counts.dispatches, baseline.dispatches, phase + ': lifting must not claim fewer messages');
          assert.equal(counts.workerEntries, baseline.selectedClosures, phase + ': every selected closure replaced by exactly one worker');
          assert.equal(counts.dispatchSlots - baseline.dispatchSlots, counts.captureElements, phase + ': count all extra capture slots');
          assert.equal(baseline.runTail - counts.runTail, counts.workerEntries, phase + ': run_tail calls replaced by explicit messages');
        }
      }
      const resultFile = path.join(out, fixture.name + '-' + name + '.json'); fs.writeFileSync(resultFile, JSON.stringify(observed) + '\n');
      report.rows.push({n, variant: name, fixture: identity(fixtureFile), result: identity(resultFile), load: loadCounts, check: checkCounts, exactBaseline: true}); save();
    }
  }
  inputs.forEach(verifyIdentity); report.inputsVerified = true; report.complete = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
report.finished = new Date().toISOString(); save(); console.log(JSON.stringify(report));
