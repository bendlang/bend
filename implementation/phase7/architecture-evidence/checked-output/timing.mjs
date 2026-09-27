// Frozen, serial, bounded comparison; this is not a whole compiler benchmark.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const [baseline,candidate,runtime,outArg]=process.argv.slice(2);
assert.ok(outArg,'Expected BASELINE_CHECKED_API CANDIDATE_CHECKED_API RUNTIME NEW_OUTPUT');
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const digest=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({file:path.resolve(file),sha256:digest(fs.readFileSync(file))});
const put=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n',{flag:'wx'});
const worker=path.join(out,'timing-worker.mjs');fs.copyFileSync(path.join(import.meta.dirname,'timing-worker.mjs'),worker);
fs.copyFileSync(import.meta.filename,path.join(out,'timing.mjs'));
const report={kind:'checked-output-bounded-cost',complete:false,pass:false,
  scope:'Repeated checking of one successful immutable definition with 128 nested identity calls; compile lane includes baseline annotation versus direct candidate output; excludes loading, parsing, full-book chronology, backend emission and process startup from request times.',
  protocol:{cpu:0,workerOrder:['A','B','B','A'],lanes:['check','compile'],warmBatches:3,measuredBatches:7,requestsPerBatch:32,nestedApplications:128},
  inputs:[baseline,candidate,runtime,import.meta.filename,worker].map(identity),workers:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
async function expose(file,label){
  const s=fs.readFileSync(file,'utf8'),roots=[['checkDefinition','check_definition_result',2],['checkBook','check_book',1],['context','book_context',1],['annotate','annotate',4]];
  for(const [,name]of roots)assert.equal(s.split('function $'+name+'$(').length,2);
  const target=path.join(out,label+'.mjs');fs.writeFileSync(target,s+'\n'+roots.map(([alias,name,n])=>`export const ${alias}=run_lib($${name}$,${n});`).join('\n')+'\n',{flag:'wx'});
  return {...await import(pathToFileURL(target)),identity:identity(target)};
}
const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
const t=(tag,name='',id=0,quant=0,kids=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:nil});
const adt=t('ADT','Flag'),typ=t('Typ','',0,0,[t('Qua','',0,2)]);
const def=(name,ty,value=t('Absent'),arity=0,kind='Def',ctors=[])=>({$:'KDef',name,kind,arity,templates:0,typ:ty,value,ctors:list(ctors),native:false,unsafe:false});
const flag=def('Flag',typ,t('Absent'),0,'ADT',[def('On',adt,t('Absent'),0,'Ctr'),def('Off',adt,t('Absent'),0,'Ctr')]);
const id=def('id',t('All','x',10,1,[adt,adt]),t('Lam','x',11,1,[t('Var','x',11)]),1);
let body=t('Ctr','On');for(let i=0;i<128;i++)body=t('App','',0,0,[t('Ref','id'),body]);
const target=def('main',adt,body),book=list([flag,id,target]);
const fixture={book,target,env:{$:'KEnv',book:nil,name:'main',lhs:t('Ref','main'),pending:0,quantities:nil,unsafe:false}};
try{
  const A=await expose(baseline,'baseline-exposed'),B=await expose(candidate,'candidate-exposed');
  const ac=A.context(book),bc=B.context(book);
  assert.equal(A.checkBook(book),'');assert.equal(B.checkBook(book),'');
  const ar=A.checkDefinition(ac,target),br=B.checkDefinition(bc,target);
  const observation=r=>({typ:r.typ,uses:r.uses,error:r.error});assert.deepEqual(observation(br),observation(ar));assert.equal(ar.error,'');
  const annotated=A.annotate({...fixture.env,book:ac},nil,target.value,target.typ);assert.deepEqual(br.term,annotated);
  const aDefs=A.default.annotate_selected(ac,book,nil),bDefs=list([flag,{...id,value:B.checkDefinition(bc,id).term},{...target,value:br.term}]);
  const aCode=A.default.j_program_selected(ac,aDefs),bCode=B.default.j_program_selected(bc,bDefs);assert.equal(bCode,aCode);
  for(const [label,code]of [['A',aCode],['B',bCode]]){
    const file=path.join(out,label+'-program.mjs');fs.writeFileSync(file,fs.readFileSync(runtime,'utf8')+'\n'+code,{flag:'wx'});
    const p=spawnSync(process.execPath,['--stack-size=4096',file],{encoding:'utf8',timeout:10000,maxBuffer:2**20});
    put(path.join(out,label+'-program-result.json'),{status:p.status,signal:p.signal,stdout:p.stdout,stderr:p.stderr,error:p.error?.message});
    assert.equal(p.status,0);assert.equal(p.stdout,'On{}\n');assert.equal(p.stderr,'');
  }
  const fixtureFile=path.join(out,'fixture.json');put(fixtureFile,fixture);
  const cfg={variants:{A:A.identity,B:B.identity},fixture:{...identity(fixtureFile),valueSha256:digest(JSON.stringify(fixture))},
    expected:{check:digest(JSON.stringify(observation(ar))),compile:digest(JSON.stringify(annotated))},
    warmBatches:3,measuredBatches:7,requestsPerBatch:32};
  const configFile=path.join(out,'config.json');put(configFile,cfg);report.config=identity(configFile);report.outputSha256=digest(aCode);save();
  for(const lane of ['check','compile'])for(const [i,variant]of ['A','B','B','A'].entries()){
    const result=path.join(out,lane+'-'+i+'-'+variant+'.json');
    const args=['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,configFile,variant,lane,result];
    const start=performance.now(),p=spawnSync('taskset',args,{encoding:'utf8',timeout:120000,maxBuffer:2**20});
    const execution={lane,variant,command:['taskset',...args],status:p.status,signal:p.signal,stdout:p.stdout,stderr:p.stderr,error:p.error?.message,processMilliseconds:performance.now()-start};
    put(path.join(out,lane+'-'+i+'-'+variant+'-execution.json'),execution);
    report.workers.push({...execution,result:fs.existsSync(result)?JSON.parse(fs.readFileSync(result,'utf8')):null});save();
    assert.equal(p.status,0,p.error?.message||p.stderr||p.stdout);
  }
  const median=xs=>{const ys=xs.toSorted((a,b)=>a-b);return ys[Math.floor(ys.length/2)];};
  report.summary={};
  for(const lane of ['check','compile']){
    const ws=report.workers.filter(x=>x.lane===lane).map(x=>x.result);
    const pair=(a,b)=>({requestTimeRatio:median(b.milliseconds)/median(a.milliseconds),maxRssRatio:b.maxRssKiB/a.maxRssKiB});
    report.summary[lane]={workerBatchMedians:ws.map(x=>({variant:x.variant,ms:median(x.milliseconds),maxRssKiB:x.maxRssKiB})),oppositeOrderPairs:[pair(ws[0],ws[1]),pair(ws[3],ws[2])]};
  }
  report.complete=true;report.pass=true;save();console.log(JSON.stringify({complete:true,pass:true,summary:report.summary}));
}catch(error){report.error=String(error.stack??error);save();console.error(report.error);process.exitCode=1;}
