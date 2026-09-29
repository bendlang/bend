import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt,identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
const [attemptArg,profileArg,outArg]=process.argv.slice(2);
const attempt=fs.realpathSync(attemptArg),profile=fs.realpathSync(profileArg),out=path.resolve(outArg);
const m=await verifyAttempt(attempt);assert.equal(m.api.sha256,'44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0');
fs.mkdirSync(out);
const original=fs.readFileSync(m.api.file,'utf8');let source=original;
const edits=[];
function replace(before,after){assert.equal(source.split(before).length-1,1,before);source=source.replace(before,after);edits.push({before,after});}
replace('$index_remove$({$: "Con", "head": _h_0, "tail": _rest_0}, ($dn$(_d_0)))','$index_remove$({$: "Con", "head": _h_0, "tail": _rest_0}, ($dn$(_d_0)), __phase22_root("book-put-uncached"))');
replace('$index_remove$(_done_0, ($dn$(_d_0)))','$index_remove$(_done_0, ($dn$(_d_0)), __phase22_root("book-final-legacy"))');
replace('f: $index_remove$, x: [_rest_0, _name_0]','f: $index_remove$, x: [_rest_0, _name_0, __phase22_root("book-put-cached")]');
replace('$index_remove$(_ds_0, ($dn$(_d_0)))','$index_remove$(_ds_0, ($dn$(_d_0)), __phase22_root("index-leaf"))');
const old=`function $index_remove$(_ds_0, _name_0) {
  if (_ds_0.$ === "Nil") {
    return {$: "Nil"};
  } else {
    const _h_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return run_tail((($String$eq$(($dn$(_h_0)), _name_0))) ? ((_x_0) => {
  return $index_remove$(_rest_0, _name_0);
}) : ((_x_1) => {
  return {$: "Con", "head": _h_0, "tail": run_loop($index_remove$(_rest_0, _name_0))};
}), {$: "Unit"});
  }
}`;
const next=`function $index_remove$(_ds_0, _name_0, _p=__phase22_root("unknown"), _after=false) {
  if (_ds_0.$ === "Nil") {
    const z=__phase22_counts[_p.kind];z.completed++;z.visited+=_p.visited;z.removed+=_p.removed;z.kept+=_p.kept;z.keptAfterFirst+=_p.keptAfterFirst;z.maxVisited=Math.max(z.maxVisited,_p.visited);z[_p.removed===0?"missRoots":_p.removed===1?"singleRoots":"duplicateRoots"]++;
    return {$: "Nil"};
  } else {
    _p.visited++;
    const _h_0 = _ds_0["head"];
    const _rest_0 = _ds_0["tail"];
    return run_tail((($String$eq$(($dn$(_h_0)), _name_0))) ? ((_x_0) => {
  _p.removed++;return $index_remove$(_rest_0, _name_0, _p, true);
}) : ((_x_1) => {
  _p.kept++;if(_after)_p.keptAfterFirst++;
  return {$: "Con", "head": _h_0, "tail": run_loop($index_remove$(_rest_0, _name_0, _p, _after))};
}), {$: "Unit"});
  }
}`;
replace(old,next);
source+='\nconst __phase22_counts={};\nfunction __phase22_root(kind){const z=__phase22_counts[kind]??=( {roots:0,completed:0,visited:0,removed:0,kept:0,keptAfterFirst:0,maxVisited:0,missRoots:0,singleRoots:0,duplicateRoots:0});z.roots++;return {kind,visited:0,removed:0,kept:0,keptAfterFirst:0};}\nexport function __phase22_index_remove_counts(){return __phase22_counts;}\n';
const api=path.join(out,'instrumented-api.mjs');fs.writeFileSync(api,source,{flag:'wx'});
fs.writeFileSync(path.join(out,'edits.json'),JSON.stringify({parent:identity(m.api.file),artifact:identity(api),edits,addedExport:'__phase22_index_remove_counts',checkedProductionArtifact:false},null,2)+'\n',{flag:'wx'});
const worker=path.join(out,'worker.mjs');fs.copyFileSync(new URL('./index-remove-count-worker-v2.mjs',import.meta.url),worker);
const originalRequest=JSON.parse(fs.readFileSync(path.join(profile,'request.json')));
const request={...originalRequest,instrumentedApi:api,driver:path.join(m.snapshot.root,'tools/typed-driver.mjs'),baselineResult:path.join(profile,'result.json')};
request.inputs=[...originalRequest.inputs,...[api,worker,import.meta.filename,path.join(profile,'result.json')].map(identity)];
const requestFile=path.join(out,'request.json'),resultFile=path.join(out,'result.json');fs.writeFileSync(requestFile,JSON.stringify(request,null,2)+'\n',{flag:'wx'});
const report={kind:'phase22-index-remove-diagnostic-census',complete:false,pass:false,started:new Date().toISOString(),inputs:request.inputs,originalApi:identity(m.api.file),instrumentedApi:identity(api),scope:'Four call-site counters and original list branch construction counts only; unchanged host explicit API injection, current original cache bytes unchanged, no speed claim.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
try{report.execution=await supervise('taskset',['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,requestFile,resultFile],{directory:path.join(out,'process'),env:process.env,timeoutMs:600000});requireExecution(report.execution);const result=JSON.parse(fs.readFileSync(resultFile));assert.ok(result.complete&&result.pass);for(const x of request.inputs)verifyIdentity(x);await verifyAttempt(attempt);report.result=identity(resultFile);report.complete=report.pass=true;}catch(e){report.error=String(e.stack??e);process.exitCode=1;}report.finished=new Date().toISOString();save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,error:report.error}));
