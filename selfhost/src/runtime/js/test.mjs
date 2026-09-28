// Primitive ABI integration checks; no parser, checker, emitter or upstream compiler.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import assert from 'node:assert/strict';
const dir=fs.mkdtempSync(path.join(os.tmpdir(),'bend2-runtime-'));
const target=path.join(dir,'test.mjs');
const runtime=fs.readFileSync(process.env.BEND_JS_RUNTIME?path.resolve(process.env.BEND_JS_RUNTIME):new URL('../../runtime.mjs',import.meta.url),'utf8');
const checks="import assert from 'node:assert/strict';\nconst invoke=(n,...a)=>call(G[n],a);\nconst io=async(n,...a)=>invoke(n,...a).io();\nassert.deepEqual(await io('File.open','', 'r'),ctor('Fail',[[2,'No such file or directory']]));\nassert.equal(show([1,[2n,99]],['Tuple',['U32'],['Tuple',['Nat'],['Char']]]),\"(1, 2n, 'c')\");\nassert.equal(show('a\\x01b\\x7f\\t'), '\\\"a\\\\u{1}b\\\\u{7f}\\\\t\\\"');\nassert.equal(invoke('Char.to_upper',233),233);\nassert.equal(invoke('F32.from_nat',4294967297n),1);\nassert.equal(invoke('F32.to_nat',Infinity),0n);\nconst c=await io('Chan.new',null,0);let sent=false;const sending=io('Chan.send',null,c,42).then(x=>{sent=true;return x});\nassert.equal(sent,false);assert.equal((await io('Chan.recv',null,c)).a[0],42);assert.equal(await sending,true);await io('Chan.close',null,c);assert.equal((await io('Chan.recv',null,c)).$,'None');\nconst f='/tmp/bend2-runtime-bytes-'+process.pid;const h=(await io('File.open',f,'w')).a[0];assert.equal((await io('File.write_bytes',h,list([0,65,255])))[1].$,'Done');await io('File.close',h);const r=(await io('File.open',f,'r')).a[0];assert.deepEqual(unlist((await io('File.read_at',r,1,2))[1].a[0]),[65,255]);assert.equal((await io('File.size',r))[1].a[0],3);await io('File.close',r);fs.unlinkSync(f);\nconst listener=(await io('TCP.listen','127.0.0.1',0)).a[0];const port=listener.server.address().port;const client=(await io('TCP.connect','127.0.0.1',port)).a[0];const server=(await io('TCP.accept',listener))[1].a[0];await io('TCP.send',client,'hello');assert.equal((await io('TCP.recv',server,5))[1].a[0],'hello');assert.equal((await io('TCP.poll',server,5,2))[1].a[0].$,'None');await io('Socket.close',client);await io('Socket.close',server);await io('Listener.close',listener);\nconst ua=(await io('UDP.bind','127.0.0.1',0)).a[0],ub=(await io('UDP.bind','127.0.0.1',0)).a[0];await io('UDP.send_to',ua,'127.0.0.1',ub.socket.address().port,'udp');const ur=(await io('UDP.recv_from',ub,9))[1].a[0];assert.equal(ur[1][1],'udp');await io('Socket.close',ua);await io('Socket.close',ub);\nassert.equal(invoke('F32.read','  -inf').a[0],-Infinity);\nassert.equal(invoke('F32.read','1e9999').a[0],Infinity);\nassert.equal(invoke('F32.read','1 ').$,'None');\nassert.throws(()=>invoke('Char.from_u32',0xd800),/Unicode scalar/);\nassert.equal((await io('IO.get_env','PATH\\\\0X')).$,'Fail');\nconsole.log('runtime numeric/readback/File/Chan/TCP/UDP checks passed');\n";
try{
 fs.writeFileSync(target,runtime+'\n'+checks);
 const result=spawnSync(process.execPath,[target],{stdio:'inherit',timeout:10000});
 if(result.error)throw result.error;
 assert.equal(result.status,0);
 fs.writeFileSync(target,runtime+'\nG.main=fn(0,()=>bind(call(G["IO.spawn"],[null,call(G["IO.sleep"],[10000])]),()=>call(G["IO.die"],[null,7,"halt now"])));await runmain(null,true);');
 const halted=spawnSync(process.execPath,[target],{encoding:'utf8',timeout:1000});
 assert.equal(halted.error,undefined);
 assert.equal(halted.status,7);
 assert.equal(halted.stderr,'halt now\n');
 console.log('Halt terminates outstanding child effects');
}finally{fs.rmSync(dir,{recursive:true,force:true})}
