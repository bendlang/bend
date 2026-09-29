// Exact checked-image histories under one explicitly reviewed compatible host.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';
export {identity, verifyIdentity, supervise, requireExecution};
export const repo = path.resolve(import.meta.dirname, '../../../..');

export async function bindCandidate(bindingFile) {
  bindingFile = fs.realpathSync(bindingFile);
  const config = JSON.parse(fs.readFileSync(bindingFile));
  assert.deepEqual(Object.keys(config).sort(), ['baselineAttempt', 'candidateAttempt', 'hostReview']);
  const resolve = value => fs.realpathSync(path.resolve(path.dirname(bindingFile), value));
  const directories = [resolve(config.baselineAttempt), resolve(config.candidateAttempt)];
  const [parent, candidate] = await Promise.all(directories.map(verifyAttempt));
  const inputs = new Map(), add = file => {const value = identity(file); inputs.set(value.file, value); return value;};
  assert.equal(candidate.runtime.sha256, parent.runtime.sha256);
  assert.equal(candidate.base.sha256, parent.base.sha256);
  assert.equal(candidate.config.upstream, parent.config.upstream);
  for (const m of [parent, candidate]) assert.equal(m.artifactKind, 'derived-b1');
  const hosts = m => new Map(m.snapshot.sources.map(({frozen}) =>
    [path.relative(m.snapshot.root, frozen.file), frozen]).filter(([n]) => n.startsWith('tools/')));
  const old = hosts(parent), current = hosts(candidate);
  assert.deepEqual([...old.keys()].sort(), [...current.keys()].sort());
  const reviewFile = resolve(config.hostReview), review = JSON.parse(fs.readFileSync(reviewFile));
  assert.equal(review.pass, true);
  const changed = [...current].filter(([n, f]) => f.sha256 !== old.get(n).sha256).map(([n]) => n).sort();
  assert.deepEqual(review.changes.map(r => r.relative).sort(), changed);
  for (const row of review.changes) {
    for (const [item, expected] of [[row.before, old.get(row.relative)], [row.after, current.get(row.relative)]]) {
      verifyIdentity(item); assert.equal(item.sha256, expected.sha256);
      assert.equal(fs.realpathSync(item.file), expected.canonicalPath); add(item.file);
    }
    verifyIdentity(row.patch); add(row.patch.file);
  }
  const hostChecks = {mode: 'both APIs under the candidate snapshot host', review: add(reviewFile),
    changes: review.changes, reason: 'Term/span/load capability compatibility is explicit; complete paired result provenance is identical.'};
  for (const m of [parent, candidate]) for (const row of [m.api, m.checkedApi, m.base,
    m.runtime, m.node, m.bootstrapReport, m.derivationReport, ...m.artifacts,
    ...m.snapshot.sources.map(x => x.frozen)]) {verifyIdentity(row); add(row.file);}
  for (const f of [import.meta.filename, process.execPath, bindingFile,
    ...directories.map(d => path.join(d, 'attempt.json'))]) add(f);
  assert.equal(process.version, 'v24.18.0');
  const replay = () => {for (const row of inputs.values()) verifyIdentity(row);}; replay();
  return {parent, candidate, manifest: add(bindingFile), inputs, add, replay, hostChecks};
}

export async function prepareVariant(binding, name, directory, cpu) {
  const {parent, candidate, add} = binding;
  assert.ok(['baseline', 'candidate'].includes(name));
  const api = name === 'baseline' ? parent.api : candidate.api;
  fs.mkdirSync(directory);
  const project = path.join(directory, 'project'); fs.mkdirSync(project);
  for (const sub of ['src', 'tools']) fs.cpSync(path.join(candidate.snapshot.root, sub), path.join(project, sub), {recursive: true});
  for (const {frozen} of candidate.snapshot.sources) {
    const target = path.join(project, path.relative(candidate.snapshot.root, frozen.file));
    if (fs.existsSync(target)) {assert.equal(identity(target).sha256, frozen.sha256); add(target);}
  }
  const cacheDir = path.join(project, 'build/typed/cache'); fs.mkdirSync(cacheDir, {recursive: true});
  const environment = Object.fromEntries(Object.entries(process.env).filter(([key]) =>
    !key.startsWith('BEND_') && !['NODE_OPTIONS', 'NODE_PATH'].includes(key)));
  Object.assign(environment, {BEND_TYPED_API: api.file, BEND_TYPED_RUNTIME: parent.runtime.file,
    BEND_BASE: parent.base.file, BEND_UPSTREAM: parent.config.upstream, BEND_TYPED_TRACE: '1'});
  const preparation = await supervise('taskset', ['-c', String(cpu), process.execPath,
    '--stack-size=4096', '--max-old-space-size=4096', path.join(project, 'tools/typed-driver.mjs'),
    '--prepare-base'], {directory: path.join(directory, 'prepare-base'), env: environment, timeoutMs: 180000});
  fs.writeFileSync(path.join(directory, 'prepare-base.json'), JSON.stringify(preparation, null, 2) + '\n');
  requireExecution(preparation);
  const {validatedCache} = await import(pathToFileURL(path.join(candidate.snapshot.root, 'tools/development/workflow.mjs')));
  const cache = validatedCache(cacheDir, api.file, parent.base.file); add(cache.file);
  const adapter = path.join(project, 'tools/conformance/adapters/typed.mjs'); add(adapter);
  return {name, directory, project, adapter, api, cache, preparation, environment};
}
