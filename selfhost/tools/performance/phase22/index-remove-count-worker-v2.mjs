import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [requestFile,resultFile]=process.argv.slice(2);
const request=JSON.parse(fs.readFileSync(requestFile));
const verify=()=>{for(const x of request.inputs)assert.equal(createHash('sha256').update(fs.readFileSync(x.file)).digest('hex'),x.sha256,x.file);};
verify();
for(const key of Object.keys(process.env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete process.env[key];
Object.assign(process.env,{BEND_TYPED_API:request.api,BEND_TYPED_RUNTIME:request.runtime,BEND_BASE:request.base,BEND_UPSTREAM:request.upstream,BEND_TYPED_TRACE:''});
const module=await import(pathToFileURL(request.instrumentedApi));
const api=module.default;
const {inspect}=await import(pathToFileURL(request.driver));
const result=await inspect(request.source,{mode:'check',api,timeoutMs:600000,combinedOutput:true});
fs.writeFileSync(resultFile+'.raw.json',JSON.stringify(result,null,2)+'\n',{flag:'wx'});
const {hostProvenance,...expected}=JSON.parse(fs.readFileSync(request.baselineResult)).result;
assert.deepEqual(result,expected,'Instrumentation must preserve the entire driver observation');
const counters=module.__phase22_index_remove_counts();
assert.equal(counters.unknown?.roots??0,0);
for(const row of Object.values(counters))assert.equal(row.roots,row.completed);
verify();
fs.writeFileSync(resultFile,JSON.stringify({complete:true,pass:true,result,counters,inputsVerified:true,
  node:{version:process.version,args:process.execArgv},affinity:fs.readFileSync('/proc/self/status','utf8').split('\n').find(s=>s.startsWith('Cpus_allowed_list:')),
  scope:'Diagnostic generated-constructor executions; not V8 heap allocation or elapsed-performance evidence.'},null,2)+'\n',{flag:'wx'});
