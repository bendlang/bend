// Finite paired contracts for private membership; no benchmark or public API claim.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [parentArgument, candidateArgument, outputArgument] = process.argv.slice(2);
assert(parentArgument && candidateArgument && outputArgument,
  'Usage: membership-controls.mjs PARENT_API CANDIDATE_API NEW_DIRECTORY');
const out = path.resolve(outputArgument); fs.mkdirSync(out);
const identity = file => ({file: fs.realpathSync(file), bytes: fs.statSync(file).size,
  sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report = {kind: 'phase24-membership-direct-controls', complete: false, pass: false,
  scope: 'Private unchecked exports appended to unchanged parent/candidate API prefixes. Finite exact membership and demand/error observations; not universal foreign-object equivalence, frontend conformance or performance.',
  inputs: [identity(parentArgument), identity(candidateArgument), identity(import.meta.filename)],
  examples: [], generated: {cases: 0}, deep: [], demand: []};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs')); save();
try {
  const imports = [];
  for (const [label, argument] of [['parent', parentArgument], ['candidate', candidateArgument]]) {
    const original = fs.readFileSync(argument);
    assert(original.includes(Buffer.from('function $has_name$(')));
    const suffix = '\nexport const __membership=(names,name)=>run_loop($has_name$(names,name));\n';
    const file = path.join(out, label + '-extension.mjs');
    fs.writeFileSync(file, Buffer.concat([original, Buffer.from(suffix)]), {flag: 'wx'});
    assert(fs.readFileSync(file).subarray(0, original.length).equals(original));
    report[label + 'Extension'] = {...identity(file), originalPrefixBytes: original.length, originalPrefixUnchanged: true};
    imports.push(await import(pathToFileURL(file)));
  }
  const [parent, candidate] = imports;
  const nil = () => ({$: 'Nil'});
  const list = values => values.reduceRight((tail, head) => ({$: 'Con', head, tail}), nil());
  const check = (values, query) => {
    const expected = values.includes(query);
    const old = parent.__membership(list(values), query), actual = candidate.__membership(list(values), query);
    assert.equal(old, expected); assert.equal(actual, expected); return actual;
  };
  const examples = [
    ['empty', [], 'x'], ['empty-string-hit', [''], ''], ['singleton-hit', ['x'], 'x'],
    ['singleton-miss', ['x'], 'y'], ['first-hit', ['a', 'b', 'c'], 'a'],
    ['middle-hit', ['a', 'b', 'c'], 'b'], ['last-hit', ['a', 'b', 'c'], 'c'],
    ['duplicates', ['a', 'b', 'a', 'a'], 'a'], ['duplicates-miss', ['a', 'a'], 'b'],
    ['prefix-is-not-equality', ['abc', 'abcd'], 'ab'], ['embedded-nul', ['a\0b', 'ab'], 'a\0b'],
    ['unicode', ['λ', '漢字', '😀'], '漢字'], ['astral', ['λ', '漢字', '😀'], '😀'],
    ['normalization-distinction', ['é'], 'e\u0301'], ['lone-high-surrogate', ['\ud800'], '\ud800'],
    ['lone-low-surrogate', ['\udc00'], '\udc00'], ['surrogates-remain-distinct', ['\ud800'], '\udc00'],
    ['constructor-spelling', ['Con', 'Nil', 'Absent'], 'Nil']
  ];
  for (const [name, values, query] of examples)
    report.examples.push({name, length: values.length, query, result: check(values, query), pass: true});
  const alphabet = ['', 'a', 'b', 'aa', 'λ', '漢', '😀', '\ud800'];
  for (let i = 0; i < 128; i++) {
    const values = Array.from({length: i % 13}, (_, j) => alphabet[(i * 3 + j * 5) % alphabet.length]);
    for (const query of [...alphabet, 'missing']) { check(values, query); report.generated.cases++; }
  }
  for (const length of [32, 256, 1000, 6000, 10000]) {
    const values = Array.from({length}, (_, i) => 'name' + i);
    for (const query of ['name0', 'name' + (length - 1), 'absent'])
      report.deep.push({length, query, result: check(values, query), pass: true});
  }
  const observe = (api, build, query) => {
    const accesses = []; let result, error;
    try { result = api.__membership(build(accesses), query); }
    catch (e) { error = {name: e.name, message: e.message}; }
    return {result, error, accesses};
  };
  const watched = (log, label, head, tail) => ({
    get $() { log.push(label + '.$'); return 'Con'; },
    get head() { log.push(label + '.head'); return head; },
    get tail() { log.push(label + '.tail'); return tail; }
  });
  const poison = log => ({get $() { log.push('poison.$'); throw Error('unvisited tail demanded'); }});
  const demands = [
    ['first-hit-skips-malformed-tail', log => watched(log, 'first', 'hit', poison(log)), 'hit'],
    ['second-hit-skips-malformed-tail', log => watched(log, 'first', 'miss', watched(log, 'second', 'hit', poison(log))), 'hit'],
    ['missing-demands-malformed-tail', log => watched(log, 'first', 'miss', poison(log)), 'absent'],
    ['empty-list-does-not-read-fields', log => ({$: 'Nil', get head() { log.push('head'); throw Error('Nil.head'); }, get tail() { log.push('tail'); throw Error('Nil.tail'); }}), 'anything'],
    ['matching-head-tail-property-demand', log => ({$: 'Con', head: 'hit', get tail() { log.push('root.tail'); throw Error('tail property read'); }}), 'hit'],
    ['head-before-tail-order', log => ({$: 'Con', get head() { log.push('root.head'); throw Error('head property read'); }, get tail() { log.push('root.tail'); throw Error('tail property read'); }}), 'hit'],
    ['ordinary-missing-access-order', log => watched(log, 'first', 'a', watched(log, 'second', 'b', nil())), 'absent']
  ];
  for (const [name, build, query] of demands) {
    const expected = observe(parent, build, query), actual = observe(candidate, build, query);
    assert.deepEqual(actual, expected, name);
    if (name.includes('skips-malformed')) { assert.equal(actual.result, true); assert(!actual.accesses.includes('poison.$')); }
    if (name === 'missing-demands-malformed-tail') assert.equal(actual.error?.message, 'unvisited tail demanded');
    report.demand.push({name, parent: expected, candidate: actual, pass: true});
  }
  for (const item of report.inputs) assert.deepEqual(identity(item.file), item);
  report.complete = true; report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, examples: report.examples.length,
  generated: report.generated.cases, deep: report.deep.length, demand: report.demand.length, error: report.error}));
