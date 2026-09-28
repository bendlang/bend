// Uninstrumented operation measurements of the checked Bend component workers.
// Input generation, validation, imports and process startup are outside timings.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
const identity=file=>({file:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const same=item=>identity(item.file).sha256===item.sha256;
const now=()=>Number(process.hrtime.bigint())/1e6;
const write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n',{flag:'wx'});

function workloads(K,focus=false){
  const nil={$:'Nil'},list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);
  const t=(tag,name='',id=0,quant=0,kids=[])=>({$:'KTerm',tag,name,id,quant,kids:list(kids),removed:nil});
  const qua=q=>t('Qua','',0,q),typ=q=>t('Typ','',0,0,[qua(q)]),adt=t('ADT','Bool');
  const ctr=n=>t('Ctr',n),v=id=>t('Var','x',id),all=(id,a,b)=>t('All','x',id,1,[a,b]);
  const def=(name,typ,kind='Ctr',ctors=[])=>({$:'KDef',name,kind,arity:0,templates:0,typ,value:t('Absent'),ctors:list(ctors),native:false,unsafe:false});
  const book=list([def('Bool',typ(2),'ADT',[def('True',adt),def('False',adt)])]);
  const env={$:'KEnv',book,name:'',lhs:t('Absent'),pending:0,quantities:nil,unsafe:false};
  const cases=[];
  for(const size of [32,128,512]){
    let a=ctr('Leaf'),b=ctr('Leaf');
    for(let i=0;i<size;i++){a=t('Ctr','Wrap',0,0,[a]);b=t('Ctr','Wrap',0,0,[b]);}
    cases.push({family:'exact',size,input:[nil,a,b,false],invoke:()=>K.compare(nil,a,b,false),verify:r=>assert.equal(r,true),consume:r=>r?1:0});
  }
  const addLambda=(family,size,depth,domainDepth)=>{
    let type=adt,body=ctr('True'),fresh=100;
    for(let i=0;i<depth;i++){
      let domain=adt;
      for(let j=0;j<domainDepth;j++)domain=all(fresh++,adt,domain);
      type=all(fresh++,domain,type);
      body=t('Lam','x',500000+i,1,[body]);
    }
    // The optimized checker's checked-goal precondition is validated, not assumed.
    assert.equal(K.check(env,nil,type,0,typ(1)).error,'');
    const invoke=()=>K.check(env,nil,body,1,type);
    const verify=r=>{assert.equal(r.error,'');assert.deepEqual(r.term,body);assert.deepEqual(r.typ,type);assert.deepEqual(r.uses,nil);};
    cases.push({family,size,depth,domainDepth,input:[env,nil,body,1,type],invoke,verify,consume:r=>r.error.length+1});
    if(focus&&family==='lambda-domain'&&size===64){
      const main={...def('main',type,'Def'),arity:depth,value:body};
      const wholeBook={$:'Con',head:book.head,tail:{$:'Con',head:main,tail:nil}};
      cases.push({family:'lambda-book',size,depth,domainDepth,input:[wholeBook],invoke:()=>K.check_book(wholeBook),verify:r=>assert.equal(r,''),consume:r=>r.length+1});
    }
  };
  for(const size of [4,16,64])addLambda('lambda-depth',size,size,0);
  for(const size of [4,16,64])addLambda('lambda-domain',size,4,size);
  for(const size of [16,128,1024]){
    let ctx=nil;
    for(let i=0;i<size;i++)ctx={$:'Con',head:t('Bind','x',i,1,[adt]),tail:ctx};
    for(const success of [true,false]){
      const variable=v(success?0:size),error=success?'':'unbound variable';
      const verify=r=>{assert.equal(r.error,error);if(success){assert.deepEqual(r.typ,adt);assert.deepEqual(r.uses,list([t('Use','',0,1)]));}};
      cases.push({family:success?'lookup-success':'lookup-missing',size,input:[env,ctx,variable,1,nil],invoke:()=>K.infer(env,ctx,variable,1,nil),verify,consume:r=>r.error.length+1});
    }
  }
  return focus?cases.filter(c=>(c.family==='exact'&&c.size===512)||(['lambda-depth','lambda-domain','lambda-book'].includes(c.family)&&c.size===64)||(c.family.startsWith('lookup-')&&c.size===1024)):cases;
}

if(process.argv[2]==='--worker'){
  const config=JSON.parse(fs.readFileSync(process.argv[3]));
  assert(same(config.api));
  const {default:K}=await import(pathToFileURL(config.api.file));
  let cases=workloads(K,config.focus);if(config.reverse)cases=cases.reverse();
  const before=hash(JSON.stringify(cases.map(c=>c.input))),results=[];
  let sink=0;
  for(const c of cases){
    c.verify(c.invoke());
    const warmStart=now();let warmCalls=0;
    do{sink=(sink+c.consume(c.invoke()))>>>0;warmCalls++;}while(now()-warmStart<150||warmCalls<10);
    const warmMs=now()-warmStart;
    const repetitions=Math.max(1,Math.min(100000,Math.ceil(50*warmCalls/warmMs)));
    const samples=[];
    for(let sample=0;sample<3;sample++){
      const started=now();
      for(let i=0;i<repetitions;i++)sink=(sink+c.consume(c.invoke()))>>>0;
      const milliseconds=now()-started;samples.push({repetitions,milliseconds,nsPerCall:milliseconds*1e6/repetitions});
    }
    c.verify(c.invoke());
    results.push({family:c.family,size:c.size,depth:c.depth,domainDepth:c.domainDepth,warmCalls,warmMs,samples});
  }
  const after=hash(JSON.stringify(cases.map(c=>c.input)));
  assert.equal(after,before,'Input mutation');assert(same(config.api));
  write(config.output,{kind:'checker-operation-worker',variant:config.variant,sweep:config.sweep,reverse:config.reverse,api:config.api,inputSha256:before,inputsUnchanged:true,results,sink,maxRssKiB:process.resourceUsage().maxRSS});
  process.exit(0);
}

const [evidenceArg,outputArg,mode='concurrent']=process.argv.slice(2),evidence=fs.realpathSync(evidenceArg),output=path.resolve(outputArg);
assert(['concurrent','exclusive'].includes(mode));const focus=mode==='exclusive';
fs.mkdirSync(output,{recursive:false});
const script=path.join(output,'worker.mjs');fs.copyFileSync(import.meta.filename,script);
const names=focus?['baseline','combined']:['baseline','lambda','exact','lookup','combined'];
const variants=names.map(name=>{
  const directory=path.join(evidence,name+'-component-01'),reportFile=path.join(directory,'report.json');
  const report=JSON.parse(fs.readFileSync(reportFile));assert.equal(report.pass,true);assert(report.inputs.every(same));assert(same(report.api));
  return {name,report:identity(reportFile),api:report.api,inputs:report.inputs};
});
const manifest={kind:focus?'exclusive-checker-operation-confirmation':'concurrent-checker-operation-screen',started:new Date().toISOString(),node:identity(process.execPath),script:identity(script),variants,cpu:'1',sweeps:4,samplesPerCell:3,warmMs:150,targetSampleMs:50,
  scope:focus?'Baseline and combined independently checked components, uninstrumented compiled Bend workers; root must confirm an exclusive window before invocation. Whole-book synthetic counterpart included; no whole-compiler speedup is inferred.':'Five independently checked component APIs, uninstrumented compiled Bend workers; concurrent CPU0/CPU3 work permitted. No B1/private-worker equivalence or whole-compiler speedup is inferred.',
  boundary:'Operation only: imports, input generation, validated-goal checks, full result validation and startup excluded; result consumption included. RSS is whole fresh worker.',
  workloadSizes:focus?{exact:[512],lambdaDepth:[64],lambdaDomain:[64],lambdaBook:[64],lookupSuccess:[1024],lookupMissing:[1024]}:{exact:[32,128,512],lambdaDepth:[4,16,64],lambdaDomain:[4,16,64],lookupSuccess:[16,128,1024],lookupMissing:[16,128,1024]},
  order:'Four fresh-worker sweeps: forward, reverse, forward, reverse; reverse sweeps also reverse workload order.'};
write(path.join(output,'manifest.json'),manifest);
const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];
const commands=[];let healthy=true;
for(let sweep=0;sweep<4&&healthy;sweep++){
  const order=sweep%2?[...variants].reverse():variants;
  for(const variant of order){
    const stem=`${sweep}-${variant.name}`,configFile=path.join(output,stem+'.config.json'),result=path.join(output,stem+'.json');
    write(configFile,{variant:variant.name,sweep,reverse:!!(sweep%2),focus,api:variant.api,output:result});
    const argv=['-c','1',process.execPath,'--stack-size=4096','--max-old-space-size=4096',script,'--worker',configFile];
    const run=spawnSync('taskset',argv,{env,encoding:'utf8',timeout:90000,maxBuffer:1024*1024});
    fs.writeFileSync(path.join(output,stem+'.stdout'),run.stdout??'');fs.writeFileSync(path.join(output,stem+'.stderr'),run.stderr??'');
    const row={variant:variant.name,sweep,command:'taskset',argv,status:run.status,signal:run.signal,error:run.error?String(run.error):null,result:fs.existsSync(result)?identity(result):null};commands.push(row);
    fs.writeFileSync(path.join(output,'commands.json'),JSON.stringify(commands,null,2)+'\n');
    if(run.status!==0||run.signal||run.error){healthy=false;break;}
    console.log(JSON.stringify({finished:stem}));
  }
}
const changedInputs=[manifest.node,manifest.script,...variants.flatMap(v=>[v.report,v.api,...v.inputs])].filter(item=>!same(item));
const median=xs=>{const a=[...xs].sort((x,y)=>x-y),m=Math.floor(a.length/2);return a.length%2?a[m]:(a[m-1]+a[m])/2;};
const groups=new Map();
for(const command of commands)if(command.result){
  const row=JSON.parse(fs.readFileSync(command.result.file));
  for(const cell of row.results){const key=cell.family+'/'+cell.size;if(!groups.has(key))groups.set(key,{family:cell.family,size:cell.size,variants:{}});const group=groups.get(key);(group.variants[row.variant]??=[]).push(...cell.samples.map(s=>({sweep:row.sweep,nsPerCall:s.nsPerCall})));}
}
const rows=[...groups.values()].map(row=>{const medians=Object.fromEntries(Object.entries(row.variants).map(([name,samples])=>[name,median(samples.map(x=>x.nsPerCall))]));return {...row,medianNs:medians,speedup:Object.fromEntries(Object.entries(medians).map(([name,ns])=>[name,medians.baseline/ns]))};});
const pass=healthy&&commands.length===4*variants.length&&changedInputs.length===0;
write(path.join(output,'summary.json'),{kind:manifest.kind,manifest:identity(path.join(output,'manifest.json')),pass,changedInputs,workers:commands.length,rows,finished:new Date().toISOString()});
console.log(JSON.stringify({pass,workers:commands.length,changedInputs:changedInputs.length,output}));if(!pass)process.exitCode=1;
