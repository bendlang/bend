// Diagnose host capture without changing the compiler, native helper or oracle.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';

const [projectArg, outArg, environmentLabel] = process.argv.slice(2);
assert.ok(['sandboxed', 'approved-escalated'].includes(environmentLabel));
const project = fs.realpathSync(projectArg), out = path.resolve(outArg);
fs.mkdirSync(out);
const hash = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity = file => ({file:fs.realpathSync(file), bytes:fs.statSync(file).size, sha256:hash(file)});
const clangRoot = path.join(project, 'build/phase1/clang/root');
const env = {...process.env};
for (const key of Object.keys(env)) {
  if (key.startsWith('BEND_') || ['NODE_OPTIONS', 'NODE_PATH'].includes(key)) delete env[key];
}
const selectedEnv = {
  CC:path.join(clangRoot, 'usr/bin/clang-16'),
  CPATH:path.join(clangRoot, 'usr/include'),
  LIBRARY_PATH:path.join(clangRoot, 'usr/lib/x86_64-linux-gnu'),
  LD_LIBRARY_PATH:path.join(clangRoot, 'usr/lib/x86_64-linux-gnu'),
};
Object.assign(env, selectedEnv);
const source = path.join(out, 'probe.c');
fs.writeFileSync(source, 'extern int puts(const char*); int main(void) { puts("phase30-native-ok"); return 0; }\n', {flag:'wx'});
const report = {
  kind:'phase30-native-spawn-diagnostic', complete:false, pass:false,
  environmentLabel, environmentLabelScope:'Invocation label; approval/sandbox boundary belongs to the outer tool call.',
  node:identity(process.execPath), nodeVersion:process.version,
  clang:identity(selectedEnv.CC), tool:identity(import.meta.filename), source:identity(source),
  environment:selectedEnv, rows:[],
};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
save();
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
function run(name, command, args, capture) {
  const stdout = path.join(out, name + '.stdout'), stderr = path.join(out, name + '.stderr');
  let a, b, result;
  try {
    if (capture === 'files') {a = fs.openSync(stdout, 'wx'); b = fs.openSync(stderr, 'wx');}
    result = spawnSync(command, args, {
      cwd:out, env, timeout:30000, maxBuffer:1048576,
      stdio:capture === 'files' ? ['ignore', a, b] : ['ignore', 'pipe', 'pipe'],
    });
  } finally {
    if (a !== undefined) fs.closeSync(a);
    if (b !== undefined) fs.closeSync(b);
  }
  if (capture === 'pipes') {
    fs.writeFileSync(stdout, result.stdout ?? Buffer.alloc(0), {flag:'wx'});
    fs.writeFileSync(stderr, result.stderr ?? Buffer.alloc(0), {flag:'wx'});
  }
  const e = result.error;
  const row = {
    name, command:[command, ...args], capture, pid:result.pid, status:result.status, signal:result.signal,
    error:e ? {name:e.name, message:e.message, code:e.code, errno:e.errno, syscall:e.syscall,
      path:e.path, spawnargs:e.spawnargs} : null,
    stdout:identity(stdout), stderr:identity(stderr),
    pass:result.status === 0 && result.signal === null && !e,
  };
  report.rows.push(row); save(); return row;
}
try {
  assert.equal(report.node.sha256, '41a74efb34cbde5c7632cdac0cf8bd1a14d0b8d73dc1e82755014d9a9ce70f5c');
  assert.equal(report.clang.sha256, '8a3f27cb0d8904a46986cbcc6437c2049939204d1c9f7caa3898c36ba067c0e2');
  for (const capture of ['pipes', 'files']) {
    const binary = path.join(out, capture + '.bin');
    const row = run(capture + '-compile', selectedEnv.CC, [source, '-o', binary], capture);
    row.binary = fs.existsSync(binary) ? identity(binary) : null; save();
    if (row.pass) {
      const executed = run(capture + '-execute', binary, [], capture);
      executed.outputMatches = fs.readFileSync(executed.stdout.file, 'utf8') === 'phase30-native-ok\n';
      executed.pass &&= executed.outputMatches; save();
    }
  }
  report.complete = true;
  report.pass = report.rows.length === 4 && report.rows.every(row => row.pass);
} catch (error) {
  report.error = String(error.stack ?? error);
}
save();
console.log(JSON.stringify({complete:report.complete, pass:report.pass, rows:report.rows.length}));
if (!report.pass) process.exitCode = 1;
