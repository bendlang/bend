// Bounded serial cost gate for ordinary, unseeded graph loading; no compiler build.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,identity,verifyIdentity} from '../../../selfhost/tools/development/workflow.mjs';
import {supervise,requireExecution} from '../../../selfhost/tools/development/process.mjs';

const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const digest=value=>sha(JSON.stringify(value));
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const write=(file,value)=>fs.writeFileSync(file,JSON.stringify(value,null,2)+'\n');
const affinity=()=>fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:')).split(':')[1].trim();
const median=values=>{const a=values.toSorted((x,y)=>x-y),n=a.length;assert.ok(n);return (a[Math.floor((n-1)/2)]+a[Math.floor(n/2)])/2;};
const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),{$:'Nil'});
function verifyWorkerIdentity(input){
  assert.equal(fs.realpathSync(input.file),input.canonicalPath);
  // Avoid making the 118 MiB Node executable a readFileSync allocation/RSS floor.
  const hash=createHash('sha256'),buffer=Buffer.allocUnsafe(65536),fd=fs.openSync(input.file,'r');
  try{let n;while((n=fs.readSync(fd,buffer,0,buffer.length,null))>0)hash.update(buffer.subarray(0,n));}
  finally{fs.closeSync(fd);}
  assert.equal(hash.digest('hex'),input.sha256,'Input drift: '+input.file);
}

async function worker(configFile,variant,mode,directory){
  const c=read(configFile),out=path.resolve(directory),apiFile=c.apis[variant].file;
  const r={kind:'S4-graph-cost-worker',variant,mode,complete:false,affinity:affinity(),rows:[]};
  const save=()=>write(path.join(out,'result.json'),r);save();
  try{
    assert.equal(r.affinity,'0');assert.equal(typeof global.gc,'function');
    for(const input of [...c.inputs,c.apis[variant]])verifyWorkerIdentity(input);
    const module=await import(pathToFileURL(apiFile));assert.equal(module.G,undefined,'Expected default named-field equality API');
    const api=module.default;
    for(const name of ['f_parse','f_source_parsed','f_load_graph','f_load_graph_trace'])assert.equal(typeof api[name],'function',name);
    const coreText=fs.readFileSync(c.core.file,'utf8'),baseText=fs.readFileSync(c.base.file,'utf8');
    const core={$:'FSource',name:c.core.file,path:c.core.file,text:coreText};
    // Base remains parsed input, never a seeded/loaded book; every graph call is unseeded.
    const baseResult=api.f_parse(baseText);assert.equal(baseResult.error,'','Canonical Base parses');
    const base=api.f_source_parsed('Base',c.base.file,baseText,baseResult);
    const prepare=kind=>{
      if(kind==='raw')return list([core,base]);
      const parsed=api.f_parse(coreText);assert.equal(parsed.error,'','Frozen core parses');
      return list([api.f_source_parsed(core.name,core.path,core.text,parsed),base]);
    };
    if(mode==='oracle'){
      let raw;
      for(const kind of ['raw','parsed']){
        const sources=prepare(kind),inputSha256=digest(sources);
        const graph=api.f_load_graph(core.path,sources),trace=api.f_load_graph_trace(core.path,sources);
        assert.equal(graph.error,'','Frozen core loads');assert.deepEqual(trace.result,graph,'Trace result');
        if(raw)assert.deepEqual(graph,raw,'Raw/parsed exact ordered graph');else raw=graph;
        const artifacts={};
        for(const [name,value] of Object.entries({graph,trace})){
          const file=path.join(out,kind+'-'+name+'.json');
          fs.writeFileSync(file,JSON.stringify(value),{flag:'wx'});artifacts[name]=identity(file);
        }
        assert.equal(digest(sources),inputSha256,'Oracle sources unchanged');
        r.rows.push({kind,inputSha256,artifacts});
      }
    }else{
      assert.ok(['raw','parsed'].includes(mode));
      const sources=prepare(mode),inputSha256=digest(sources);
      const expected=read(c.oracle).rows.find(row=>row.kind===mode).artifacts.graph.sha256;
      let result=api.f_load_graph(core.path,sources);
      assert.equal(digest(result),expected,'Initial exact ordered graph');
      for(let i=0;i<c.warmups;i++)result=api.f_load_graph(core.path,sources);
      global.gc();r.rssBeforeTimingBytes=process.memoryUsage().rss;
      const cpu=process.cpuUsage(),begin=performance.now();
      for(let i=0;i<c.iterations;i++)result=api.f_load_graph(core.path,sources);
      r.milliseconds=performance.now()-begin;
      const used=process.cpuUsage(cpu);r.cpuMs=(used.user+used.system)/1000;
      r.iterations=c.iterations;r.warmups=c.warmups;r.perCallMs=r.milliseconds/c.iterations;
      // Capture peak before final serialization; lifetime includes import/preparation/warmup.
      r.peakRssKiB=process.resourceUsage().maxRSS;r.rssAfterTimingBytes=process.memoryUsage().rss;
      assert.equal(digest(result),expected,'Final exact ordered graph');
      assert.equal(digest(sources),inputSha256,'Measured sources unchanged');
      r.graphSha256=expected;r.inputSha256=inputSha256;
    }
    for(const input of [...c.inputs,c.apis[variant]])verifyWorkerIdentity(input);
    r.complete=true;
  }catch(error){r.error=String(error.stack??error);process.exitCode=1;}
  save();console.log(JSON.stringify({complete:r.complete,variant,mode,error:r.error}));
}

async function parent(beforeArg,afterArg,coreArg,outArg){
  assert.ok(beforeArg&&afterArg&&coreArg&&outArg,'Expected BASELINE_ATTEMPT CANDIDATE_ATTEMPT FROZEN_CORE NEW_OUTPUT');
  const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
  const report={kind:'S4-unseeded-graph-cost',complete:false,pass:false,started:new Date().toISOString(),executions:[],samples:[],
    scope:'Frozen real four-core source. Ordinary f_load_graph only; raw/parsed main with own-API parsed canonical Base outside requests. Fresh processes, serial CPU 0. No checker, host-loop, native, fixed-point or TypeScript ratio claim.',
    order:['baseline','candidate','candidate','baseline','baseline','candidate','candidate','baseline'],
    guards:{runtimeRatio:1.05,peakRssRatio:1.10,apiBytesRatio:1.10},warmups:3,iterations:5,childTimeoutMs:120000,totalTimeoutMs:900000};
  const save=()=>write(path.join(out,'report.json'),report);save();
  const start=performance.now();
  try{
    const attempts=[fs.realpathSync(beforeArg),fs.realpathSync(afterArg)];
    const manifests=[];for(const dir of attempts)manifests.push(await verifyAttempt(dir));
    for(const m of manifests){assert.equal(m.config.profile,'equality');assert.equal(m.artifactKind,'derived-b1');}
    assert.equal(manifests[0].base.sha256,manifests[1].base.sha256);
    assert.equal(manifests[0].base.canonicalPath,manifests[1].base.canonicalPath);
    assert.equal(manifests[0].base.sha256,'b8c2734d45ec6b4ce70fee70ff06ef35e08fce885af8852d8eb77dbff020e946');
    const core=identity(fs.realpathSync(coreArg)),base=manifests[0].base;
    assert.equal(core.sha256,'7ea730ae3e2ee190ff55a0def12f8410203fee9fa2c0573df52265b583523ccf','Use frozen S3 60,909-byte four-core workload');
    assert.equal(fs.statSync(core.file).size,60909);
    const apis={baseline:manifests[0].api,candidate:manifests[1].api};
    const inputs=[identity(import.meta.filename),identity(process.execPath),core,base,
      ...attempts.map(dir=>identity(path.join(dir,'attempt.json'))),
      ...['workflow','process'].map(name=>identity(path.join(import.meta.dirname,'../../../selfhost/tools/development/'+name+'.mjs')))];
    const config={core,base,apis,inputs,warmups:report.warmups,iterations:report.iterations,oracle:path.join(out,'oracle-baseline/result.json')};
    const configFile=path.join(out,'config.json');write(configFile,config);
    report.inputs=[...inputs,identity(configFile)];report.apis=apis;report.attempts=attempts;
    report.node={file:process.execPath,version:process.version};report.coreBytes=60909;report.baseBytes=fs.statSync(base.file).size;
    report.apiBytes=Object.fromEntries(Object.entries(apis).map(([name,item])=>[name,fs.statSync(item.file).size]));save();
    const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];
    const run=async(variant,mode,label)=>{
      report.inputs.forEach(verifyIdentity);Object.values(apis).forEach(verifyIdentity);
      const remaining=report.totalTimeoutMs-(performance.now()-start);assert.ok(remaining>0,'Experiment deadline');
      const directory=path.join(out,label);fs.mkdirSync(directory,{recursive:false});
      const execution=await supervise('taskset',['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096','--expose-gc',import.meta.filename,'--worker',configFile,variant,mode,directory],
        {directory:path.join(directory,'command'),env,timeoutMs:Math.min(report.childTimeoutMs,Math.floor(remaining))});
      report.executions.push({variant,mode,label,execution});save();requireExecution(execution);
      const result=read(path.join(directory,'result.json'));assert.equal(result.complete,true);assert.equal(result.affinity,'0');
      return {directory,result};
    };
    const oracles={};
    for(const variant of ['baseline','candidate'])oracles[variant]=(await run(variant,'oracle','oracle-'+variant)).result;
    for(const mode of ['raw','parsed']){
      const a=oracles.baseline.rows.find(row=>row.kind===mode),b=oracles.candidate.rows.find(row=>row.kind===mode);
      assert.equal(a.inputSha256,b.inputSha256,'Cross-version prepared source equality');
      for(const field of ['graph','trace'])assert.ok(fs.readFileSync(a.artifacts[field].file).equals(fs.readFileSync(b.artifacts[field].file)),mode+' exact ordered '+field);
    }
    report.oracleExact=true;report.oracles=oracles;
    report.inputs.push(identity(config.oracle));save();
    for(const mode of ['raw','parsed'])for(const [block,variant] of report.order.entries()){
      const {directory,result}=await run(variant,mode,mode+'-'+String(block).padStart(2,'0')+'-'+variant);
      report.samples.push({...result,block,result:identity(path.join(directory,'result.json'))});save();
    }
    report.summary=['raw','parsed'].map(mode=>{
      const grouped=variant=>report.samples.filter(row=>row.variant===variant&&row.mode===mode);
      const measure=variant=>({milliseconds:median(grouped(variant).map(row=>row.perCallMs)),peakRssKiB:median(grouped(variant).map(row=>row.peakRssKiB))});
      const baseline=measure('baseline'),candidate=measure('candidate');
      const runtimeRatio=candidate.milliseconds/baseline.milliseconds,peakRssRatio=candidate.peakRssKiB/baseline.peakRssKiB;
      return {mode,baseline,candidate,runtimeRatio,peakRssRatio,runtimeGuardPass:runtimeRatio<=report.guards.runtimeRatio,memoryGuardPass:peakRssRatio<=report.guards.peakRssRatio};
    });
    report.apiBytesRatio=report.apiBytes.candidate/report.apiBytes.baseline;report.apiSizeGuardPass=report.apiBytesRatio<=report.guards.apiBytesRatio;
    report.inputs.forEach(verifyIdentity);for(const dir of attempts)await verifyAttempt(dir);
    assert.ok(performance.now()-start<=report.totalTimeoutMs,'Experiment deadline after final verification');
    report.complete=true;report.pass=report.apiSizeGuardPass&&report.summary.every(row=>row.runtimeGuardPass&&row.memoryGuardPass);
    if(!report.pass)process.exitCode=1;
  }catch(error){report.error=String(error.stack??error);process.exitCode=1;}
  report.elapsedMs=performance.now()-start;report.finished=new Date().toISOString();save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,summary:report.summary,apiBytesRatio:report.apiBytesRatio,error:report.error}));
}

const args=process.argv.slice(2);
if(args[0]==='--worker')await worker(...args.slice(1));else await parent(...args);
