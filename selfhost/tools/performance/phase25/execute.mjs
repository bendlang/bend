// Clean generated-program execution. Calibration never enters comparative samples.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [mode,moduleArgument,configArgument]=process.argv.slice(2);
assert.ok(['check','calibrate','time'].includes(mode));
const config=JSON.parse(fs.readFileSync(configArgument));
const file=fs.realpathSync(moduleArgument),bytes=fs.readFileSync(file);
const report={kind:'phase25-emitted-execution',mode,complete:false,module:{file,sha256:crypto.createHash('sha256').update(bytes).digest('hex')},node:process.version,args:process.execArgv,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),config};
try {
  const importStart=performance.now(),mod=await import(pathToFileURL(file));
  report.importMs=performance.now()-importStart;
  const bench=mod.default[config.exportName??'bench'];assert.equal(typeof bench,'function');
  const call=(p)=>{const value=bench(p.size,p.seed);assert.ok(Number.isInteger(value)&&value>=0&&value<=0xffffffff,'Expected U32 scalar');return value;};
  if(mode==='check') {
    report.results=config.inputs.map(p=>{const result=call(p);if(p.expected!==undefined)assert.equal(result,p.expected);return {...p,result};});
  } else {
    const {size,seed,expected}=config;assert.ok(Number.isInteger(expected));
    // Check every result; identical host checks on both sides. Boundary control
    // quantifies their cost. Timed calls alternate two runtime seeds when supplied.
    const inputs=config.alternate??[{size,seed,expected}];
    const invoke=i=>{const p=inputs[i%inputs.length];const result=call(p);assert.equal(result,p.expected);return result;};
    const warmStart=performance.now();report.warmup=0;
    do {invoke(report.warmup++);} while(report.warmup<(config.warmup??8)||performance.now()-warmStart<(config.warmupMs??100));
    report.warmupMs=performance.now()-warmStart;
    const run=n=>{let checksum=0;const start=performance.now();for(let i=0;i<n;i++)checksum=(checksum+invoke(i))>>>0;return {repetitions:n,executionMs:performance.now()-start,checksum};};
    if(mode==='calibrate') {
      report.trials=[];let repetitions=1;
      for(;;){const trial=run(repetitions);report.trials.push(trial);if(trial.executionMs>=50||repetitions>=65536)break;repetitions*=2;}
      Object.assign(report,report.trials.at(-1));
    } else {assert.ok(config.repetitions>0&&config.repetitions<=1000000);Object.assign(report,run(config.repetitions));}
  }
  report.complete=true;
} catch(error) {report.error=error.stack??String(error);process.exitCode=1;}
report.peakRssKiB=process.resourceUsage().maxRSS;
console.log(JSON.stringify(report));
