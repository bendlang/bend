import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';
const request = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const { loadApi, inspect } = await import(pathToFileURL(request.driver));
const api = await loadApi(), emit = api.j_program_selected;
let emissionMs;
api.j_program_selected = (...args) => { const start = performance.now(), result = emit(...args); emissionMs = performance.now() - start; return result; };
const start = performance.now(), observation = await inspect(request.file, { mode: 'compile', api });
const compileMs = performance.now() - start, code = observation.code; delete observation.code;
const report = { observation, compileMs, emissionMs, maxRssKiB: process.resourceUsage().maxRSS };
if (code) {
  const file = path.join(request.directory, 'program.mjs'); fs.writeFileSync(file, code);
  report.code = { bytes: Buffer.byteLength(code), sha256: crypto.createHash('sha256').update(code).digest('hex') };
  const stdout = fs.openSync(path.join(request.directory, 'stdout'), 'w'), stderr = fs.openSync(path.join(request.directory, 'stderr'), 'w');
  const child = spawnSync(process.execPath, [file], { timeout: 10000, stdio: ['ignore', stdout, stderr] }); fs.closeSync(stdout); fs.closeSync(stderr);
  report.runtime = { status: child.status, signal: child.signal, error: child.error?.message ?? null, stdout: fs.readFileSync(path.join(request.directory, 'stdout'), 'utf8'), stderr: fs.readFileSync(path.join(request.directory, 'stderr'), 'utf8') };
}
report.pass = observation.status === 'ok' && observation.checked === true && report.runtime?.status === 0 && report.runtime.signal === null && report.runtime.error === null && report.runtime.stdout === request.expected && report.runtime.stderr === '';
fs.writeFileSync(path.join(request.directory, 'report.json'), JSON.stringify(report, null, 2) + '\n'); if (!report.pass) process.exitCode = 1;
