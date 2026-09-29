import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnFileSync as spawnSync} from '../helpers/spawn-file-sync.mjs';
import test from 'node:test';
const root=path.resolve(import.meta.dirname,'../..'),upstream=process.env.BEND_UPSTREAM||path.join(root,'.bootstrap/upstream-phase23'),available=fs.existsSync(path.join(upstream,'tests'));
const directory=fs.mkdtempSync(path.join(os.tmpdir(),'bend-targeted-test-'));let serial=0;
process.on('exit',()=>fs.rmSync(directory,{recursive:true,force:true}));
function run(body,{timeout=3000}={}){
  const folder=path.join(directory,String(serial++));fs.mkdirSync(folder);
  const adapter=path.join(folder,'adapter.mjs'),selection=path.join(folder,'selection.json'),output=path.join(folder,'result.json');
  fs.writeFileSync(adapter,"export const name='controlled';export const capabilities={check:true};\n"+body);
  fs.writeFileSync(selection,JSON.stringify([{id:'base/list_sort.bend',lane:'check'}]));
  const child=spawnSync(process.execPath,[path.join(root,'tools/conformance/run.mjs'),'--upstream',upstream,'--adapter',adapter,'--selection',selection,'--output',output,'--jobs','1','--timeout',String(timeout),'--retain','all','--selected-exit','1'],{encoding:'utf8',timeout:15000});
  assert.ok(fs.existsSync(output),child.stderr);return {child,folder,adapter,output,report:JSON.parse(fs.readFileSync(output,'utf8'))};
}
test('selected pass stays incomplete; retained failure replays and rejects input drift',{skip:!available},()=>{
  const pass=run("export async function probe(){return {status:'ok',phase:'check',checked:true,exitCode:0}}");
  assert.equal(pass.child.status,0,pass.child.stderr);assert.equal(pass.report.selectedComplete,true);assert.equal(pass.report.complete,false);
  const fail=run("export async function probe(){return {status:'error',phase:'check',checked:true,diagnostic:'Error: controlled',exitCode:1}}");
  assert.equal(fail.child.status,1);assert.equal(fail.report.selectedComplete,false);
  const row=fail.report.results[0];assert.ok(fs.existsSync(path.join(row.artifacts,'request.json')));assert.ok(fs.existsSync(path.join(row.artifacts,'worker.stderr')));
  const replay=spawnSync(row.replay[0],row.replay.slice(1),{encoding:'utf8',timeout:15000});assert.equal(replay.status,1,replay.stderr);assert.equal(JSON.parse(replay.stdout).result.diagnostic,'Error: controlled');
  fs.appendFileSync(fail.adapter,'\n// changed\n');const drift=spawnSync(row.replay[0],row.replay.slice(1),{encoding:'utf8',timeout:15000});assert.notEqual(drift.status,0);assert.match(drift.stderr,/adapter changed/);
});
test('artifact drift invalidates selected pass and output overflow remains a crash',{skip:!available},()=>{
  const drift=run("import fs from 'node:fs';export async function probe(){fs.appendFileSync(new URL(import.meta.url),'\\n// mutation\\n');return {status:'ok',phase:'check',checked:true,exitCode:0}}");
  assert.equal(drift.report.results[0].status,'pass');assert.equal(drift.report.identity.adapterChangedDuringRun,true);assert.equal(drift.report.selectedComplete,false);
  const overflow=run("export async function probe(){process.stdout.write('x'.repeat(2**20+100));return {status:'ok',phase:'check',checked:true,exitCode:0}}");
  assert.equal(overflow.report.results[0].status,'crash');assert.match(overflow.report.results[0].reason,/output limit/);
  assert.ok(fs.statSync(path.join(overflow.report.results[0].artifacts,'worker.stdout')).size<=2**20);
});
test('whole process group deadline kills delayed grandchildren',{skip:!available},async()=>{
  const marker=path.join(directory,'escaped-child');
  const program="setTimeout(()=>require('node:fs').writeFileSync("+JSON.stringify(marker)+",'escaped'),700)";
  const timed=run("import {spawn} from 'node:child_process';export async function probe(){spawn(process.execPath,['-e',"+JSON.stringify(program)+"],{stdio:'ignore'});while(true){}}",{timeout:150});
  assert.equal(timed.report.results[0].status,'timeout');await new Promise(resolve=>setTimeout(resolve,850));assert.equal(fs.existsSync(marker),false);
});
test('adapter-declared inputs and expected missing assets cannot drift into a selected pass',{skip:!available},()=>{
  const source=path.join(directory,'declared-input');fs.writeFileSync(source,'before');
  const modified=run("import fs from 'node:fs';export const inputFiles=["+JSON.stringify(source)+"];export async function probe(){fs.writeFileSync(inputFiles[0],'after');return {status:'ok',phase:'check',checked:true,exitCode:0}}");
  assert.equal(modified.report.selectedComplete,false);assert.ok(modified.report.changedInputs.includes(source));
  const missing=path.join(directory,'previously-missing-asset');
  const created=run("import fs from 'node:fs';export const inputFiles=["+JSON.stringify(missing)+"];export async function probe(){fs.writeFileSync(inputFiles[0],'appeared');return {status:'ok',phase:'check',checked:true,exitCode:0}}");
  assert.equal(created.report.inputHashes[missing],null);assert.equal(created.report.selectedComplete,false);assert.ok(created.report.changedInputs.includes(missing));
});
test('exact replay clears ambient configuration and rejects another Node version',{skip:!available},()=>{
  const priorTrace=process.env.BEND_TYPED_TRACE,priorCC=process.env.CC;
  try{
    process.env.BEND_TYPED_TRACE='recorded';delete process.env.CC;
    const observed=run("export async function probe(){return {status:'ok',phase:'check',checked:true,exitCode:0,trace:process.env.BEND_TYPED_TRACE,compiler:process.env.CC??null}}");
    const row=observed.report.results[0],replay=spawnSync(row.replay[0],row.replay.slice(1),{encoding:'utf8',timeout:15000,env:{...process.env,BEND_TYPED_TRACE:'ambient',CC:'ambient-compiler'}});
    assert.equal(replay.status,0,replay.stderr);const result=JSON.parse(replay.stdout).result;assert.equal(result.trace,'recorded');assert.equal(result.compiler,null);
    const request=JSON.parse(fs.readFileSync(path.join(row.artifacts,'request.json'),'utf8')),identity=JSON.parse(fs.readFileSync(request.identityFile,'utf8'));identity.nodeVersion='different';fs.writeFileSync(request.identityFile,JSON.stringify(identity));
    const wrong=spawnSync(row.replay[0],row.replay.slice(1),{encoding:'utf8',timeout:15000});assert.notEqual(wrong.status,0);assert.match(wrong.stderr,/recorded Node executable and version/);
  }finally{if(priorTrace===undefined)delete process.env.BEND_TYPED_TRACE;else process.env.BEND_TYPED_TRACE=priorTrace;if(priorCC===undefined)delete process.env.CC;else process.env.CC=priorCC;}
});
test('a same-content input symlink retarget invalidates source identity',{skip:!available},()=>{
  const first=path.join(directory,'first-source'),second=path.join(directory,'second-source'),link=path.join(directory,'source-link');fs.writeFileSync(first,'same');fs.writeFileSync(second,'same');fs.symlinkSync(first,link);
  const result=run("import fs from 'node:fs';export const inputFiles=["+JSON.stringify(link)+"];export async function probe(){fs.unlinkSync(inputFiles[0]);fs.symlinkSync("+JSON.stringify(second)+",inputFiles[0]);return {status:'ok',phase:'check',checked:true,exitCode:0}}");
  assert.equal(result.report.selectedComplete,false);assert.ok(result.report.changedInputs.includes(link));assert.equal(result.report.inputPaths[link],first);
});
