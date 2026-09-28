// Host-effect contract controls; compiler execution is tested separately.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-phase8-effects-'));
const file=path.join(directory,'effects.mjs');
const checks=String.raw`
import assert from 'node:assert/strict';
const io=async(name,...args)=>call(G[name],args).io();
assert.equal(await io('IO.thread_count'),1);
assert.deepEqual(unlist(await io('IO.args')),[process.argv[1],'--help','argument']);
const run=(program,args=[],input='',limit=128,timeout=1000)=>io('Process.run',program,list(args),input,limit,timeout);
const ok=(value,code,out,err='')=>assert.deepEqual(value,done([code,[out,err]]));
const badCode=(value,code)=>{assert.equal(value.$,'Fail');assert.equal(value.a[0][0],code)};
ok(await run('/bin/cat',[],'Привет 🌍\n'),0,'Привет 🌍\n');
ok(await run('/bin/echo',['x; echo injected']),0,'x; echo injected\n');
ok(await run('/bin/sh',['-c','printf out; printf err >&2; exit 7']),7,'out','err');
ok(await run('/bin/sh',['-c','printf 1234'],'',4),0,'1234');
badCode(await run('/bin/sh',['-c','printf 12345'],'',4),27);
badCode(await run('/bin/sh',['-c','printf abc; printf def >&2'],'',5),27);
badCode(await run('/bin/sleep',['2'],'',128,30),process.platform==='darwin'?60:110);
badCode(await run('/__bend_missing_executable__'),2);
badCode(await run('/bin/cat',[],'',0),22);
badCode(await run('/bin/cat',[],'',1,0),22);
badCode(await run('/bin/echo',['bad\0arg']),22);
ok(await run('/bin/cat',[],'',1),0,'');
ok(await run('/bin/sh',['-c','kill -TERM $$']),143,'');
ok(await run('/usr/bin/perl',['-e','print $SIG{PIPE} // q(default)']),0,'default');
const before=Date.now();ok(await run('/bin/sh',['-c','sleep 1 & echo hi'],'',128,300),0,'hi\n');assert.ok(Date.now()-before<800);
const results=await Promise.all([run('/bin/cat',[],'a'),run('/bin/cat',[],'b')]);ok(results[0],0,'a');ok(results[1],0,'b');
const listener=(await io('TCP.listen','127.0.0.1',0)).a[0];
const client=(await io('TCP.connect','127.0.0.1',listener.server.address().port)).a[0];
const server=(await io('TCP.accept',listener))[1].a[0];
assert.equal((await io('TCP.send_bytes',client,list([0,255,195,169])))[1].$,'Done');
assert.deepEqual(unlist((await io('TCP.recv_bytes',server,4))[1].a[0]),[0,255,195,169]);
badCode((await io('TCP.send_bytes',client,list([256])))[1],22);
await io('Socket.close',client);await io('Socket.close',server);await io('Listener.close',listener);
badCode(await io('TCP.listen','not-an-ip',0),22);badCode(await io('UDP.bind','not-an-ip',0),22);
console.log('Phase8 host effects: process/argv/thread/TCP contracts passed');
`;
try{
  fs.writeFileSync(file,fs.readFileSync(new URL('../../runtime.mjs',import.meta.url),'utf8')+'\n'+checks);
  const result=spawnSync(process.execPath,[file,'--threads','2','--help','argument'],{stdio:'inherit',timeout:10000});
  if(result.error)throw result.error;
  assert.equal(result.status,0);
}finally{fs.rmSync(directory,{recursive:true,force:true})}
