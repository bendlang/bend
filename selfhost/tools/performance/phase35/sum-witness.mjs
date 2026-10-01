// Diagnostic-only derivative: prove region admission and private tree visits.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2);assert(baseArg&&outArg,'usage: sum-witness.mjs DERIVED_DIR NEW_OUT');
const base=path.resolve(baseArg),out=path.resolve(outArg);assert(!fs.existsSync(out),'output must be new');
const hash=x=>createHash('sha256').update(x).digest('hex'),identity=f=>({path:fs.realpathSync(f),sha256:hash(fs.readFileSync(f))});
const manifestFile=path.join(base,'derive.json'),manifest=JSON.parse(fs.readFileSync(manifestFile));
assert.equal(manifest.kind,'phase35-private-sum-prototype');assert.equal(manifest.complete,true);
fs.mkdirSync(out,{recursive:false});fs.copyFileSync(import.meta.filename,path.join(out,'consumed-witness.mjs'));
const report={kind:'phase35-private-sum-admission-witness',complete:false,pass:false,node:process.version,
 warning:'Counter derivatives are diagnostic artifacts and must never be timed.',inputs:[import.meta.filename,manifestFile].map(identity),modules:[],points:[]};
try{
 for(const variant of ['loop','sums']){
  const originalFile=path.join(base,variant+'.mjs'),originalSource=fs.readFileSync(originalFile,'utf8');
  assert.equal(hash(originalSource),manifest.modules.find(x=>x.variant===variant).sha256);report.inputs.push(identity(originalFile));
  const marker=`/* private sum ${variant} prototype */`;assert.equal(originalSource.split(marker).length,2);
  for(const marker of ['function $sumEval(e,x){','function $sumSize(e){'])assert.equal(originalSource.split(marker).length,2);
  const source=originalSource.replace(marker,marker+'++$sumAdmissionWitness;')
   .replace('function $sumEval(e,x){','function $sumEval(e,x){++$sumEvalWitness;')
   .replace('function $sumSize(e){','function $sumSize(e){++$sumSizeWitness;')+
   '\nlet $sumAdmissionWitness=0,$sumEvalWitness=0,$sumSizeWitness=0;\nexport const sumWitness=()=>[$sumAdmissionWitness,$sumEvalWitness,$sumSizeWitness];\n';
  const file=path.join(out,variant+'.mjs');fs.writeFileSync(file,source,{flag:'wx'});report.modules.push({variant,...identity(file)});
  const clean=await import(pathToFileURL(originalFile)),witness=await import(pathToFileURL(file));
  for(const pts of [0n,1n,16n]){const before=witness.sumWitness(),expected=clean.default.cand(42,pts),actual=witness.default.cand(42,pts);
   const counts=witness.sumWitness().map((n,i)=>n-before[i]),expectedCounts=[1,variant==='sums'?63*Number(pts):0,variant==='sums'?63:0];
   report.current={variant,kind:'candidate',pts:String(pts),expected,actual,counts,expectedCounts};assert.deepEqual(actual,expected);assert.deepEqual(counts,expectedCounts);
   report.points.push(report.current);delete report.current;
  }
  const before=witness.sumWitness(),expected=clean.default.bench(6,42),actual=witness.default.bench(6,42);
  const counts=witness.sumWitness().map((n,i)=>n-before[i]),expectedCounts=[96,variant==='sums'?96*63*16:0,variant==='sums'?96*63:0];
  report.current={variant,kind:'original-bench',args:[6,42],expected,actual,counts,expectedCounts};assert.equal(actual,2490246820);assert.equal(actual,expected);assert.deepEqual(counts,expectedCounts);
  report.points.push(report.current);delete report.current;
 }
 for(const row of report.inputs)assert.deepEqual(identity(row.path),row);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({complete:report.complete,pass:report.pass,points:report.points.length,error:report.error}));
