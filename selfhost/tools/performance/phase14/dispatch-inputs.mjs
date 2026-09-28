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
export async function bindCandidate(attemptDirectory) {
  const directory=fs.realpathSync(attemptDirectory),candidate=await verifyAttempt(directory),parent=await verifyAttempt(path.join(repo,'selfhost/build/phase12/integrated-03'));
  const inputs=new Map(),add=file=>{const value=identity(file);inputs.set(value.file,value);return value;};
  assert.equal(parent.api.sha256,baselineSha);assert.equal(candidate.runtime.sha256,parent.runtime.sha256);assert.equal(candidate.base.sha256,parent.base.sha256);assert.equal(candidate.config.upstream,parent.config.upstream);
  assert.equal(candidate.artifactKind,'derived-b1');
  for(const m of [parent,candidate]){
    for(const row of [m.api,m.checkedApi,m.base,m.runtime,m.node,m.bootstrapReport,m.derivationReport,...m.artifacts,...m.snapshot.sources.map(x=>x.frozen)]){verifyIdentity(row);add(row.file);}
  }
  for(const file of [import.meta.filename,process.execPath,path.join(directory,'attempt.json'),path.join(repo,'selfhost/build/phase12/integrated-03/attempt.json')])add(file);
  assert.equal(process.version,'v24.18.0');
  const replay=()=>{for(const row of inputs.values())verifyIdentity(row);};replay();
  return {candidate,parent,manifest:add(path.join(directory,'attempt.json')),inputs,add,replay};
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
