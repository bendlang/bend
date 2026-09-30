#!/usr/bin/env node
// Diagnostics for already-emitted, deterministic bench(U32,U32)->U32 libraries.
// Profiler/counter observations are never uninstrumented performance samples.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {Session} from 'node:inspector';
import {pathToFileURL, fileURLToPath} from 'node:url';
import {gzipSync} from 'node:zlib';

const SELF = fileURLToPath(import.meta.url);
const ROOT = path.resolve(path.dirname(SELF), '../../../..');
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const identity = file => { const bytes = fs.readFileSync(file); return {path:path.resolve(file), bytes:bytes.length, sha256:sha(bytes)}; };
const json = (file, value) => fs.writeFileSync(file, JSON.stringify(value, null, 2)+'\n', {flag:'wx'});
const fail = message => { throw new Error(message); };
function uint(value, name) {
  if (!Number.isSafeInteger(value) || value < 0 || value > 0xffffffff) fail(`${name} must be U32`);
  return value;
}
function bounded(value, name, min, max) {
  if (!Number.isSafeInteger(value) || value < min || value > max) fail(`${name} must be ${min}..${max}`);
  return value;
}
function exported(module, name) {
  const value = module.default?.[name] ?? module[name] ?? (name === 'bench' && typeof module.default === 'function' ? module.default : undefined);
  if (typeof value !== 'function') fail(`missing callable export ${name}`);
  return value;
}
function calls(fn, config, values) {
  for (let i=0; i<values.length; i++) {
    const value = fn(config.size, config.seed);
    uint(value, 'bench result');
    if (value !== config.expectedResult) fail(`result differs at repetition ${i}: expected ${config.expectedResult}, got ${value}`);
    values[i] = value;
  }
}
function result(values) {
  let checksum = 0;
  const counts = new Map();
  for (const value of values) {
    checksum = (checksum + value) >>> 0;
    counts.set(value,(counts.get(value)??0)+1);
  }
  return {calls:values.length, checksum, distinctValues:[...counts].map(([value,count])=>({value,count})),
    allCallsCheckedAgainstExpectedResult:true};
}
function framesCPU(profile) {
  const nodes = new Map(profile.nodes.map(n => [n.id, n]));
  const totals = new Map();
  const samples = profile.samples ?? [];
  for (let i=0; i<samples.length; i++) {
    const frame = nodes.get(samples[i])?.callFrame ?? {};
    const key = JSON.stringify(frame);
    const row = totals.get(key) ?? {frame, samples:0, microseconds:0};
    row.samples++; row.microseconds += profile.timeDeltas?.[i] ?? 0;
    totals.set(key,row);
  }
  return {sampleCount:samples.length, startTime:profile.startTime, endTime:profile.endTime,
    exclusiveFrames:[...totals.values()].sort((a,b)=>b.microseconds-a.microseconds)};
}
function writeAllocation(profile, out) {
  const nodesFile = path.join(out,'allocation-nodes.ndjson');
  const samplesFile = path.join(out,'allocation-samples.ndjson');
  const nf = fs.openSync(nodesFile,'wx');
  const sf = fs.openSync(samplesFile,'wx');
  const frames = new Map();
  let nodes=0, selfSize=0, sampleSize=0;
  try {
    const todo = [{node:profile.head, parentId:null}];
    while (todo.length) {
      const {node,parentId} = todo.pop();
      const {children=[], ...rest} = node;
      fs.writeSync(nf,JSON.stringify({...rest,parentId})+'\n');
      nodes++; selfSize += node.selfSize;
      const key = JSON.stringify(node.callFrame);
      const row = frames.get(key) ?? {frame:node.callFrame, sampledBytes:0,nodes:0};
      row.sampledBytes += node.selfSize; row.nodes++; frames.set(key,row);
      for (let i=children.length-1;i>=0;i--) todo.push({node:children[i],parentId:node.id});
    }
    for (const sample of profile.samples ?? []) {
      fs.writeSync(sf,JSON.stringify(sample)+'\n'); sampleSize += sample.size;
    }
  } finally { fs.closeSync(nf); fs.closeSync(sf); }
  const {head,samples,...metadata}=profile;
  json(path.join(out,'allocation-metadata.json'),metadata);
  return {nodes, samples:profile.samples?.length??0, sampledBytesFromNodes:selfSize,
    sampledBytesFromSamples:sampleSize, exclusiveFrames:[...frames.values()].sort((a,b)=>b.sampledBytes-a.sampledBytes),
    files:[identity(nodesFile),identity(samplesFile),identity(path.join(out,'allocation-metadata.json'))],
    interpretation:'Statistical allocated-size estimate including objects collected by minor/major GC; not retained or peak heap. Inspector and loop overhead are included. Nodes preserve full parent relationships.'};
}

const SELFHOST_KEYS = ['functionRecords','applyCalls','partialApplications','overApplications',
  'argumentCopyArrays','boundConcats','argumentSlices','overApplicationSlices','tailMessages',
  'tailArgumentSlots','forceCalls','bounceSteps','callCalls','constructorCalls','projectCalls',
  'matcherCreates','matcherEntries','matcher1Creates','matcher1Entries','buildMessages'];
const UPSTREAM_KEYS = ['tailMessages','tailArgumentArrays','closureCreates','closureEntries',
  'loopCalls','jumpSteps','libraryWrappers','libraryEntries','libraryPartialApplications'];
function prelude(keys) {
  return `\nconst __p25Counters=Object.fromEntries(${JSON.stringify(keys)}.map(k=>[k,0]));\n`+
    `const __p25Reset=()=>{for(const k of Object.keys(__p25Counters))__p25Counters[k]=0};\n`+
    `const __p25Read=()=>({...__p25Counters});\n`;
}
function replaceOne(source,before,after,edits) {
  if (source.split(before).length !== 2) fail(`counter guard: expected one exact helper ${before.slice(0,70)}`);
  edits.push({beforeSha256:sha(before),afterSha256:sha(after),before,after});
  return source.replace(before,after);
}
function selfhostInstrument(source,runtime) {
  if (!source.startsWith(runtime)) fail('counter guard: emitted module is not prefixed by the exact supplied selfhost runtime');
  if (source.includes('__p25')) fail('counter identifier collision');
  let changed=runtime;
  const edits=[];
  const rep=(before,after)=>{changed=replaceOne(changed,before,after,edits);};
  rep('const fn=(arity,code,env=null,bound=[])=>({arity,code,env,bound});',
      'const fn=(arity,code,env=null,bound=[])=>{__p25Counters.functionRecords++;return {arity,code,env,bound}};');
  rep('const jump=(f,args)=>({bounce:true,f,args});',
      'const jump=(f,args)=>{__p25Counters.tailMessages++;__p25Counters.tailArgumentSlots+=args.length;return {bounce:true,f,args}};');
  rep('const build=(name,fields)=>({build:true,name,fields});',
      'const build=(name,fields)=>{__p25Counters.buildMessages++;return {build:true,name,fields}};');
  rep('function force(x){','function force(x){__p25Counters.forceCalls++;');
  rep('if(x?.bounce){x=apply(x.f,x.args);continue}',
      'if(x?.bounce){__p25Counters.bounceSteps++;x=apply(x.f,x.args);continue}');
  rep('function apply(f,args){','function apply(f,args){__p25Counters.applyCalls++;');
  rep('const all=f.bound.length?f.bound.concat(args):args.slice();',
      'const all=f.bound.length?(__p25Counters.boundConcats++,f.bound.concat(args)):(__p25Counters.argumentSlices++,args.slice());__p25Counters.argumentCopyArrays++;');
  rep('if(all.length<f.arity)return fn(f.arity,f.code,f.env,all);',
      'if(all.length<f.arity){__p25Counters.partialApplications++;return fn(f.arity,f.code,f.env,all);}');
  rep('let r=f.code.call(f.env,all.slice(0,f.arity));',
      '__p25Counters.overApplications++;__p25Counters.overApplicationSlices++;let r=f.code.call(f.env,all.slice(0,f.arity));');
  rep('if(all.length>f.arity)r=jump(force(r),all.slice(f.arity));',
      'if(all.length>f.arity){__p25Counters.overApplicationSlices++;r=jump(force(r),all.slice(f.arity));}');
  rep('const call=(f,args)=>force(apply(f,args));',
      'const call=(f,args)=>{__p25Counters.callCalls++;return force(apply(f,args))};');
  rep('function ctor(k,a){','function ctor(k,a){__p25Counters.constructorCalls++;');
  rep('function project(k,x){','function project(k,x){__p25Counters.projectCalls++;');
  rep('function matcher1(name,arm){return fn(1,([x])=>{',
      'function matcher1(name,arm){__p25Counters.matcher1Creates++;return fn(1,([x])=>{__p25Counters.matcher1Entries++;');
  rep('function matcher(name,arm,other){return fn(1,([x])=>{',
      'function matcher(name,arm,other){__p25Counters.matcherCreates++;return fn(1,([x])=>{__p25Counters.matcherEntries++;');
  const controls=`
function __p25Controls(){
 const rows=[];
 const one=(name,f,expectedValue,counts)=>{__p25Reset();const value=f();rows.push({name,value,expectedValue,counts:__p25Read(),expectedCounts:Object.fromEntries(${JSON.stringify(SELFHOST_KEYS)}.map(k=>[k,counts[k]??0]))})};
 one('exact application',()=>call(fn(2,a=>a[0]+a[1]),[3,4]),7,{functionRecords:1,applyCalls:1,argumentCopyArrays:1,argumentSlices:1,callCalls:1,forceCalls:1});
 one('partial then exact',()=>{const f=fn(2,a=>a[0]+a[1]);const p=apply(f,[3]);return call(p,[4])},7,{functionRecords:2,applyCalls:2,partialApplications:1,argumentCopyArrays:2,boundConcats:1,argumentSlices:1,callCalls:1,forceCalls:1});
 one('overapplication',()=>call(fn(1,a=>fn(1,b=>a[0]+b[0])),[3,4]),7,{functionRecords:2,applyCalls:2,overApplications:1,argumentCopyArrays:2,argumentSlices:2,overApplicationSlices:2,tailMessages:1,tailArgumentSlots:1,forceCalls:2,bounceSteps:1,callCalls:1});
 one('three tail jumps',()=>{let f;f=fn(1,a=>a[0]===0?42:jump(f,[a[0]-1]));return call(f,[3])},42,{functionRecords:1,applyCalls:4,argumentCopyArrays:4,argumentSlices:4,tailMessages:3,tailArgumentSlots:3,forceCalls:1,bounceSteps:3,callCalls:1});
 one('unary matcher',()=>call(matcher1('P25Box',()=>fn(1,a=>a[0]+1)),[ctor('P25Box',[6])]),7,{functionRecords:2,applyCalls:2,argumentCopyArrays:2,argumentSlices:2,tailMessages:1,tailArgumentSlots:1,forceCalls:1,bounceSteps:1,callCalls:1,constructorCalls:1,projectCalls:1,matcher1Creates:1,matcher1Entries:1});
 one('matcher matching arm',()=>call(matcher('P25Box',()=>fn(1,a=>a[0]+1),()=>fn(1,()=>0)),[ctor('P25Box',[6])]),7,{functionRecords:2,applyCalls:2,argumentCopyArrays:2,argumentSlices:2,tailMessages:1,tailArgumentSlots:1,forceCalls:1,bounceSteps:1,callCalls:1,constructorCalls:1,matcherCreates:1,matcherEntries:1});
 one('matcher default arm',()=>call(matcher('P25Box',()=>fn(1,()=>0),()=>fn(1,()=>7)),[ctor('P25Other',[])]),7,{functionRecords:2,applyCalls:2,argumentCopyArrays:2,argumentSlices:2,tailMessages:1,tailArgumentSlots:1,forceCalls:1,bounceSteps:1,callCalls:1,constructorCalls:1,matcherCreates:1,matcherEntries:1});
 return rows;
}
export {__p25Reset,__p25Read,__p25Controls};
`;
  return {kind:'selfhost-public-runtime',keys:SELFHOST_KEYS,edits,
    source:prelude(SELFHOST_KEYS)+changed+source.slice(runtime.length)+controls,
    coverage:'Counts exact named runtime operations. Function records are fn objects, not a PrivateFunction class. Argument-copy arrays count apply slice/concat only; overapplication slices are separate. Tail argument slots are observed lengths, not allocations. Does not count every generated array, closure, or object.'};
}
function upstreamInstrument(source) {
  if(source.includes('__p25'))fail('counter identifier collision');
  let changed=source;const edits=[];
  const rep=(before,after)=>{changed=replaceOne(changed,before,after,edits);};
  rep('function run_tail(f, x) {\n  return {$: "$JMP", f: f.j?.f === f ? f.j : f, x: [x]};\n}',
      'function run_tail(f, x) {\n  __p25Counters.tailMessages++;__p25Counters.tailArgumentArrays++;\n  return {$: "$JMP", f: f.j?.f === f ? f.j : f, x: [x]};\n}');
  rep('function run_clo(j) {\n  const f = (x) => run_loop(j(x));\n  f.j = j;\n  j.f = f;\n  return f;\n}',
      'function run_clo(j) {\n  __p25Counters.closureCreates++;\n  const f = (x) => {__p25Counters.closureEntries++;return run_loop(j(x))};\n  f.j = j;\n  j.f = f;\n  return f;\n}');
  rep('function run_loop(r) {\n  while (r !== null && typeof r === "object" && r.$ === "$JMP") {\n    r = r.f(...r.x);\n  }\n  return r;\n}',
      'function run_loop(r) {\n  __p25Counters.loopCalls++;\n  while (r !== null && typeof r === "object" && r.$ === "$JMP") {\n    __p25Counters.jumpSteps++;\n    r = r.f(...r.x);\n  }\n  return r;\n}');
  rep('function run_lib(f, n) {\n  return (...a) => a.length < n ? run_lib((...b) => f(...a, ...b), n - a.length)\n    : f(...a);\n}',
      'function run_lib(f, n) {\n  __p25Counters.libraryWrappers++;\n  return (...a) => {__p25Counters.libraryEntries++;return a.length < n ? (__p25Counters.libraryPartialApplications++,run_lib((...b) => f(...a, ...b), n - a.length))\n    : f(...a)};\n}');
  const controls=`
function __p25Controls(){
 const rows=[];
 const one=(name,f,expectedValue,counts)=>{__p25Reset();const value=f();rows.push({name,value,expectedValue,counts:__p25Read(),expectedCounts:Object.fromEntries(${JSON.stringify(UPSTREAM_KEYS)}.map(k=>[k,counts[k]??0]))})};
 one('one tail message',()=>run_loop(run_tail(x=>x+1,6)),7,{tailMessages:1,tailArgumentArrays:1,loopCalls:1,jumpSteps:1});
 one('closure three tail jumps',()=>{const j=x=>x===0?42:run_tail(j,x-1);return run_clo(j)(3)},42,{tailMessages:3,tailArgumentArrays:3,closureCreates:1,closureEntries:1,loopCalls:1,jumpSteps:3});
 one('library partial then exact',()=>run_lib((a,b)=>a+b,2)(3)(4),7,{libraryWrappers:2,libraryEntries:2,libraryPartialApplications:1});
 return rows;
}
export {__p25Reset,__p25Read,__p25Controls};
`;
  return {kind:'upstream-run-helpers',keys:UPSTREAM_KEYS,edits,source:prelude(UPSTREAM_KEYS)+changed+controls,
    coverage:'Counts exact named runtime helpers. Direct calls/loops, inline $JMP construction, arbitrary arrow closures, and program arrays are not counted. jumpSteps includes any $JMP consumed by run_loop. These counts are not a complete allocation census.'};
}

export async function runDiagnostic(config,out) {
  config={...config};
  config.module=path.resolve(config.module);
  config.size=uint(config.size,'size');config.seed=uint(config.seed,'seed');
  config.repetitions=bounded(config.repetitions??10,'repetitions',1,1000000);
  config.warmup=bounded(config.warmup??3,'warmup',0,1000000);
  config.counterRepetitions=bounded(config.counterRepetitions??config.repetitions,'counterRepetitions',1,1000000);
  config.exportName=config.exportName??'bench';
  config.samplingIntervalUs=bounded(config.samplingIntervalUs??1000,'samplingIntervalUs',50,1000000);
  config.sampleIntervalBytes=bounded(config.sampleIntervalBytes??1048576,'sampleIntervalBytes',1024,1073741824);
  config.modes=config.modes??['cpu','allocation','counters'];
  if(!Array.isArray(config.modes)||config.modes.some(x=>!['cpu','allocation','counters'].includes(x))||new Set(config.modes).size!==config.modes.length)fail('invalid diagnostic modes');
  out=path.resolve(out);fs.mkdirSync(out);
  const source=fs.readFileSync(config.module,'utf8');
  const input=identity(config.module),tool=identity(SELF);
  if(input.sha256!==sha(source))fail('emitted module changed while being read');
  const report={schema:1,kind:'phase25-emitted-js-diagnostics',status:'running',config,input,tool,
    started:new Date().toISOString(),node:{version:process.version,execArgv:process.execArgv,executable:identity(process.execPath)},
    scope:'Already emitted bench(U32,U32)->U32 execution only. Imports and warmup precede profiling. CPU, allocation and counters run separately. Instrumented durations are not performance samples.'};
  json(path.join(out,'start.json'),report);
  const session=new Session();let connected=false;
  const post=(method,params={})=>new Promise((resolve,reject)=>session.post(method,params,(err,value)=>err?reject(err):resolve(value)));
  try {
    const original=await import(pathToFileURL(config.module).href);
    const fn=exported(original,config.exportName);
    const observed=uint(fn(config.size,config.seed),'initial bench result');
    if(config.expectedResult!==undefined&&observed!==uint(config.expectedResult,'expectedResult'))fail('initial bench result differs from supplied expectedResult');
    config.expectedResult=observed;
    report.initialResult=observed;
    const warm=new Uint32Array(config.warmup);calls(fn,config,warm);report.warmup=result(warm);
    if(config.modes.some(x=>x!=='counters')){session.connect();connected=true;}
    if(config.modes.includes('cpu')){
      const values=new Uint32Array(config.repetitions);
      await post('Profiler.enable');await post('Profiler.setSamplingInterval',{interval:config.samplingIntervalUs});
      await post('Profiler.start');
      calls(fn,config,values);
      const {profile}=await post('Profiler.stop');await post('Profiler.disable');
      const file=path.join(out,'cpu.cpuprofile.gz');fs.writeFileSync(file,gzipSync(JSON.stringify(profile)),{flag:'wx'});
      report.cpu={results:result(values),...framesCPU(profile),profile:identity(file)};
      json(path.join(out,'cpu-summary.json'),report.cpu);
    }
    if(config.modes.includes('allocation')){
      const values=new Uint32Array(config.repetitions);
      await post('HeapProfiler.enable');
      await post('HeapProfiler.startSampling',{samplingInterval:config.sampleIntervalBytes,includeObjectsCollectedByMajorGC:true,includeObjectsCollectedByMinorGC:true});
      calls(fn,config,values);
      const {profile}=await post('HeapProfiler.stopSampling');await post('HeapProfiler.disable');
      report.allocation={results:result(values),...writeAllocation(profile,out)};
      json(path.join(out,'allocation-summary.json'),report.allocation);
    }
    if(connected){session.disconnect();connected=false;}
    if(config.modes.includes('counters')){
      const runtimePath=path.resolve(config.counterRuntime??path.join(ROOT,'selfhost/src/runtime.mjs'));
      const runtime=fs.readFileSync(runtimePath,'utf8');
      const runtimeIdentity={path:runtimePath,bytes:Buffer.byteLength(runtime),sha256:sha(runtime)};
      const instrumented=source.startsWith(runtime)?selfhostInstrument(source,runtime):upstreamInstrument(source);
      const file=path.join(out,'instrumented.mjs');fs.writeFileSync(file,instrumented.source,{flag:'wx'});
      const guard={kind:instrumented.kind,original:input,instrumented:identity(file),runtime:instrumented.kind==='selfhost-public-runtime'?runtimeIdentity:null,edits:instrumented.edits,coverage:instrumented.coverage};
      json(path.join(out,'counter-guard.json'),guard);
      const module=await import(pathToFileURL(file).href);
      const controls=module.__p25Controls();
      for(const row of controls){row.pass=row.value===row.expectedValue&&JSON.stringify(row.counts)===JSON.stringify(row.expectedCounts);}
      json(path.join(out,'counter-controls.json'),{pass:controls.every(r=>r.pass),rows:controls});
      if(controls.some(r=>!r.pass))fail('counter controls failed; see retained counter-controls.json');
      const counted=exported(module,config.exportName);
      const warmValues=new Uint32Array(config.warmup);calls(counted,config,warmValues);
      const values=new Uint32Array(config.counterRepetitions);module.__p25Reset();calls(counted,config,values);
      const counts=module.__p25Read();
      if(Object.values(counts).some(n=>!Number.isSafeInteger(n)))fail('counter exceeds exact integer domain');
      report.counters={kind:instrumented.kind,results:result(values),counts,controls:controls.length,coverage:instrumented.coverage,guard:identity(path.join(out,'counter-guard.json'))};
      json(path.join(out,'counter-summary.json'),report.counters);
      if(instrumented.kind==='selfhost-public-runtime'&&identity(runtimePath).sha256!==runtimeIdentity.sha256)fail('counter runtime changed during run');
    }
    report.finalInput=identity(config.module);report.finalTool=identity(SELF);
    if(report.finalInput.sha256!==input.sha256||report.finalTool.sha256!==tool.sha256)fail('input or diagnostic tool changed during run');
    report.status='pass';report.finished=new Date().toISOString();json(path.join(out,'report.json'),report);return report;
  } catch(error) {
    report.status='failed';report.error={name:error.name,message:error.message,stack:error.stack};report.finished=new Date().toISOString();
    json(path.join(out,'failure.json'),report);throw error;
  } finally {if(connected)session.disconnect();}
}

if(process.argv[1] && path.resolve(process.argv[1])===SELF){
  const args=process.argv.slice(2);
  if(args.length!==5){process.stderr.write('usage: diagnostics.mjs MODULE size seed repetitions OUT\n');process.exitCode=2;}
  else runDiagnostic({module:args[0],size:Number(args[1]),seed:Number(args[2]),repetitions:Number(args[3])},args[4])
    .then(r=>process.stdout.write(JSON.stringify({status:r.status,out:path.resolve(args[4]),expectedResult:r.initialResult})+'\n'))
    .catch(e=>{process.stderr.write(String(e.stack??e)+'\n');process.exitCode=1;});
}
