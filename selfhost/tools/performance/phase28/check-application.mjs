// One complete original test value; acquisition only, not comparative timing.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [moduleArgument, configArgument] = process.argv.slice(2);
const file = fs.realpathSync(moduleArgument), config = JSON.parse(fs.readFileSync(configArgument));
const report = {kind:'phase28-application-check', complete:false,
  module:{file,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')},
  config,node:process.version,args:process.execArgv,
  timingScope:'First cold correctness acquisition call only; not comparative runtime.'};
try {
  const begin = performance.now(), mod = await import(pathToFileURL(file));
  report.importMs = performance.now() - begin;
  const run = mod.default[config.exportName];
  assert.equal(typeof run,'function');
  const start = performance.now();
  report.result = run(...config.args);
  report.firstCallMs = performance.now() - start;
  assert.equal(typeof report.result, config.resultType === 'string' ? 'string' : 'number');
  assert.equal(report.result,config.expected);
  report.complete = true;
} catch (error) {report.error=error.stack??String(error);process.exitCode=1;}
report.peakRssKiB = process.resourceUsage().maxRSS;
console.log(JSON.stringify(report));
