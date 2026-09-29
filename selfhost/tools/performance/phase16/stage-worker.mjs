import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [requestFile,resultFile]=process.argv.slice(2),request=JSON.parse(fs.readFileSync(requestFile));
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const verify=()=>request.inputs.forEach(i=>assert.deepEqual(identity(i.file),i));verify();
for(const key of Object.keys(process.env))if(key.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(key))delete process.env[key];
Object.assign(process.env,{BEND_TYPED_API:request.api,BEND_BASE:request.base,BEND_TYPED_RUNTIME:request.runtime,BEND_UPSTREAM:request.upstream});
const importStart=performance.now(),host=await import(pathToFileURL(request.host)),importMs=performance.now()-importStart;
const begin=performance.now(),cpu=process.cpuUsage();
const apiStart=performance.now(),raw=await host.loadApi(),apiLoadMs=performance.now()-apiStart;
const calls={},api={...raw};
for(const [name,fn]of Object.entries(raw))if(typeof fn==='function')api[name]=(...args)=>{
  const start=performance.now();try{return fn(...args);}finally{
    const c=calls[name]??={count:0,ms:0};c.count++;c.ms+=performance.now()-start;
  }
};
const result=await host.inspect(request.source,{mode:'check',api,timeoutMs:600000,combinedOutput:true});
const requestMs=performance.now()-begin,used=process.cpuUsage(cpu),compilerApiMs=Object.values(calls).reduce((n,c)=>n+c.ms,0);
const pass=result.typeAccepted===true&&result.proofTrust==='failed'&&result.phase==='verdict'&&result.exitCode===1;
verify();
fs.writeFileSync(resultFile,JSON.stringify({variant:request.variant,pass,result,calls,requestMs,apiLoadMs,compilerApiMs,hostAndInstrumentationMs:requestMs-apiLoadMs-compilerApiMs,importMs,cpuMs:(used.user+used.system)/1000,maxRssKiB:process.resourceUsage().maxRSS,affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:')),inputsVerified:true},null,2)+'\n',{flag:'wx'});
assert(pass,'Ordinary checked compiler source and unsafe-trust result required');
