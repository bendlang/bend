import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

const request = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const { loadApi, inspect } = await import(pathToFileURL(request.driver));
const api = await loadApi(), result = await inspect(request.file, { mode: request.mode ?? 'compile', api });
const report = { observation: { ...result }, exports: Object.keys(api).sort() }; delete report.observation.code;
if (result.code) {
  const output = path.join(request.directory, request.mode === 'native' ? 'program.c' : 'program.mjs'); fs.writeFileSync(output, result.code);
  report.code = { bytes: Buffer.byteLength(result.code), sha256: crypto.createHash('sha256').update(result.code).digest('hex') };
  if (request.expectedOutput !== undefined) {
    const stdout = fs.openSync(path.join(request.directory, 'stdout'), 'w'), stderr = fs.openSync(path.join(request.directory, 'stderr'), 'w');
    const child = spawnSync(process.execPath, [output], { timeout: 10000, stdio: ['ignore', stdout, stderr] }); fs.closeSync(stdout); fs.closeSync(stderr);
    report.runtime = { status: child.status, signal: child.signal, error: child.error?.message ?? null, stdout: fs.readFileSync(path.join(request.directory, 'stdout'), 'utf8'), stderr: fs.readFileSync(path.join(request.directory, 'stderr'), 'utf8') };
  }
  if (request.libraryNames) {
    const library = (await import(pathToFileURL(output))).default;
    report.library = request.libraryNames.map((name, i) => { const value = library['make' + i](); return { name, value, picked: library.pick(value) }; });
  }
}
report.pass = result.checked === true && result.status === request.expectedStatus && (!request.expectedDiagnostic || result.diagnostic === request.expectedDiagnostic) && (!request.expectedPhase || result.phase === request.expectedPhase);
if (request.expectedOutput !== undefined) report.pass &&= report.runtime?.status === (request.expectedExit ?? 0) && report.runtime.signal === null && report.runtime.error === null && report.runtime.stdout + report.runtime.stderr === request.expectedOutput;
if (request.libraryNames) report.pass &&= report.library?.every(row => row.value.$ === row.name && row.picked.$ === 'Up');
fs.writeFileSync(path.join(request.directory, 'report.json'), JSON.stringify(report, null, 2) + '\n'); if (!report.pass) process.exitCode = 1;
