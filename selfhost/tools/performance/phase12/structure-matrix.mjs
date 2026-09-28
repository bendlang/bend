import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { supervise, requireExecution } from '../../development/process.mjs';
const project = path.resolve(import.meta.dirname, '../../..'), out = path.resolve(process.argv[2]); fs.mkdirSync(out);
const driver = path.join(project, 'tools/typed-driver.mjs'), worker = path.join(out, 'worker.mjs'), prepare = path.join(out, 'prepare.mjs');
fs.copyFileSync(path.join(import.meta.dirname, 'structure-matrix-worker.mjs'), worker);
fs.writeFileSync(prepare, "import{pathToFileURL}from'node:url';const{loadApi,prepareBase}=await import(pathToFileURL(process.argv[2]));await prepareBase(await loadApi());\n");
const variants = { baseline: path.join(project, 'build/phase11/integrated-01/equality/api.mjs'), reuse: path.join(project, 'build/phase12/structure-reuse-01/attempt/equality/api.mjs'), lookup: path.join(project, 'build/phase12/structure-lookup-01/attempt/equality/api.mjs'), combined: path.join(project, 'build/phase12/structure-combined-01/attempt/equality/api.mjs') };
const file = path.join(out, 'nat-128.bend'); fs.writeFileSync(file, 'import Base\n\ndef down(n: Nat) -> Nat:\n  match n:\n    case 128n:\n      down(127n)\n    case _:\n      n\n\ndef main() -> Nat:\n  Nat.add(down(128n), down(7n))\n');
const identity = file => ({ file, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') });
const env = api => ({ ...process.env, BEND_TYPED_API: api, BEND_BASE: path.join(project, 'dist/base.bend') });
const report = { scope: 'Directional public JS-emission screen: serial fresh CPU1 workers in reversed order, two samples per ablation. Other CPU jobs may compete; not an exclusive compiler-wide ratio. Validated per-variant Base caches prepared; OS caches not flushed. compileMs covers inspect through JS output; process wall also covers imports and execution; emitter wrapper is identical.', cpu: '1', node: process.version, resources: { stackKiB: 4096, heapMiB: 4096, timeoutMs: 30000 }, inputs: [file, driver, worker, prepare, import.meta.filename, process.execPath, path.join(project, 'dist/base.bend'), path.join(project, 'src/runtime.mjs'), ...Object.values(variants)].map(identity), preparation: [], rows: [], pass: false };
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n'); save();
try {
  for (const [name, api] of Object.entries(variants)) { const execution = await supervise('taskset', ['-c', '1', process.execPath, '--stack-size=4096', '--max-old-space-size=4096', prepare, driver], { env: env(api), directory: path.join(out, 'prepare-' + name), timeoutMs: 30000 }); report.preparation.push({ name, execution }); save(); requireExecution(execution); }
  for (const [i, name] of ['baseline', 'reuse', 'lookup', 'combined', 'combined', 'lookup', 'reuse', 'baseline'].entries()) {
    const directory = path.join(out, i + '-' + name); fs.mkdirSync(directory); const requestFile = path.join(directory, 'request.json'); fs.writeFileSync(requestFile, JSON.stringify({ directory, driver, file, expected: '134n\n' }, null, 2) + '\n');
    const execution = await supervise('taskset', ['-c', '1', process.execPath, '--stack-size=4096', '--max-old-space-size=4096', worker, requestFile], { env: env(variants[name]), directory: path.join(directory, 'process'), timeoutMs: 30000 });
    const resultFile = path.join(directory, 'report.json'), result = fs.existsSync(resultFile) ? JSON.parse(fs.readFileSync(resultFile)) : null; report.rows.push({ i, name, execution, result }); save(); requireExecution(execution); if (!result?.pass) throw Error('Actual output gate failed: ' + name);
  }
  if (new Set(report.rows.map(row => row.result.code.sha256)).size !== 1) throw Error('Emitted JS changed');
  if (!report.inputs.every(input => identity(input.file).sha256 === input.sha256)) throw Error('Input identity changed');
  report.means = Object.fromEntries(Object.keys(variants).map(name => { const rows = report.rows.filter(row => row.name === name); return [name, { compileMs: rows.reduce((n, row) => n + row.result.compileMs, 0) / rows.length, emissionMs: rows.reduce((n, row) => n + row.result.emissionMs, 0) / rows.length, processMs: rows.reduce((n, row) => n + row.execution.wallMs, 0) / rows.length, maxRssKiB: Math.max(...rows.map(row => row.result.maxRssKiB)) }]; })); report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
save(); console.log(JSON.stringify({ pass: report.pass, means: report.means, error: report.error }));
