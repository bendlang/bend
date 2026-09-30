// V8 trace boundaries for an already emitted module. Never a timing sample.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const config=JSON.parse(fs.readFileSync(process.argv[2]));
console.log('PHASE25_BEGIN_IMPORT');
const {default:api}=await import(pathToFileURL(config.module));
const bench=api.bench;
function run(ms){let calls=0,checksum=0;const start=performance.now();do {
  const value=bench(config.size,config.seed);assert.equal(value,config.expectedResult);
  checksum=(checksum+value)>>>0;calls++;
}while(performance.now()-start<ms);return {calls,checksum};}
console.log('PHASE25_BEGIN_WARMUP');
const warm=run(200);
console.log('PHASE25_BEGIN_STEADY');
const steady=run(250);
console.log('PHASE25_END_STEADY');
console.log(JSON.stringify({kind:'phase25-v8-diagnostic-trace',complete:true,config,warm,steady,node:process.version,args:process.execArgv}));
