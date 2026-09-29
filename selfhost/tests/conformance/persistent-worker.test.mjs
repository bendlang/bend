import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import {spawnFileSync as spawnSync} from '../helpers/spawn-file-sync.mjs';
import path from 'node:path';
import {createPersistentRunner,validatePersistentReplay} from '../../tools/conformance/persistent-probe.mjs';

test('persistent runner isolates requests and recycles at its bound', async()=>{
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'bend-persistent-test-'));
  fs.writeFileSync(path.join(root,'identity.json'),'{}');
  const adapter=path.join(root,'adapter.mjs');
  fs.writeFileSync(adapter,`export const persistentLanes=['parse'];\nexport async function createPersistentSession(){let calls=0;return {probe:async()=>({status:'ok',phase:'parse',exitCode:0,calls:++calls})};}\nexport async function probe(){throw Error('persistent fixture');}\n`);
  const runner=createPersistentRunner({directory:path.join(root,'runner'),recycleAfter:2,rssLimitMb:1024});
  try {
    const rows=[];
    for(let i=0;i<3;i++){
      const workdir=path.join(root,'request-'+i);fs.mkdirSync(workdir);
      rows.push(await runner.run({adapter,lane:'parse',test:{id:'persistent-'+i},upstream:root,project:root,workdir,timeoutMs:5000,response:path.join(workdir,'response.json'),identityFile:path.join(root,'identity.json'),workerNodeArgs:[]}));
    }
    assert.deepEqual(rows.map(row=>row.result.calls),[1,2,1]);
    assert.equal(rows[0].worker.index,0);assert.equal(rows[1].worker.index,1);assert.equal(rows[2].worker.index,0);
    assert.notEqual(rows[0].worker.generation,rows[2].worker.generation);
    assert.equal(runner.errors.length,0);assert.equal(runner.stats.recycles,1);
  } finally {runner.close();fs.rmSync(root,{recursive:true,force:true});}
});

function fixture(t,body,options={}){
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'bend-persistent-failure-'));
  const adapter=path.join(root,'adapter.mjs'),identityFile=path.join(root,'identity.json');
  fs.writeFileSync(identityFile,'{}');
  fs.writeFileSync(adapter,`import fs from 'node:fs'; import {spawn} from 'node:child_process';\nexport const persistentLanes=['parse'];export async function createPersistentSession(){let calls=0;return {async probe(request){calls++;${body}}};}`);
  const runner=createPersistentRunner({directory:path.join(root,'runner'),...options});
  let index=0;
  t.after(()=>{runner.close();fs.rmSync(root,{recursive:true,force:true});});
  function request(mode='ok',extra={}){
    const workdir=path.join(root,'request-'+index++);fs.mkdirSync(workdir);
    return {adapter,identityFile,lane:'parse',test:{id:mode},project:root,upstream:root,workdir,response:path.join(workdir,'response.json'),timeoutMs:5000,workerNodeArgs:[],...extra};
  }
  return {root,adapter,identityFile,runner,request};
}
const success="return {status:'ok',phase:'parse',exitCode:0,calls};";

test('captured stdout and stderr share one output budget and recover',async t=>{
  const f=fixture(t,`if(request.test.id==='overflow'){process.stdout.write('x'.repeat(600000));process.stderr.write('y'.repeat(600000));}${success}`);
  const bad=await f.runner.run(f.request('overflow'));
  assert.equal(bad.result.status,'crash');assert.match(bad.result.reason,/output limit/);
  const good=await f.runner.run(f.request());
  assert.equal(good.result.calls,1);assert.notEqual(good.worker.generation,bad.worker.generation);
});

test('captured and raw descriptor output share the budget and remain request-local',async t=>{
  const f=fixture(t,`if(request.test.id==='overflow'){process.stdout.write('x'.repeat(1000000));for(let i=0;i<20;i++){fs.writeSync(2,'r'.repeat(5000));await new Promise(r=>setTimeout(r,1));}}else {process.stdout.write('captured');fs.writeSync(2,'raw');}${success}`);
  const bad=await f.runner.run(f.request('overflow'));
  assert.equal(bad.result.status,'crash');assert.match(bad.result.reason,/output limit/);
  const request=f.request(),good=await f.runner.run(request);
  assert.equal(good.result.status,'ok');assert.equal(good.result.calls,1);
  assert.equal(fs.readFileSync(path.join(request.workdir,'worker.stdout'),'utf8'),'captured');
  assert.equal(fs.readFileSync(path.join(request.workdir,'worker.stderr'),'utf8'),'raw');
});

test('timeouts kill descendants and crashes reset session state before recovery',async t=>{
  const f=fixture(t,`if(request.test.id==='timeout'){spawn(process.execPath,['-e',"setTimeout(()=>require('fs').writeFileSync(process.argv[1],'orphan'),500)",request.marker],{stdio:'ignore'});await new Promise(()=>{});}if(request.test.id==='crash')process.exit(23);${success}`);
  assert.equal((await f.runner.run(f.request())).result.calls,1);
  const marker=path.join(f.root,'orphan');
  const timed=await f.runner.run(f.request('timeout',{timeoutMs:150,marker}));
  assert.equal(timed.result.status,'timeout');
  const recovered=await f.runner.run(f.request());assert.equal(recovered.result.calls,1);
  const crashed=await f.runner.run(f.request('crash'));assert.equal(crashed.result.status,'crash');
  assert.match(crashed.result.reason,/exited unexpectedly/);
  assert.equal((await f.runner.run(f.request())).result.calls,1);
  await new Promise(r=>setTimeout(r,550));assert.equal(fs.existsSync(marker),false);
});

test('oversized response and invalid adapter result cannot poison the next request',async t=>{
  const f=fixture(t,`if(request.test.id==='large')return {status:'ok',value:'x'.repeat(2**22)};if(request.test.id==='invalid')return null;${success}`);
  for(const mode of ['large','invalid']){
    assert.equal((await f.runner.run(f.request(mode))).result.status,'crash');
    assert.equal((await f.runner.run(f.request())).result.calls,1);
  }
});

test('stale completion files are removed and changed identity starts a new session',async t=>{
  const f=fixture(t,success),request=f.request();
  fs.writeFileSync(path.join(request.workdir,'worker.done'),'{stale');
  fs.writeFileSync(request.response,'{stale');
  assert.equal((await f.runner.run(request)).result.calls,1);
  const identityFile=path.join(f.root,'other-identity.json');fs.writeFileSync(identityFile,'{}');
  const next=await f.runner.run(f.request('ok',{identityFile}));assert.equal(next.result.calls,1);assert.equal(next.worker.generation,2);
});

test('retained sequence validates every prefix result and request despite removed workdirs',async t=>{
  const f=fixture(t,success),first=f.request(),last=f.request();
  await f.runner.run(first);await f.runner.run(last);
  const retained=JSON.parse(fs.readFileSync(path.join(last.workdir,'request.json'),'utf8'));
  const session=JSON.parse(fs.readFileSync(retained.workerSession.file,'utf8'));
  fs.rmSync(first.workdir,{recursive:true});
  assert.equal(validatePersistentReplay(retained,session,[]),1);
  for(const alter of [
    copy=>delete copy.requests[0].resultDigest,
    copy=>copy.requests[0].request.test.id='changed',
    copy=>copy.requests[0].resultDigest='0'.repeat(64),
    copy=>copy.workerSha256='0'.repeat(64),
  ]){const copy=structuredClone(session);alter(copy);assert.throws(()=>validatePersistentReplay(retained,copy,[]));}
  const changed=structuredClone(retained);changed.test.id='different';assert.throws(()=>validatePersistentReplay(changed,session,[]),/Retained request differs/);
  const replay=createPersistentRunner({directory:path.join(f.root,'replay')});
  try{
    for(let i=0;i<2;i++){
      const workdir=path.join(f.root,'replayed-'+i);fs.mkdirSync(workdir);
      const row=await replay.run({...session.requests[i].request,workdir,response:path.join(workdir,'response.json')});
      assert.equal(row.result.calls,i+1);
    }
  }finally{replay.close();}
});

// A deliberately faulty worker exercises the FD3 path independently of the
// ordinary worker's done file and capture implementation.
function protocolFixture(t,body){
  const root=fs.mkdtempSync(path.join(os.tmpdir(),'bend-persistent-protocol-'));
  const worker=path.join(root,'worker.mjs');
  fs.writeFileSync(worker,`import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';const q=process.argv[3];const timer=setInterval(()=>{const name=fs.readdirSync(q).find(n=>n.endsWith('.json'));if(!name)return;clearInterval(timer);const c=JSON.parse(fs.readFileSync(path.join(q,name),'utf8'));const r=JSON.parse(fs.readFileSync(c.file,'utf8'));${body}},5);setInterval(()=>{},1000);`);
  const f=fixture(t,success,{worker});
  t.after(()=>fs.rmSync(root,{recursive:true,force:true}));return f;
}

test('FD3 overflow completion is rejected even without a done file',async t=>{
  const f=protocolFixture(t,`fs.writeSync(3,JSON.stringify({id:c.id,token:c.token,done:true,rss:1,logOverflow:true,responseSha256:'0'.repeat(64)})+'\\n');`);
  const row=await f.runner.run(f.request());assert.equal(row.result.status,'crash');assert.match(row.result.reason,/output limit/);
});

test('malformed, out-of-sequence and oversized FD3 messages fail promptly',async t=>{
  for(const output of ["'{oops}\\n'","JSON.stringify({id:c.id,token:'0'.repeat(32)})+'\\n'","'x'.repeat(16385)"]){
    const f=protocolFixture(t,`fs.writeSync(3,${output});`);
    const row=await f.runner.run(f.request());assert.equal(row.result.status,'crash');assert.match(row.result.reason,/Malformed|Out-of-sequence|output limit/);
  }
});

test('completion waits for split pipe boundaries and checks response identity',async t=>{
  for(const corrupt of [false,true]){
    const f=protocolFixture(t,`const bytes=JSON.stringify({status:'ok',phase:'parse',exitCode:0});fs.writeFileSync(r.response,bytes);fs.writeFileSync(r.workerStdout,'');fs.writeFileSync(r.workerStderr,'');const message={id:c.id,token:c.token,done:true,rss:1,logOverflow:false,responseSha256:crypto.createHash('sha256').update(${corrupt?"'wrong'":"bytes"}).digest('hex')};fs.writeSync(3,JSON.stringify(message)+'\\n');const end='\\0BEND-END-'+c.token+'\\0';fs.writeSync(1,'before'+end.slice(0,8));setTimeout(()=>{fs.writeSync(1,end.slice(8));fs.writeSync(2,end);},40);`);
    const request=f.request(),row=await f.runner.run(request);
    assert.equal(row.result.status,corrupt?'crash':'ok');
    if(corrupt)assert.match(row.result.reason,/identity changed/);
    else assert.equal(fs.readFileSync(path.join(request.workdir,'worker.stdout'),'utf8'),'before');
  }
});

test('request deadlines must fit Node timers, and RSS recycling restores fresh state',async t=>{
  const f=fixture(t,success,{rssLimitMb:1});
  for(const timeoutMs of [0,-1,NaN,Infinity,2147483648])assert.throws(()=>f.runner.run(f.request('ok',{timeoutMs})),/timeout/);
  assert.equal((await f.runner.run(f.request())).result.calls,1);
  assert.equal((await f.runner.run(f.request())).result.calls,1);
  assert.equal(f.runner.stats.recycles,2);
});

test('a reused runner directory preserves prior session and queue identity',async t=>{
  const f=fixture(t,success),first=await f.runner.run(f.request());f.runner.close();
  const before=fs.readFileSync(first.worker.session,'utf8');
  const runner=createPersistentRunner({directory:path.join(f.root,'runner')});
  try{const second=await runner.run(f.request());assert.notEqual(second.worker.session,first.worker.session);assert.equal(fs.readFileSync(first.worker.session,'utf8'),before);}finally{runner.close();}
});

const project=path.resolve(import.meta.dirname,'../..');
const upstream=process.env.BEND_UPSTREAM||path.join(project,'.bootstrap/upstream-phase23');
test('CLI retained failure replays its deleted successful prefix and rejects tampering',{skip:!fs.existsSync(path.join(upstream,'tests'))},t=>{
  const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-persistent-cli-'));t.after(()=>fs.rmSync(directory,{recursive:true,force:true}));
  const adapter=path.join(directory,'adapter.mjs'),selection=path.join(directory,'selection.json'),output=path.join(directory,'result.json');
  fs.writeFileSync(adapter,`export const capabilities={check:true};export const persistentLanes=['check'];export async function probe(){throw Error('isolated must not run')};export async function createPersistentSession(){let calls=0;return {async probe(){calls++;return calls===1?{status:'ok',phase:'check',checked:true,exitCode:0,calls}:{status:'error',phase:'check',checked:true,exitCode:1,diagnostic:'controlled',calls}}}}`);
  const files=['first','second'].map(name=>{const file=path.join(directory,name+'.bend');fs.writeFileSync(file,'def main() -> U32:\n  42\n');return file;});
  fs.writeFileSync(selection,JSON.stringify(files.map((file,i)=>({id:'persistent/'+i,file,accept:true,lane:'check'}))));
  const child=spawnSync(process.execPath,[path.join(project,'tools/conformance/run.mjs'),'--upstream',upstream,'--adapter',adapter,'--selection',selection,'--output',output,'--jobs','1','--timeout','3000','--retain','failed','--worker-mode','persistent','--selected-exit','1'],{encoding:'utf8',timeout:15000});
  assert.ok(fs.existsSync(output),child.stderr);const report=JSON.parse(fs.readFileSync(output,'utf8'));
  assert.equal(child.status,1,child.stderr);assert.equal(report.selectedComplete,false);assert.equal(report.complete,false);
  assert.equal(report.results[0].status,'pass');assert.equal(report.results[1].status,'fail');
  const row=report.results[1],requestFile=path.join(row.artifacts,'request.json'),request=JSON.parse(fs.readFileSync(requestFile,'utf8'));
  const session=JSON.parse(fs.readFileSync(request.workerSession.file,'utf8'));
  assert.equal(fs.existsSync(session.requests[0].request.workdir),false);
  const replay=()=>spawnSync(row.replay[0],row.replay.slice(1),{encoding:'utf8',timeout:15000});
  const observed=replay();assert.equal(observed.status,1,observed.stderr);assert.equal(JSON.parse(observed.stdout).result.calls,2);
  delete session.requests[0].resultDigest;fs.writeFileSync(request.workerSession.file,JSON.stringify(session));
  const missing=replay();assert.equal(missing.status,1);assert.match(missing.stderr,/prefix is incomplete or changed/);
});
