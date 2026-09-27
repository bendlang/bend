import fs from 'node:fs';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import assert from 'node:assert/strict';
const [configFile,variant,lane,output]=process.argv.slice(2);
const cfg=JSON.parse(fs.readFileSync(configFile,'utf8'));
const digest=x=>createHash('sha256').update(x).digest('hex');
const entry=cfg.variants[variant];assert.equal(digest(fs.readFileSync(entry.file)),entry.sha256);
assert.equal(digest(fs.readFileSync(cfg.fixture.file)),cfg.fixture.sha256);
const M=await import(pathToFileURL(entry.file));
const fixture=JSON.parse(fs.readFileSync(cfg.fixture.file,'utf8'));
const context=M.context(fixture.book),target=fixture.target,env={...fixture.env,book:context};
let last;
function request(){
  last=M.checkDefinition(context,target);
  if(last.error)throw Error(last.error);
  if(lane==='compile')last=variant==='A'?M.annotate(env,{$:'Nil'},target.value,target.typ):last.term;
}
const resultHash=()=>digest(JSON.stringify(lane==='compile'?last:{typ:last.typ,uses:last.uses,error:last.error}));
for(let i=0;i<cfg.warmBatches;i++)for(let n=0;n<cfg.requestsPerBatch;n++)request();
assert.equal(resultHash(),cfg.expected[lane]);
const milliseconds=[];
for(let sample=0;sample<cfg.measuredBatches;sample++){
  const start=performance.now();
  for(let n=0;n<cfg.requestsPerBatch;n++)request();
  milliseconds.push(performance.now()-start);
  assert.equal(resultHash(),cfg.expected[lane]);
}
assert.equal(digest(JSON.stringify(fixture)),cfg.fixture.valueSha256);
const status=fs.readFileSync('/proc/self/status','utf8');
const report={pass:true,variant,lane,milliseconds,requestsPerBatch:cfg.requestsPerBatch,
  warmBatches:cfg.warmBatches,measuredBatches:cfg.measuredBatches,
  resultSha256:resultHash(),maxRssKiB:process.resourceUsage().maxRSS,
  heapUsed:process.memoryUsage().heapUsed,node:process.version,
  affinity:status.split('\n').find(x=>x.startsWith('Cpus_allowed_list:')),
  apiSha256:entry.sha256,fixtureSha256:cfg.fixture.sha256,workerSha256:digest(fs.readFileSync(import.meta.filename))};
fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({pass:true,variant,lane,maxRssKiB:report.maxRssKiB,milliseconds}));
