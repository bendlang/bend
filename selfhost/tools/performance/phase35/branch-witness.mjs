// Diagnostic admission witness. This derivative must never be timed.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2);
assert(baseArg&&outArg,'usage: branch-witness.mjs DERIVED_DIR NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);
assert(!fs.existsSync(out),'output must be new');
const hash=x=>createHash('sha256').update(x).digest('hex');
const identity=file=>({path:fs.realpathSync(file),sha256:hash(fs.readFileSync(file))});
const manifestFile=path.join(base,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
assert.equal(manifest.kind,'phase35-final-bool-loop-prototype');assert.equal(manifest.complete,true);
const branchFile=path.join(base,'branch.mjs'),baselineFile=path.join(base,'baseline.mjs');
for(const name of ['branch','baseline']){
 const row=manifest.modules.find(x=>x.variant===name);assert(row,'missing variant '+name);
 assert.equal(identity(path.join(base,name+'.mjs')).sha256,row.sha256,'modified parent '+name);
}
const marker='/* private Bool loop prototype */',source=fs.readFileSync(branchFile,'utf8');
assert.equal(source.split(marker).length,2,'one exact admission marker required');
assert(!source.includes('$phase35BranchAdmissionCount'),'witness already instrumented');
const derived=source.replace(marker,marker+'++$phase35BranchAdmissionCount;')+
 '\nlet $phase35BranchAdmissionCount=0;\nexport const phase35BranchAdmissionCount=()=> $phase35BranchAdmissionCount;\n';
fs.mkdirSync(out,{recursive:false});
const moduleFile=path.join(out,'witness.mjs');fs.writeFileSync(moduleFile,derived,{flag:'wx'});
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-witness.mjs'));
const report={kind:'phase35-final-bool-loop-admission-witness',complete:false,pass:false,node:process.version,
 warning:'Diagnostic counter changes generated code. Never use this module for performance evidence.',
 inputs:[import.meta.filename,manifestFile,branchFile,baselineFile].map(identity),instrumented:identity(moduleFile),points:[]};
try{
 const baseline=await import(pathToFileURL(baselineFile)),witness=await import(pathToFileURL(moduleFile));
 for(const count of [0,1,1000]){
  const before=witness.phase35BranchAdmissionCount(),expected=baseline.default.bench(count,0),actual=witness.default.bench(count,0);
  const admitted=witness.phase35BranchAdmissionCount()-before;
  report.current={kind:'bench',args:[count,0],expected,actual,expectedAdmissions:count,admitted};
  assert.equal(actual,expected,'instrumented result');assert.equal(admitted,count,'normal final callback must enter once per outer nearest.t call');
  report.points.push(report.current);delete report.current;
 }
 for(const n of [0n,1n,9n])for(const flag of [false,true]){
  const args=[n,0,0,0,0,0,1,1000000000,1000000000,flag],before=witness.phase35BranchAdmissionCount();
  const expected=baseline.default['nearest.t'](...args),actual=witness.default['nearest.t'](...args),admitted=witness.phase35BranchAdmissionCount()-before;
  report.current={kind:'direct',n:String(n),flag,expected,actual,expectedAdmissions:n===0n?0:1,admitted};
  assert(Object.is(actual,expected),'direct instrumented result');assert.equal(admitted,n===0n?0:1,'zero/public successor admission');
  report.points.push(report.current);delete report.current;
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);
 report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,points:report.points,error:report.error}));
