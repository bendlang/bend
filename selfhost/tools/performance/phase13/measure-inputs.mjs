// Experimental-image lineage and unchanged private host setup; not an attempt manifest.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity, verifyIdentity, verifyAttempt, validatedCache} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

export {identity, verifyIdentity, validatedCache, supervise, requireExecution};
export const repo = path.resolve(import.meta.dirname, '../../../..');
export const baselineSha = '0975a4a805409cfd6a721f72cd4ffac6b207045cdecb8aa5ef04955297fcd697';
export async function bindCandidate(manifestFile) {
  manifestFile = fs.realpathSync(manifestFile);
  const candidate = JSON.parse(fs.readFileSync(manifestFile)), inputs = new Map();
  const add = file => {const value = identity(file); inputs.set(value.file, value); return value;};
  assert.equal(candidate.complete, true); assert.equal(candidate.inputsVerified, true);
  assert.equal(candidate.kind, 'phase13-structured-worker-candidate');
  const parent = await verifyAttempt(candidate.parentAttempt);
  assert.equal(parent.api.sha256, baselineSha);
  assert.deepEqual(candidate.baselineApi, parent.api);
  assert.deepEqual(candidate.checkedApi, parent.checkedApi);
  assert.deepEqual(candidate.base, parent.base); assert.deepEqual(candidate.runtime, parent.runtime);
  for (const row of [...candidate.inputs, ...candidate.helperInputs, candidate.api, candidate.helper, candidate.transformReportIdentity]) {
    verifyIdentity(row); add(row.file);
  }
  for (const file of [manifestFile, import.meta.filename, process.execPath, path.join(candidate.parentAttempt, 'attempt.json')]) add(file);
  assert.equal(process.version, 'v24.18.0');
  const helper = await import(pathToFileURL(candidate.helper.file));
  const replay = () => {
    for (const row of inputs.values()) verifyIdentity(row);
    const derived = helper.transform(fs.readFileSync(candidate.checkedApi.file, 'utf8'), candidate.options);
    assert.equal(derived.source, fs.readFileSync(candidate.api.file, 'utf8'), 'Experimental image does not replay');
    assert.deepEqual(derived.report, candidate.transformReport);
    assert.deepEqual(JSON.parse(fs.readFileSync(candidate.transformReportIdentity.file)), candidate.transformReport);
    for (const row of inputs.values()) verifyIdentity(row);
  };
  replay();
  return {candidate, parent, manifest: add(manifestFile), inputs, add, replay};
}

export async function prepareVariant(binding, name, directory, cpu) {
  const {parent, candidate, add} = binding, api = name === 'baseline' ? parent.api : candidate.api;
  assert.ok(['baseline', 'candidate'].includes(name));
  fs.mkdirSync(directory); const project = path.join(directory, 'project'); fs.mkdirSync(project);
  for (const sub of ['src', 'tools']) fs.cpSync(path.join(parent.snapshot.root, sub), path.join(project, sub), {recursive: true});
  for (const {frozen} of parent.snapshot.sources) {
    const target = path.join(project, path.relative(parent.snapshot.root, frozen.file));
    if (fs.existsSync(target)) {assert.equal(identity(target).sha256, frozen.sha256, 'Private host changed'); add(target);}
  }
  const cacheDir = path.join(project, 'build/typed/cache'); fs.mkdirSync(cacheDir, {recursive: true});
  const environment = Object.fromEntries(Object.entries(process.env).filter(([key]) => !key.startsWith('BEND_') && !['NODE_OPTIONS', 'NODE_PATH'].includes(key)));
  Object.assign(environment, {BEND_TYPED_API: api.file, BEND_TYPED_RUNTIME: parent.runtime.file, BEND_BASE: parent.base.file, BEND_UPSTREAM: parent.config.upstream, BEND_TYPED_TRACE: '1'});
  let preparation = null;
  if (name === 'baseline') {
    const original = validatedCache(path.join(parent.snapshot.root, 'build/typed/cache'), api.file, parent.base.file);
    add(original.file); fs.copyFileSync(original.file, path.join(cacheDir, path.basename(original.file)));
  } else {
    preparation = await supervise('taskset', ['-c', String(cpu), process.execPath, '--stack-size=4096', '--max-old-space-size=4096', path.join(project, 'tools/typed-driver.mjs'), '--prepare-base'], {directory: path.join(directory, 'prepare-base'), env: environment, timeoutMs: 180000});
    fs.writeFileSync(path.join(directory, 'prepare-base.json'), JSON.stringify(preparation, null, 2) + '\n');
    requireExecution(preparation);
  }
  const cache = validatedCache(cacheDir, api.file, parent.base.file); add(cache.file);
  const adapter = path.join(project, 'tools/conformance/adapters/typed.mjs'); add(adapter);
  return {name, directory, project, adapter, api, cache, preparation, environment};
}
