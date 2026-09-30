// Acquire an unchanged complete JS program, separately from runtime measurement.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt, identity, verifyIdentity} from '../../development/workflow.mjs';

const [variant, attemptArgument, inputArgument, outputArgument] = process.argv.slice(2);
assert.ok(['upstream', 'selfhost'].includes(variant));
const input = fs.realpathSync(inputArgument), output = path.resolve(outputArgument);
const root = path.resolve(import.meta.dirname, '../../..');
const report = {kind:'phase28-checked-program-emission', variant, complete:false,
  input:identity(input), started:new Date().toISOString()};
const begin = performance.now();
try {
  let code;
  if (variant === 'upstream') {
    const upstream = path.join(root, '.bootstrap/upstream-phase23/bend2');
    report.compiler = ['bend.ts','comp.ts','base.bend'].map(f => identity(path.join(upstream,f)));
    const B = await import(pathToFileURL(path.join(upstream, 'bend.ts')));
    const C = await import(pathToFileURL(path.join(upstream, 'comp.ts')));
    const book = B.book_nil();
    await B.book_load(book, input, '', new Map());
    B.book_valid(book);
    assert.equal(book.hols, 0);
    report.checked = true;
    code = C.js_book(book);
    report.compiler.forEach(verifyIdentity);
  } else {
    const attempt = path.resolve(attemptArgument), m = await verifyAttempt(attempt);
    report.attempt = identity(path.join(attempt, 'attempt.json'));
    report.api = m.api; report.runtime = m.runtime; report.base = m.base;
    report.driver = identity(path.join(m.snapshot.root, 'tools/typed-driver.mjs'));
    process.env.BEND_TYPED_API = m.api.file;
    process.env.BEND_TYPED_RUNTIME = m.runtime.file;
    process.env.BEND_BASE = m.base.file;
    const D = await import(pathToFileURL(report.driver.file));
    const result = await D.inspect(input, {mode:'compile'});
    const {code:emitted, ...observation} = result;
    report.observation = observation;
    assert.equal(result.status, 'ok');
    assert.equal(result.checked, true);
    report.checked = true;
    code = emitted;
    verifyIdentity(report.attempt);
    await verifyAttempt(attempt);
  }
  fs.writeFileSync(output, code, {flag:'wx'});
  report.output = identity(output);
  verifyIdentity(report.input);
  report.complete = true;
} catch (error) {
  report.error = error.stack ?? String(error);
  process.exitCode = 1;
}
report.elapsedMs = performance.now() - begin;
report.timingScope = 'Descriptive checked emission acquisition only; not compiler throughput.';
fs.writeFileSync(output + '.json', JSON.stringify(report,null,2) + '\n', {flag:'wx'});
console.log(JSON.stringify(report));
