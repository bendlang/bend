// Acquisition correctness probe, not a controlled performance comparison.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [moduleArgument, configArgument]=process.argv.slice(2);
const file=fs.realpathSync(moduleArgument), config=JSON.parse(fs.readFileSync(configArgument));
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const report={kind:'phase28-first-call-check',complete:false,module:{file,sha256:sha(file)},config,node:process.version,args:process.execArgv,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),timingScope:'One cold correctness acquisition call; descriptive only, not a controlled comparison.'};
try{
  const begin=performance.now(), mod=await import(pathToFileURL(file));
  report.importMs=performance.now()-begin;
  const bench=mod.default.bench;assert.equal(typeof bench,'function');
  const start=performance.now();report.result=bench(config.size,config.seed);report.firstCallMs=performance.now()-start;
  assert.ok(Number.isInteger(report.result)&&report.result>=0&&report.result<=0xffffffff);
  assert.equal(report.result,config.expected);report.complete=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
report.peakRssKiB=process.resourceUsage().maxRSS;
console.log(JSON.stringify(report));
