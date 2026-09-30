// Complete exported work, with first-call and warmed execution kept separate.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [mode,moduleArgument,configFile]=process.argv.slice(2);
assert.ok(['check','calibrate','time'].includes(mode));
const sha=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const file=fs.realpathSync(moduleArgument),config=JSON.parse(fs.readFileSync(configFile));
const report={kind:'phase28-program-execution',mode,complete:false,module:{file,sha256:sha(file)},config,
  configSha256:sha(configFile),toolSha256:sha(import.meta.filename),node:process.version,args:process.execArgv,
  affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:'))};
try{
  const start=performance.now(),mod=await import(pathToFileURL(file));report.importMs=performance.now()-start;
  const fn=mod.default[config.exportName??'bench'];assert.equal(typeof fn,'function');
  assert.ok(typeof config.expected==='string'||(Number.isInteger(config.expected)&&config.expected>=0&&config.expected<=0xffffffff));
  const invoke=()=>{const value=fn(...config.args);assert.equal(value,config.expected);return value;};
  const first=performance.now();report.firstResult=invoke();report.firstCallMs=performance.now()-first;
  if(mode!=='check'){
    const warm=performance.now();report.warmup=0;
    do{invoke();report.warmup++;}while(report.warmup<3||performance.now()-warm<1000);
    report.warmupMs=performance.now()-warm;
    const run=n=>{
      let checksum=0;const begin=performance.now(),halves=[];let from=0;
      for(const end of (n>1?[Math.floor(n/2),n]:[n])){
        const t=performance.now();for(let i=from;i<end;i++){const v=invoke();checksum=(checksum+(typeof v==='string'?v.length:v))>>>0;}
        halves.push({calls:end-from,ms:performance.now()-t});from=end;
      }
      return {repetitions:n,executionMs:performance.now()-begin,checksum,halves};
    };
    if(mode==='calibrate'){
      report.trials=[];let n=1;
      for(;;){const trial=run(n);report.trials.push(trial);if(trial.executionMs>=100||n>=65536)break;n*=2;}
      Object.assign(report,report.trials.at(-1));
    }else{
      assert.ok(Number.isInteger(config.repetitions)&&config.repetitions>=1&&config.repetitions<=1000000);
      Object.assign(report,run(config.repetitions));
    }
  }
  assert.equal(sha(file),report.module.sha256);assert.equal(sha(configFile),report.configSha256);report.complete=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1;}
report.peakRssKiB=process.resourceUsage().maxRSS;
console.log(JSON.stringify(report));
