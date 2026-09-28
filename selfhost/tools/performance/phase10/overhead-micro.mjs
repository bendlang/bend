import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {performance} from 'node:perf_hooks';
const identity=file=>({file:path.resolve(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const [mode,arg1,arg2,arg3]=process.argv.slice(2);
if(mode==='worker'){
 const file=path.resolve(arg1),K=(await import(pathToFileURL(file))).default;
 const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
 const atom={$:'KTerm',tag:'Absent',name:'',id:0,quant:0,kids:nil,removed:nil};
 const results=[];let consume=0;
 for(const size of [16,256,4096]){
  const ds=Array.from({length:size},(_,i)=>({$:'KDef',name:'micro/'+i,kind:'Def',arity:i,templates:0,typ:atom,value:atom,ctors:nil,native:true,unsafe:false}));
  const cached=K.book_cached(list(ds),size),tree=cached.head.ctors.head;
  const keys=ds.map(x=>x.name),hashes=keys.map(x=>K.index_hash(x,2166136261));
  const positions=Array.from({length:64},(_,i)=>(i*337+3)%size);
  for(const operation of ['prehashed-find','lookup']){
   const batch=()=>{let sum=0;for(const i of positions){const d=operation==='lookup'?K.lookup(cached,keys[i]):K.index_find(tree,keys[i],hashes[i],32);sum+=d.arity;}return sum};
   const expected=positions.reduce((sum,i)=>sum+i,0);assert.equal(batch(),expected);
   let warm=performance.now(),n=0;while(performance.now()-warm<120){consume+=batch();n++}
   const samples=[];for(let j=0;j<3;j++){const start=performance.now();let batches=0;do{consume+=batch();batches++}while(performance.now()-start<60);samples.push({milliseconds:performance.now()-start,batches,operations:batches*64})}
   assert.equal(batch(),expected);results.push({size,operation,expected,warmBatches:n,samples});
  }
 }
 console.log(JSON.stringify({api:identity(file),results,consume}));
}else if(mode==='run'){
 const before=path.resolve(arg1),after=path.resolve(arg2),out=path.resolve(arg3);fs.mkdirSync(out,{recursive:false});
 const node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';const inputs=[identity(import.meta.filename),identity(node),identity(before),identity(after)];const runs=[];
 const frozen=path.join(out,'worker.mjs');fs.copyFileSync(import.meta.filename,frozen);
 for(const label of ['baseline','candidate','candidate','baseline','candidate','baseline','baseline','candidate']){
  const file=label==='baseline'?before:after,command=['taskset','-c','3',node,'--stack-size=4096',frozen,'worker',file];
  const r=spawnSync(command[0],command.slice(1),{encoding:'utf8',timeout:15000,maxBuffer:4*1024*1024});
  const stem=String(runs.length).padStart(2,'0')+'-'+label;fs.writeFileSync(path.join(out,stem+'.stdout'),r.stdout??'');fs.writeFileSync(path.join(out,stem+'.stderr'),r.stderr??'');
  const entry={label,command,status:r.status,signal:r.signal,error:r.error?.message};if(r.status===0)entry.result=JSON.parse(r.stdout);runs.push(entry);if(r.status!==0)break;
 }
 const median=a=>{a=[...a].sort((a,b)=>a-b);return a.length%2?a[(a.length-1)/2]:(a[a.length/2-1]+a[a.length/2])/2};
 const summary=[];for(const size of [16,256,4096])for(const operation of ['prehashed-find','lookup']){
  const times=label=>runs.filter(x=>x.label===label&&x.result).map(x=>median(x.result.results.find(y=>y.size===size&&y.operation===operation).samples.map(z=>z.milliseconds/z.operations)));
  const baseline=times('baseline'),candidate=times('candidate');summary.push({size,operation,baselineMsPerLookup:baseline,candidateMsPerLookup:candidate,speedup:median(baseline)/median(candidate)});
 }
 const changed=inputs.filter(x=>identity(x.file).sha256!==x.sha256);const report={kind:'phase10-concurrent-index-component-screen',scope:'Fresh workers, serial ABBA/BAAB on CPU3; other compiler work may run on other CPUs. Checked components, not whole compiler.',inputs,pass:runs.length===8&&runs.every(x=>x.status===0)&&!changed.length,changed,runs,summary};
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,summary}));if(!report.pass)process.exitCode=1;
}else throw Error('run BASE CANDIDATE OUT or worker API');
