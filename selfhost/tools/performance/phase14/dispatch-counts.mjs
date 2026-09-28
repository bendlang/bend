// Instrumented operation counts only; these images are never timing samples.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {moduleView} from '../phase13/rewriter-structure.mjs';

const [baselineArg, candidateArg, outArg] = process.argv.slice(2), out = path.resolve(outArg);
assert.equal(process.version, 'v24.18.0'); fs.mkdirSync(out);
const baseline = await verifyAttempt(baselineArg), candidate = await verifyAttempt(candidateArg);
assert.equal(baseline.api.sha256, '0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697');
assert.equal(candidate.runtime.sha256, baseline.runtime.sha256);assert.equal(candidate.base.sha256, baseline.base.sha256);
const inputs = [import.meta.filename, process.execPath, path.join(baselineArg,'attempt.json'),path.join(candidateArg,'attempt.json'),new URL('../phase13/rewriter-structure.mjs', import.meta.url).pathname, baseline.api.file,candidate.api.file].map(identity);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
fs.copyFileSync(new URL('../phase13/rewriter-structure.mjs', import.meta.url), path.join(out, 'consumed-structure.mjs'));
const once = (source, before, after) => { assert.equal(source.split(before).length, 2); return source.replace(before, () => after); };
const list = xs => xs.reduceRight((tail, head) => ({$: 'Con', head, tail}), {$: 'Nil'});
const report = {kind: 'phase14-source-dispatch-operation-counts', complete: false, inputs,
  scope: 'Counters on isolated generated images, not checked candidates or speed measurements. Count actual selected-family literal arrow creation, Unit construction, all JMP object/array allocation, run_tail calls and every dispatch. Each counted JMP literal contains exactly one fresh x array.',
  variants: [], rows: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
try {
  const variants = [];
  for (const [name, file] of [['baseline', baseline.api.file], ['candidate', candidate.api.file]]) {
    let source = fs.readFileSync(file, 'utf8');
    const view = moduleView(source), {ts} = view, insertions = [];
    const selected = (name === 'baseline' ? ['norm_eval_node'] : ['norm_eval_node',...['app','ann','let','ref','min','rwt'].map(n=>'norm_node_'+n)]).map(name => {
      const fn = view.functions.get(name); assert.ok(fn); return fn;
    });
    const selectedAt = i => selected.some(fn => fn.body < i && i < fn.end);
    const wrap = (start, end, counter) => {
      insertions.push({at: start, text: '(' + counter + ', '});
      insertions.push({at: end, text: ')'});
    };
    let staticClosures = 0, staticUnits = 0, staticMessages = 0;
    for (let i = 0; i < ts.length; i++) {
      if (ts[i].text === '{' && ts[i + 1]?.text === '$' && ts[i + 2]?.text === ':') {
        const tag = ts[i + 3]?.text;
        if (tag === '"Unit"') {
          assert.equal(ts[i].close, i + 4, 'Unit literal has extra fields');
          wrap(ts[i].start, ts[ts[i].close].end, 'p13counts.units++' + (selectedAt(i) ? ', p13counts.familyUnits++' : ''));
          staticUnits++;
        } else if (tag === '"$JMP"') {
          const fields = view.split(i), vector = fields[2];
          assert.equal(fields.length, 3);
          assert.equal(ts[vector[0]].text, 'x'); assert.equal(ts[vector[0] + 1].text, ':');
          const array = vector[0] + 2;
          assert.equal(ts[array].text, '['); assert.equal(ts[array].close, vector[1] - 1);
          wrap(ts[array].start, ts[ts[array].close].end, 'p13counts.arrayAllocations++');
          wrap(ts[i].start, ts[ts[i].close].end, 'p13counts.messageAllocations++'); staticMessages++;
        }
      }
      if (selectedAt(i) && ts[i].text === '(' && ts[ts[i].close + 1]?.text === '=' && ts[ts[i].close + 2]?.text === '>') {
        const body = ts[i].close + 3;
        assert.equal(ts[body]?.text, '{');
        const arrow = view.arrow([i, ts[body].close + 1]); assert.ok(arrow);
        wrap(ts[i].start, ts[arrow.end].end, 'p13counts.familyClosures++'); staticClosures++;
      }
    }
    insertions.sort((a, b) => b.at - a.at);
    for (const {at, text} of insertions) source = source.slice(0, at) + text + source.slice(at);
    source = once(source, 'function run_tail(f, x) {', 'function run_tail(f, x) {\n  p13counts.runTail++; p13counts.messageAllocations++;');
    source = once(source, 'x: [x]};', 'x: (p13counts.arrayAllocations++, [x])};');
    source = once(source, '    r = r.f(...r.x);', '    p13counts.dispatches++; p13counts.dispatchSlots += r.x.length;\n    r = r.f(...r.x);');
    source = 'let p13counts = {familyClosures:0,familyUnits:0,units:0,messageAllocations:0,arrayAllocations:0,runTail:0,dispatches:0,dispatchSlots:0};\n' + source;
    source += '\nexport function p13reset() {for (const key of Object.keys(p13counts)) p13counts[key]=0;} export function p13get() {return {...p13counts};}\n';
    const instrumented = path.join(out, name + '.mjs'); fs.writeFileSync(instrumented, source, {flag: 'wx'});
    variants.push({name, K: await import(pathToFileURL(instrumented))});
    report.variants.push({name, original: identity(file), instrumented: identity(instrumented), instrumentation: {staticClosures, staticUnits, staticMessages, arrays: 'Every counted message literal allocates exactly one x array; dispatchSlots counts array elements consumed.'}});
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
          const saved = baseline.familyClosures - counts.familyClosures;
          assert.ok(saved >= 0);
          for (const key of ['familyUnits', 'units', 'messageAllocations', 'arrayAllocations', 'runTail', 'dispatches', 'dispatchSlots'])
            assert.equal(baseline[key] - counts[key], saved, phase + ': one omitted selector must save exactly one ' + key);
        }
      }
      const resultFile = path.join(out, fixture.name + '-' + name + '.json'); fs.writeFileSync(resultFile, JSON.stringify(observed) + '\n');
      report.rows.push({n, variant: name, fixture: identity(fixtureFile), result: identity(resultFile), load: loadCounts, check: checkCounts, exactBaseline: true}); save();
    }
  }
  inputs.forEach(verifyIdentity); report.inputsVerified = true; report.complete = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
report.finished = new Date().toISOString(); save(); console.log(JSON.stringify(report));
