import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const [driver, file, out, expected] = process.argv.slice(2);
const { loadApi, inspect } = await import(pathToFileURL(driver));
const api = await loadApi();
const emit = api.j_program_selected;
let emission;
api.j_program_selected = (...args) => {
  globalThis.__structureCounts = {};
  const started = performance.now(), code = emit(...args);
  emission = { ms: performance.now() - started, counts: { ...globalThis.__structureCounts } };
  return code;
};
const observation = await inspect(file, { mode: 'compile', api });
let execution = null, code = null;
if (observation.code) {
  const output = path.join(out, 'program.mjs');
  fs.writeFileSync(output, observation.code);
  code = { bytes: Buffer.byteLength(observation.code), sha256: crypto.createHash('sha256').update(observation.code).digest('hex') };
  const stdout = fs.openSync(path.join(out, 'runtime.stdout'), 'w'), stderr = fs.openSync(path.join(out, 'runtime.stderr'), 'w');
  const child = spawnSync(process.execPath, [output], { timeout: 10000, stdio: ['ignore', stdout, stderr] });
  fs.closeSync(stdout); fs.closeSync(stderr);
  execution = { status: child.status, signal: child.signal, error: child.error?.message ?? null, stdout: fs.readFileSync(path.join(out, 'runtime.stdout'), 'utf8'), stderr: fs.readFileSync(path.join(out, 'runtime.stderr'), 'utf8') };
  delete observation.code;
}
const pass = observation.status === 'ok' && observation.checked === true && execution?.status === 0 && execution.signal === null && execution.error === null && execution.stdout === expected + '\n' && execution.stderr === '';
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify({ observation, emission, code, execution, expected, pass }, null, 2) + '\n');
if (!pass) process.exitCode = 1;
