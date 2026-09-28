import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { supervise } from '../../development/process.mjs';

const project = path.resolve(import.meta.dirname, '../../..');
const api = path.resolve(process.argv[2]), out = path.resolve(process.argv[3]), cpu = process.argv[4] ?? '1';
fs.mkdirSync(out);
const original = fs.readFileSync(api, 'utf8');
let instrumented = original;
const found = [];
for (const name of ['j_constructor_mode', 'j_constructor', 'j_constructor_literal', 'j_literal_typed', 'j_literal', 'j_nat', 'j_word', 'j_string', 'j_find_ctor']) {
  let matches = 0;
  instrumented = instrumented.replace(new RegExp('function \\$' + name + '\\$\\([^\\n]*\\) \\{'), text => {
    matches++; found.push(name);
    return text + '\n globalThis.__structureCounts["' + name + '"]=(globalThis.__structureCounts["' + name + '"]??0)+1;';
  });
  if (matches !== 1 && name !== 'j_constructor') throw Error('Missing/nonunique helper: ' + name);
}
const generated = path.join(out, 'instrumented.mjs');
fs.writeFileSync(generated, 'globalThis.__structureCounts={};\n' + instrumented);
const worker = path.join(out, 'worker.mjs'); fs.copyFileSync(path.join(import.meta.dirname, 'structure-worker.mjs'), worker);
const identity = file => ({ file, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') });
const cases = [];
for (const n of [8, 16, 32, 64]) {
  cases.push({ name: 'nat-' + n, source: `import Base\n\ndef down(n: Nat) -> Nat:\n  match n:\n    case ${n}n:\n      down(${n - 1}n)\n    case _:\n      n\n\ndef main() -> Nat:\n  Nat.add(down(${n}n), down(7n))\n`, expected: String(n + 6) + 'n' });
  cases.push({ name: 'string-' + n, source: `import Base\n\ndef main() -> String:\n  "${'a'.repeat(n)}"\n`, expected: '"' + 'a'.repeat(n) + '"' });
}
const report = { scope: 'Instrumented checked-image JS emitter entries, successful checked emission and exact actual output. Diagnostic concurrent times are not speed ratios.', cpu, resources: { stackKiB: 4096, heapMiB: 4096, timeoutMs: 30000 }, found, inputs: [api, generated, worker, import.meta.filename, process.execPath, path.join(project, 'tools/typed-driver.mjs'), path.join(project, 'dist/base.bend')].map(identity), rows: [] };
for (const fixture of cases) {
  const directory = path.join(out, fixture.name); fs.mkdirSync(directory);
  const file = path.join(directory, 'main.bend'); fs.writeFileSync(file, fixture.source);
  const execution = await supervise('taskset', ['-c', cpu, process.execPath, '--stack-size=4096', '--max-old-space-size=4096', worker, path.join(project, 'tools/typed-driver.mjs'), file, directory, fixture.expected], { directory: path.join(directory, 'process'), env: { ...process.env, BEND_TYPED_API: generated, BEND_BASE: path.join(project, 'dist/base.bend') }, timeoutMs: 30000 });
  const resultFile = path.join(directory, 'report.json');
  report.rows.push({ name: fixture.name, input: identity(file), execution, result: fs.existsSync(resultFile) ? JSON.parse(fs.readFileSync(resultFile, 'utf8')) : null });
  fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify({ name: fixture.name, pass: report.rows.at(-1).result?.pass, counts: report.rows.at(-1).result?.emission?.counts }));
}
report.inputsVerified = report.inputs.every(input => identity(input.file).sha256 === input.sha256);
report.pass = report.inputsVerified && report.rows.every(row => row.result?.pass && row.execution.exitCode === 0 && row.execution.signal === null && !row.execution.error && !row.execution.timedOut && !row.execution.overflow);
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
if (!report.pass) process.exitCode = 1;
