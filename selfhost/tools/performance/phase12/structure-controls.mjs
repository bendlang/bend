import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { supervise } from '../../development/process.mjs';

const project = path.resolve(import.meta.dirname, '../../..'), baseline = path.resolve(process.argv[2]), candidate = path.resolve(process.argv[3]), out = path.resolve(process.argv[4]); fs.mkdirSync(out);
const cpu = process.env.STRUCTURE_CPU ?? '1';
if (!/^\d+$/.test(cpu)) throw Error('STRUCTURE_CPU must identify one CPU');
const cases = [], pre = 'import Base\n\n';
const add = (name, source, expectedOutput, options = {}) => { const file = path.join(out, name + '.bend'); fs.writeFileSync(file, source); cases.push({ name, file, expectedStatus: 'ok', expectedOutput, ...options }); };
for (const [name, relative, expectedOutput] of [
  ['erased-constructor', 'check/erased_ctor_field.bend', '7n\n'],
  ['u32-patterns', 'compile/u32_literal_word.bend', '94 q\n'],
  ['f32-patterns', 'compile/f32_literal_word.bend', '4 10\n'],
  ['mixed-readback', 'show/literal_readback.bend', "([7, 7, 7], (1, 2n, 'c'), [[True{}], []], [3, 3], [])\n"],
]) cases.push({ name, file: path.join(project, '.bootstrap/upstream-phase8/tests', relative), expectedStatus: 'ok', expectedOutput });
add('unicode', pre + 'def main() -> List<String>:\n  ["", "😀é", "a" ++ "b"]\n', '["", "😀é", "ab"]\n');
add('dynamic-string', pre + 'def tail() -> String:\n  "bc"\n\ndef main() -> String:\n  SCon{Chr{97}, tail()}\n', '"abc"\n');
add('type-alias', pre + 'def Text() -> Type:\n  String\n\ndef main() -> Text:\n  "label"\n', '"label"\n');
add('dependent-alias', pre + 'type Box<-A: Type> is Type:\n  Boxed{value: A}\n\ndef Family() -> Type:\n  Box<Nat>\n\ndef take(b: Family) -> Nat:\n  match b:\n    case Boxed{x}: x\n\ndef main() -> Nat:\n  take(Boxed{3n})\n', '3n\n');
add('invalid-char', pre + 'def main() -> Char:\n  Chr{55296}\n', 'bend: 55296 is not a Unicode scalar value\n', { expectedExit: 1 });
add('invalid-string-order', pre + 'def main() -> String:\n  SCon{Chr{55296}, SCon{Chr{55297}, SNil{}}}\n', 'bend: 55296 is not a Unicode scalar value\n', { expectedExit: 1 });
const names = ['True', 'False', 'Zero', 'Succ', 'SNil', 'SCon', 'Chr', 'Tuple', 'ALeaf', 'ANode'];
add('owned-constructors', 'type Flag is Data:\n  Up{}\n  Down{}\n\ntype Foo is Data:\n' + names.map(name => '  ' + name + '{+value: Flag}\n').join('') + '\ndef pick(f: Foo) -> Flag:\n  match f:\n' + names.map(name => '    case ' + name + '{value}: value\n').join('') + '\n' + names.map((name, i) => 'def make' + i + '() -> Foo:\n  ' + name + '{Up{}}\n').join('\n'), undefined, { mode: 'library', libraryNames: names });
for (const [name, expectedOutput, expectedExit] of [['erased-overflow', '7n\n', 0], ['unused-live-overflow', 'bend: a Nat past the largest immediate 2^48-1\n', 1]]) cases.push({ name, file: path.join(project, 'build/phase11/pattern-fixtures-01', name + '.bend'), expectedStatus: 'ok', expectedOutput, expectedExit });
cases.push({ name: 'dynamic-array-refusal', file: path.join(project, 'build/phase11/pattern-fixtures-01/dynamic-open-array.bend'), expectedStatus: 'error', expectedPhase: 'compile', expectedDiagnostic: 'Error: an open Array element type' });
const moduleFile = path.join(out, 'imported.bend'); fs.writeFileSync(moduleFile, pre + 'type Item is Data:\n  Item{value: Nat}\n');
add('imported-adt', pre + 'import ./imported.bend as M\n\ndef get(x: M.Item) -> Nat:\n  match x:\n    case M.Item{v}: v\n\ndef main() -> Nat:\n  get(M.Item{3n})\n', '3n\n');
for (const name of ['erased-constructor', 'unicode', 'dynamic-string']) { const original = cases.find(row => row.name === name); cases.push({ ...original, name: name + '-native-bytes', mode: 'native', expectedOutput: undefined }); }
if (process.argv[5]) { const names = process.argv[5].split(','); for (let i = cases.length - 1; i >= 0; i--) if (!names.includes(cases[i].name)) cases.splice(i, 1); }
const worker = path.join(out, 'worker.mjs'); fs.copyFileSync(path.join(import.meta.dirname, 'structure-control-worker.mjs'), worker);
const identity = file => ({ file, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') });
const report = { scope: 'Fresh paired actual checked emission; exact JS/native C bytes, complete observations/export keys and selected runtime outputs. Native-byte rows do not run Clang. Concurrent development, no timing claim.', inputs: [...new Set([baseline, candidate, worker, import.meta.filename, process.execPath, path.join(project, 'tools/typed-driver.mjs'), path.join(project, 'src/runtime.mjs'), path.join(project, 'src/runtime/native/runtime.c'), path.join(project, 'dist/base.bend'), moduleFile, ...cases.map(row => row.file)])].map(identity), rows: [] };
report.cpu = cpu;
for (const row of cases) for (const [variant, api] of [['baseline', baseline], ['candidate', candidate]]) {
  const directory = path.join(out, row.name + '-' + variant); fs.mkdirSync(directory);
  const request = { ...row, directory, driver: path.join(project, 'tools/typed-driver.mjs') }, requestFile = path.join(directory, 'request.json'); fs.writeFileSync(requestFile, JSON.stringify(request, null, 2) + '\n');
  const execution = await supervise('taskset', ['-c', cpu, process.execPath, '--stack-size=4096', '--max-old-space-size=4096', worker, requestFile], { directory: path.join(directory, 'process'), env: { ...process.env, BEND_TYPED_API: api, BEND_BASE: path.join(project, 'dist/base.bend') }, timeoutMs: 30000 });
  const resultFile = path.join(directory, 'report.json'); report.rows.push({ name: row.name, variant, execution, result: fs.existsSync(resultFile) ? JSON.parse(fs.readFileSync(resultFile)) : null });
  fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n'); console.log(row.name, variant, execution.exitCode);
}
report.pairs = cases.map(row => { const results = report.rows.filter(result => result.name === row.name).map(result => result.result); return { name: row.name, exact: JSON.stringify(results[0]) === JSON.stringify(results[1]) }; });
report.inputsVerified = report.inputs.every(input => identity(input.file).sha256 === input.sha256);
report.pass = report.inputsVerified && report.pairs.every(row => row.exact) && report.rows.every(row => row.result?.pass && row.execution.exitCode === 0 && row.execution.signal === null && !row.execution.error && !row.execution.timedOut && !row.execution.overflow);
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n'); if (!report.pass) process.exitCode = 1;
