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
`;
const foreignChecks=String.raw`
import assert from 'node:assert/strict';
// Mirror descriptors actually emitted for native forms, including recursion.
showSchemas.Nat=()=>['ADT',{Zero:[],Succ:[['Named','Nat',[]]]}];
showSchemas.Bool=()=>['ADT',{False:[],True:[]}];
showSchemas['Word.Con']=()=>['ADT',{WCon:[['Named','Bool',[]],null]}];
showSchemas.U32=()=>['ADT',{U32:[['Named','Word.Con',[null]]]}];
showSchemas.F32=()=>['ADT',{F32:[['Named','Word.Con',[null]]]}];
showSchemas.Char=()=>['ADT',{Chr:[['Named','U32',[]]]}];
showSchemas.String=()=>['ADT',{SNil:[],SCon:[['Char'],['Named','String',[]]]}];
constructors.Box=['n'];constructorOwn.Box='Box';showSchemas.Box=()=>['ADT',{Box:[['Named','Nat',[]]]}];
assert.deepEqual(foreignIn({$:'Box',n:5n},['Named','Box',[]]),{$:'Box',a:[5n]});
for(const invalid of [{$:'Bogus',n:5n},{n:5n},null,[]])assert.throws(()=>foreignIn(invalid,['Named','Box',[]]),/Box has no tag/);
for(const [name,values] of [['Nat',[0n,5n,1n<<100n]],['U32',[0,5,4294967295]],['F32',[0,-0,Infinity,NaN]],['Bool',[false,true]],['String',['','ok','Привет 🌍']]]){
  for(const value of values)assert.ok(Object.is(foreignIn(value,['Named',name,[]]),value),name+' native representation');
  assert.equal(foreignHasNat(['Named',name,[]]),name==='Nat');
}
assert.equal(foreignIn('🌍',['Char']),'🌍');
assert.equal(foreignOut(0x1f30d,['Char']),'🌍');
assert.equal(foreignHasNat(['Named','Box',[]]),true);
assert.equal(foreignHasNat(['Named','Undefined',[]]),false);
showSchemas.GenericMaybe=p=>['ADT',{None:[],Some:[p[0]]}];
showSchemas.PairOfMaybe=()=>['ADT',{PairOfMaybe:[['Named','GenericMaybe',[['Named','Nat',[]]]],['Named','GenericMaybe',[['Named','Bool',[]]]]]}];
assert.equal(foreignHasNat(['Named','PairOfMaybe',[]]),true,'distinct instantiations must inspect their arguments before the seen-name guard');
assert.throws(()=>foreignIn({$:'Bogus'},['Named','PairOfMaybe',[]]),/PairOfMaybe has no tag Bogus/);
constructors.Wrapped=['box'];constructorOwn.Wrapped='Wrapped';showSchemas.Wrapped=()=>['ADT',{Wrapped:[['Named','Box',[]]]}];
assert.deepEqual(foreignIn({$:'Wrapped',box:{$:'Box',n:5n}},['Named','Wrapped',[]]),{$:'Wrapped',a:[{$:'Box',a:[5n]}]});
assert.throws(()=>foreignIn({$:'Wrapped',box:{$:'Bogus',n:5n}},['Named','Wrapped',[]]),/Box has no tag Bogus/);
assert.deepEqual(foreignIn([0n,5n],['Array',['Named','Nat',[]]]),{array:[0n,5n]});
assert.deepEqual(foreignIn({$:'Tuple',fst:5n,snd:true},['Tuple',['Named','Nat',[]],['Named','Bool',[]]]),[5n,true]);
console.log('Phase8 foreign-tag and primitive representation contracts passed');
`;
try{
  const selected=process.argv.includes('--foreign-only')?foreignChecks:checks+'\n'+foreignChecks.replace("import assert from 'node:assert/strict';",'');
  fs.writeFileSync(file,fs.readFileSync(new URL('../../runtime.mjs',import.meta.url),'utf8')+'\n'+selected);
  const result=spawnSync(process.execPath,[file,'--threads','2','--help','argument'],{stdio:'inherit',timeout:10000});
  if(result.error)throw result.error;
  assert.equal(result.status,0);
}finally{fs.rmSync(directory,{recursive:true,force:true})}
