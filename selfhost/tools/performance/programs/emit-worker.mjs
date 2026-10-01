// Checked acquisition only. A fresh process owns one source and its compiler API.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {verifyAttempt, identity, verifyIdentity} from '../../development/workflow.mjs';
import {verifyRelease} from '../../development/release.mjs';

const [selection, inputArgument, outputArgument] = process.argv.slice(2);
assert.ok(selection && inputArgument && outputArgument,
  'Usage: emit-worker.mjs installed|ATTEMPT|upstream:CHECKOUT SOURCE NEW_MODULE');
const project = path.resolve(import.meta.dirname, '../../..');
const input = fs.realpathSync(inputArgument), output = path.resolve(outputArgument);
const report = {kind:'bend-program-checked-emission', schemaVersion:1, complete:false,
  input:{...identity(input), bytes:fs.statSync(input).size}, producer:identity(import.meta.filename), node:process.version,
  verifiers:['workflow.mjs','release.mjs'].map(name => identity(path.join(project, 'tools/development', name)))};
const begin = performance.now();
try {
  // Direct use has the same explicit compiler selection as supervised use.
  for (const key of Object.keys(process.env)) if (key.startsWith('BEND_')) delete process.env[key];
  const catalog = JSON.parse(fs.readFileSync(path.join(import.meta.dirname, 'catalog.json'), 'utf8'));
  let api, runtime, base, driver, verify, code;
  if (selection.startsWith('upstream:')) {
    const upstream = fs.realpathSync(selection.slice('upstream:'.length));
    const names = ['bend2/bend.ts', 'bend2/comp.ts', 'bend2/base.bend'];
    const git = (...args) => execFileSync('git', ['-C', upstream, ...args], {encoding:'utf8'}).trim();
    const check = () => {
      assert.equal(git('rev-parse', 'HEAD'), catalog.upstreamCommit, 'Upstream checkout must match the catalog pin');
      assert.equal(git('diff', '--name-only', 'HEAD', '--', ...names), '', 'Pinned TypeScript compiler sources are modified');
    };
    check();
    report.compiler = {kind:'checked-pinned-typescript', upstreamCommit:catalog.upstreamCommit,
      sources:names.map(name => identity(path.join(upstream, name)))};
    const B = await import(pathToFileURL(path.join(upstream, 'bend2/bend.ts')));
    const C = await import(pathToFileURL(path.join(upstream, 'bend2/comp.ts')));
    const book = B.book_nil(); await B.book_load(book, input, '', new Map()); B.book_valid(book);
    assert.equal(book.hols, 0);
    code = C.js_lib(book, true);
    report.observation = {status:'ok', checked:true, mode:'library'};
    verify = () => { check(); report.compiler.sources.forEach(verifyIdentity); };
  } else if (selection === 'installed') {
    const release = verifyRelease(project);
    report.release = identity(path.join(project, 'dist/release.json'));
    report.compiler = {kind:'installed-checked-release', upstreamCommit:release.lineage.upstreamRevision,
      sourceSha256:release.sourceSha256, artifact:release.artifact};
    api = path.join(project, 'dist/typed-api.mjs');
    runtime = path.join(project, 'src/runtime.mjs');
    base = path.join(project, 'dist/base.bend');
    driver = path.join(project, 'tools/typed-driver.mjs');
    verify = () => { verifyIdentity(report.release); verifyRelease(project); };
  } else {
    const attempt = fs.realpathSync(selection), manifest = await verifyAttempt(attempt);
    assert.equal(manifest.checked, true, 'Attempt must contain a checked compiler');
    report.attempt = identity(path.join(attempt, 'attempt.json'));
    const bootstrap = JSON.parse(fs.readFileSync(manifest.bootstrapReport.file, 'utf8'));
    report.compiler = {kind:'checked-development-attempt', upstreamCommit:bootstrap.revision,
      sourceSha256:bootstrap.sourceSha256, artifact:manifest.artifactKind};
    api = manifest.api.file; runtime = manifest.runtime.file; base = manifest.base.file;
    driver = path.join(manifest.snapshot.root, 'tools/typed-driver.mjs');
    verify = async () => { verifyIdentity(report.attempt); await verifyAttempt(attempt); };
  }
  assert.equal(report.compiler.upstreamCommit, catalog.upstreamCommit, 'Different compiler target requires a new benchmark reference');
  if (!selection.startsWith('upstream:')) {
    report.compiler.api = identity(api); report.compiler.runtime = identity(runtime);
    report.compiler.base = identity(base); report.compiler.driver = identity(driver);
    process.env.BEND_TYPED_API = api; process.env.BEND_TYPED_RUNTIME = runtime;
    process.env.BEND_BASE = base;
    const D = await import(pathToFileURL(driver));
    const result = await D.inspect(input, {mode:'library'});
    const {code:emitted, ...observation} = result;
    code = emitted; report.observation = observation;
    assert.equal(result.status, 'ok'); assert.equal(result.checked, true);
    for (const key of ['api','runtime','base','driver']) verifyIdentity(report.compiler[key]);
  }
  assert.equal(typeof code, 'string');
  verifyIdentity(report.input); await verify();
  report.verifiers.forEach(verifyIdentity);
  fs.writeFileSync(output, code, {flag:'wx'});
  report.output = identity(output); report.complete = true;
} catch (error) {
  report.error = error.stack ?? String(error); process.exitCode = 1;
}
report.elapsedMs = performance.now() - begin;
report.timingScope = 'Acquisition, verification and checking only; excluded from generated-program execution budgets.';
fs.writeFileSync(output + '.json', JSON.stringify(report, null, 2) + '\n', {flag:'wx'});
console.log(JSON.stringify({complete:report.complete, output, elapsedMs:report.elapsedMs, error:report.error}));
