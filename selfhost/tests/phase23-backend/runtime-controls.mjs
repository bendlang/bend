// Exercise the maintained JS effect registry without external networking.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const root=path.resolve(import.meta.dirname,'../..'),out=path.resolve(process.argv[2]);
if(fs.existsSync(out))throw Error('Use a fresh output directory');fs.mkdirSync(out,{recursive:true});
const source=path.join(root,'src/runtime.mjs');
const checks=String.raw`
import assert from 'node:assert/strict';
export const phase23Rows=[];
const check=(name,f)=>{f();phase23Rows.push({name,pass:true})};
const io=async(name,...args)=>call(G[name],args).io();
const zero=(name,s)=>name==='TCP.poll'?io(name,s,0,10000):io(name,s,0);
const assertInvalid=(v)=>{assert.equal(v.$,'Fail');assert.deepEqual(v.a[0],[22,'Invalid argument'])};
for(const name of ['TCP.recv','TCP.recv_bytes','TCP.poll']){
 const untouched=new Proxy({},{get(){throw Error('zero read touched socket state')}});
 const r=await zero(name,untouched);
 check(name+' zero validates before handle access',()=>{assert.equal(r[0],untouched);assertInvalid(r[1])});
 const state={queue:[Buffer.from('hello')],waiters:[],error:null,closed:false};
 const z=await zero(name,state);
 check(name+' zero preserves queued bytes',()=>{assertInvalid(z[1]);assert.deepEqual(state.queue,[Buffer.from('hello')]);assert.equal(state.waiters.length,0)});
 const received=await io('TCP.recv',state,64);
 check(name+' subsequent receive gets entire payload',()=>assert.deepEqual(received,[state,done('hello')]));
 const open={queue:[],waiters:[],error:null,closed:false};
 const start=performance.now(),empty=await zero(name,open);
 check(name+' zero never waits on empty open socket',()=>{assertInvalid(empty[1]);assert.equal(open.waiters.length,0);assert.ok(performance.now()-start<1000)});
}
const state={queue:[Buffer.from([0,255,195,169])],waiters:[],error:null,closed:false};
const first=await io('TCP.recv_bytes',state,2),last=await io('TCP.recv_bytes',state,2);
check('positive byte receives preserve split queue order',()=>{assert.deepEqual(unlist(first[1].a[0]),[0,255]);assert.deepEqual(unlist(last[1].a[0]),[195,169]);assert.equal(state.queue.length,0)});
const closed={queue:[],waiters:[],error:null,closed:true};
check('positive text EOF remains empty Done',()=>{});assert.deepEqual(await io('TCP.recv',closed,1),[closed,done('')]);
assert.deepEqual(await io('TCP.poll',closed,1,0),[closed,done(some(''))]);phase23Rows.push({name:'positive poll EOF remains Some empty string',pass:true});
const idle={queue:[],waiters:[],error:null,closed:false};
assert.deepEqual(await io('TCP.poll',idle,1,1),[idle,done(none())]);phase23Rows.push({name:'positive idle poll deadline remains None',pass:true});
`;
const file=path.join(out,'runtime-controls.mjs');fs.writeFileSync(file,fs.readFileSync(source,'utf8')+'\n'+checks);
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const report={kind:'phase23-js-tcp-contract-controls',node:process.version,inputs:[source,import.meta.filename,file].map(file=>({file,sha256:sha(file)})),complete:false,pass:false};
try{report.rows=(await import(pathToFileURL(file))).phase23Rows;report.complete=true;report.pass=report.rows.every(x=>x.pass)}catch(e){report.error=String(e.stack);process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,cases:report.rows?.length,error:report.error}));
