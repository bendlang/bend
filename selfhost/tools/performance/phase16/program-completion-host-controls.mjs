// Exercise the frozen host's public inspection route independently of checker internals.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt, identity, verifyIdentity} from '../../development/workflow.mjs';

const [attemptArg, outArg] = process.argv.slice(2);
const out = path.resolve(outArg), attempt = await verifyAttempt(path.resolve(attemptArg));
fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const hostFile = path.join(attempt.snapshot.root, 'tools/typed-driver.mjs');
const host = await import(pathToFileURL(hostFile));
const fixture = path.join(out, 'input.bend');
fs.writeFileSync(fixture, 'def main() -> Type:\n  Type\n');
const inputs = [import.meta.filename, hostFile, process.execPath, path.join(attempt.snapshot.root, 'tools/compiler-abi.mjs'), fixture].map(identity);
const report = {kind: 'program-completion-host-routing', complete: false, pass: false, inputs, rows: [],
  scope: 'Actual frozen public inspect() with explicit semantic stubs. Checks host routing and short-circuiting; real compiler semantics are a separate paired gate.'};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
const nil = {$: 'Nil'}, sourceBook = {$: 'Con', head: {name: 'source-marker'}, tail: nil};
const finalBook = {$: 'Con', head: {name: 'materialized-marker'}, tail: nil};
const cases = [
  {name: 'historical-no-capability', absent: true, expect: ['legacy', 'todos', 'specialize', 'report', 'has-main-final']},
  {name: 'historical-abi0', abi: 0, expect: ['legacy', 'todos', 'specialize', 'report', 'has-main-final']},
  {name: 'historical-abi1', abi: 1, expect: ['diagnostic', 'todos', 'specialize', 'report', 'has-main-final']},
  {name: 'program-abi2', abi: 2, expect: ['program', 'report', 'has-main-final']},
  {name: 'legacy-todo-short-circuit', abi: 1, todos: 2, expect: ['diagnostic', 'todos'], error: '2 TODOs found.'},
  {name: 'program-error-short-circuit', abi: 2, error: 'program failure', expect: ['program', 'render']},
  {name: 'program-missing-entry', abi: 2, missing: true, expect: [], error: 'Compiler checker-result ABI 2 requires check_program_diagnostic'},
  ...[3, -1, '2'].map(abi => ({name: 'unknown-' + typeof abi + '-' + abi, abi, expect: [], error: 'Unsupported compiler checker-result ABI: ' + abi})),
];
save();
try {
  for (const item of cases) {
    const calls = [];
    const api = {
      f_parse: () => ({book: nil, imports: nil, error: ''}),
      f_load_graph: () => ({book: sourceBook, error: ''}),
      check_book: book => {assert.equal(book, sourceBook); calls.push('legacy'); return '';},
      check_book_diagnostic: book => {assert.equal(book, sourceBook); calls.push('diagnostic'); return {error: '', book, diagnostic: {}};},
      diagnostic_render: result => {calls.push('render'); return 'Error: ' + result.error;},
      driver_todos: book => {assert.equal(book, sourceBook); calls.push('todos'); return item.todos ?? 0;},
      specialize_book: book => {assert.equal(book, sourceBook); calls.push('specialize'); return {book: finalBook};},
      specialized_error: () => '',
      specialized_book: result => result.book,
      driver_report: book => {assert.equal(book, sourceBook); calls.push('report'); return 'ALL PROOFS CHECK\n';},
      driver_bad_names: () => nil,
      driver_has_main: book => {assert.equal(book, finalBook); calls.push('has-main-final'); return true;},
    };
    if (!item.absent) api.compiler_check_result_abi = () => item.abi;
    if (!item.missing) api.check_program_diagnostic = (book, validated, origins) => {
      assert.equal(book, sourceBook); assert.deepEqual(validated, nil); assert.deepEqual(origins, nil);
      calls.push('program'); return {error: item.name === 'program-error-short-circuit' ? item.error : '', book: finalBook, diagnostic: {}};
    };
    const result = await host.inspect(fixture, {api, mode: 'check'});
    const row = {name: item.name, calls, result, pass: false};
    report.rows.push(row); save();
    assert.deepEqual(calls, item.expect, item.name);
    assert.equal(result.phase, 'check', item.name);
    assert.equal(result.status, item.error ? 'error' : 'ok', item.name);
    if (item.error) assert.ok(result.diagnostic.includes(item.error), item.name);
    row.pass = true; save();
  }
  inputs.forEach(verifyIdentity); await verifyAttempt(path.resolve(attemptArg));
  report.complete = true; report.pass = true;
} catch (error) {report.error = String(error.stack ?? error); process.exitCode = 1;}
save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, rows: report.rows.length, error: report.error}));
