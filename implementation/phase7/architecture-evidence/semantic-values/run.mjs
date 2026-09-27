import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {assemble} from '../../../../selfhost/tools/assemble.mjs';

const repo = path.resolve(import.meta.dirname, '../../../..');
const selfhost = path.join(repo, 'selfhost');
const upstream = path.join(selfhost, '.bootstrap/upstream');
const [action, supplied] = process.argv.slice(2);
if (!['prepare', 'build', 'test'].includes(action) || !supplied) {
  throw Error('usage: node run.mjs prepare|build|test FRESH_ATTEMPT');
}
const dir = path.resolve(supplied);
const hash = data => crypto.createHash('sha256').update(data).digest('hex');
const write = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2) + '\n');
const roots = ['wnf', 'strong', 'compare', 'sv_supported', 'sv_observe', 'sv_observe_head', 'sv_equal'];
const expectedRevision = '6018e28ecc67cf1fffc0c20c64b11023474c2df8';
const revision = () => {
  const child = spawnSync('git', ['-C', upstream, 'rev-parse', 'HEAD'], {encoding: 'utf8'});
  if (child.status !== 0) throw Error('Cannot resolve pinned upstream revision');
  return child.stdout.trim();
};
const identity = file => ({file, sha256: hash(fs.readFileSync(file))});
const verify = manifest => {
  if (revision() !== manifest.upstream || manifest.upstream !== expectedRevision) throw Error('Pinned upstream revision changed');
  for (const input of [...manifest.inputs.map(input => ({file: input.target, sha256: input.sha256})), ...manifest.identities]) {
    if (hash(fs.readFileSync(input.file)) !== input.sha256) throw Error('Frozen input changed: ' + input.file);
  }
};

if (action === 'prepare') {
  if (fs.existsSync(dir)) throw Error('Fresh attempt directory required');
  fs.mkdirSync(path.join(dir, 'sources'), {recursive: true});
  const sources = [
    ...['term', 'index', 'normalize', 'graph'].map(name => path.join(selfhost, 'src/core', name + '.bend')),
    path.join(import.meta.dirname, 'semantic-values.bend'),
  ];
  const inputs = [];
  for (const source of sources) {
    const bytes = fs.readFileSync(source);
    const target = path.join(dir, 'sources', path.basename(source));
    fs.writeFileSync(target, bytes);
    inputs.push({source, target, bytes: bytes.length, sha256: hash(bytes)});
  }
  for (const name of ['run.mjs', 'controls.mjs', 'demand-witness.mjs']) {
    fs.copyFileSync(path.join(import.meta.dirname, name), path.join(dir, name));
  }
  const assembly = assemble(inputs.map(input => input.target), path.join(dir, 'component.bend'));
  const actualRevision = revision();
  if (actualRevision !== expectedRevision) throw Error('Wrong upstream checkout: ' + actualRevision);
  write(path.join(dir, 'inputs.json'), {
    kind: 'P7-A02 semantic-value feasibility component',
    scope: 'Checked stage0 component; not self-hosted B1 or a compiler release',
    prepared: new Date().toISOString(), node: process.version, executable: process.execPath,
    upstream: actualRevision, roots, inputs, assembly, cpu: '0',
    identities: [process.execPath, ...['bend.ts', 'comp.ts', 'base.bend'].map(file => path.join(upstream, 'bend2', file)),
      ...['tools/assemble.mjs', 'tools/stage0-library.mjs'].map(file => path.join(selfhost, file)),
      ...['run.mjs', 'controls.mjs', 'demand-witness.mjs', 'component.bend'].map(file => path.join(dir, file))].map(identity),
  });
  console.log(JSON.stringify({dir, assembly, roots}));
} else {
  const manifest = JSON.parse(fs.readFileSync(path.join(dir, 'inputs.json')));
  verify(manifest);
  const args = action === 'build'
    ? ['--stack-size=4096', '--max-old-space-size=4096', path.join(selfhost, 'tools/stage0-library.mjs'), path.join(dir, 'component.bend'), path.join(dir, 'api.mjs'), ...manifest.roots]
    : ['--stack-size=4096', '--max-old-space-size=4096', path.join(dir, 'controls.mjs'), path.join(dir, 'api.mjs'), path.join(dir, 'controls.json')];
  const resultFile = path.join(dir, action + '.json');
  if (fs.existsSync(resultFile)) throw Error('Preserve original attempt result; prepare a new attempt');
  const started = performance.now();
  const commandArgs = ['-c', manifest.cpu, process.execPath, ...args];
  const child = spawnSync('taskset', commandArgs, {
    cwd: selfhost, env: {...process.env, BEND_UPSTREAM: upstream, BEND_BASE: path.join(upstream, 'bend2/base.bend')}, encoding: 'utf8',
    timeout: action === 'build' ? 120000 : 60000, maxBuffer: 16 * 1024 * 1024,
  });
  fs.writeFileSync(path.join(dir, action + '.stdout'), child.stdout || '');
  fs.writeFileSync(path.join(dir, action + '.stderr'), child.stderr || '');
  let identityError = null;
  try { verify(manifest); } catch (error) { identityError = error.message; }
  const result = {action, command: 'taskset', args: commandArgs, elapsedMs: performance.now() - started,
    exitCode: child.status, signal: child.signal, error: child.error?.message || null,
    identityError, pass: child.status === 0 && !child.error && !identityError,
    timingScope: 'Descriptive elapsed duration; not a controlled performance comparison'};
  if (fs.existsSync(path.join(dir, 'api.mjs'))) {
    const bytes = fs.readFileSync(path.join(dir, 'api.mjs'));
    result.api = {bytes: bytes.length, sha256: hash(bytes)};
  }
  write(resultFile, result);
  console.log(JSON.stringify(result));
  if (!result.pass) process.exitCode = 1;
}
