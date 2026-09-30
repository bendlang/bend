// Diagnostic V8 sampling only: never use this run as a comparative timing.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import inspector from 'node:inspector';
import {pathToFileURL} from 'node:url';
const [configPath,out]=process.argv.slice(2),config=JSON.parse(fs.readFileSync(configPath));
fs.mkdirSync(out,{recursive:false});
const identity=file=>({file,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-private-row-cpu-profile',complete:false,scope:'Instrumented diagnostic samples after a fixed warmup; no timing comparison, no steady-state or total-allocation claim.',config,inputs:[identity(configPath),identity(import.meta.filename),identity(config.module),identity(process.execPath)],node:process.version,args:process.execArgv,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:'))};
const save=()=>fs.writeFileSync(out+'/report.json',JSON.stringify(report,null,2)+'\n');save();
const session=new inspector.Session();
const post=(name,args={})=>new Promise((resolve,reject)=>session.post(name,args,(error,result)=>error?reject(error):resolve(result)));
try{
 assert.equal(report.inputs[2].sha256,config.moduleSha256);
 const m=await import(pathToFileURL(config.module));
 const invoke=()=>assert.equal(m.default.bench(...config.point.args),config.point.expected);
 for(let i=0;i<config.warmupCalls;i++)invoke();
 session.connect();await post('Profiler.enable');await post('Profiler.setSamplingInterval',{interval:config.samplingIntervalMicros});await post('Profiler.start');
 for(let i=0;i<config.profileCalls;i++)invoke();
 const {profile}=await post('Profiler.stop');await post('Profiler.disable');session.disconnect();
 fs.writeFileSync(out+'/cpu.cpuprofile',JSON.stringify(profile)+'\n');
 const samples=new Map();for(const id of profile.samples??[])samples.set(id,(samples.get(id)??0)+1);
 report.sampleCount=profile.samples?.length??0;
 report.selfSamples=profile.nodes.map(node=>({id:node.id,samples:samples.get(node.id)??0,frame:node.callFrame})).filter(n=>n.samples).sort((a,b)=>b.samples-a.samples);
 report.profile=identity(out+'/cpu.cpuprofile');
 for(const p of report.inputs)assert.deepEqual(identity(p.file),p);
 report.complete=true;
}catch(error){report.error=error.stack;try{session.disconnect()}catch{};process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,sampleCount:report.sampleCount,error:report.error}));
