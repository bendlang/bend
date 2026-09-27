// Frozen operation comparison: same checked component, fresh workers, serial ABBA.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const sha=b=>createHash('sha256').update(b).digest('hex');
const median=xs=>[...xs].sort((a,b)=>a-b)[Math.floor(xs.length/2)];
const [mode,apiArg,outArg,operation,variant]=process.argv.slice(2);
const apiFile=path.resolve(apiArg),out=path.resolve(outArg);
if(mode==='worker'){
  const {default:api}=await import(pathToFileURL(apiFile));
  const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
  const term=(tag,id,kids=[])=>({$:'KTerm',tag,name:tag,id,quant:1,kids:list(kids),removed:nil});
  let next=100;
  function tree(depth){const id=next++;return depth?(depth%2?term('All',id,[term('Lam',id,[term('Var',id)]),tree(depth-1)]):term('Ctr',id,[tree(depth-1),tree(depth-1)])):term('Var',id)}
  const input=tree(7),before=sha(JSON.stringify(input));
  const fn=operation==='fresh'?(variant==='A'?api.f_fresh_term:api.a3_fresh):(variant==='A'?api.sp_shift:api.a3_shift);
  const call=()=>operation==='fresh'?fn(input,nil,500):fn(input,17);
  let last;const one=()=>{const start=performance.now();for(let i=0;i<100;i++)last=call();return performance.now()-start};
  for(let i=0;i<3;i++)one();
  const samples=[];for(let i=0;i<7;i++)samples.push(one());
  assert.equal(sha(JSON.stringify(input)),before);
  const report={operation,variant,inputSha256:before,outputSha256:sha(JSON.stringify(last)),apiSha256:sha(fs.readFileSync(apiFile)),harnessSha256:sha(fs.readFileSync(import.meta.filename)),warmupRequests:3,iterationsPerRequest:100,samplesMs:samples,medianMs:median(samples),rssKiB:process.resourceUsage().maxRSS};
  fs.writeFileSync(out,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
}else{
  if(mode!=='run'||fs.existsSync(out))throw Error('run API NEW_DIRECTORY');
  fs.mkdirSync(out,{recursive:true});
  const frozen=path.join(out,'measure.mjs');fs.copyFileSync(import.meta.filename,frozen);
  const report={scope:'freshening and template-ID shifting operation microbenchmarks; same mixed tree, no whole compiler claim',cpu:0,node:process.version,apiSha256:sha(fs.readFileSync(apiFile)),harnessSha256:sha(fs.readFileSync(frozen)),order:['A','B','B','A'],complete:false,workers:[],summary:{}};
  const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
  for(const operation of ['fresh','shift']){
    for(const [i,variant]of report.order.entries()){
      const file=path.join(out,`${operation}-${i}-${variant}.json`);
      const args=['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096',frozen,'worker',apiFile,file,operation,variant];
      const child=spawnSync('taskset',args,{encoding:'utf8',timeout:60000,maxBuffer:2**20});
      fs.writeFileSync(file+'.stdout',child.stdout??'');fs.writeFileSync(file+'.stderr',child.stderr??'');
      report.workers.push({operation,variant,command:['taskset',...args],exit:child.status,error:child.error?.message,result:fs.existsSync(file)?JSON.parse(fs.readFileSync(file)):null});save();
      assert.equal(child.status,0,'worker');assert.equal(child.error,undefined);
    }
    const rows=report.workers.filter(x=>x.operation===operation).map(x=>x.result);
    assert.equal(new Set(rows.map(x=>x.outputSha256)).size,1,'exact outputs');
    assert.equal(new Set(rows.map(x=>x.inputSha256)).size,1,'exact inputs');
    report.summary[operation]={pairedTimeRatios:[rows[1].medianMs/rows[0].medianMs,rows[2].medianMs/rows[3].medianMs],pairedRssRatios:[rows[1].rssKiB/rows[0].rssKiB,rows[2].rssKiB/rows[3].rssKiB]};save();
  }
  assert.equal(sha(fs.readFileSync(apiFile)),report.apiSha256);
  report.complete=true;save();console.log(JSON.stringify(report.summary));
}
