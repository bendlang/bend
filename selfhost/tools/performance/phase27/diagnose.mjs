// Separate runtime helper counts from clean timing; reuse exact Phase25 guards.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {gzipSync,gunzipSync} from 'node:zlib';
import {fileURLToPath} from 'node:url';
import {runDiagnostic} from '../phase25/diagnostics.mjs';
import {analyzeCorpus} from '../phase25/structure.mjs';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
const [configFile,out]=process.argv.slice(2),config=JSON.parse(fs.readFileSync(configFile));
fs.mkdirSync(out);
const inputs=[configFile,import.meta.filename,process.execPath,fileURLToPath(new URL('../phase25/diagnostics.mjs',import.meta.url)),fileURLToPath(new URL('../phase25/structure.mjs',import.meta.url))].map(identity);
const report={kind:'phase27-arm-mechanism',complete:false,inputs,rows:[],
  scope:'Exact named helper entries for10 complete benchmark calls per variant. partialApplications counts the branch inside generic apply, not all final bound descriptors; the optimized path still constructs its final partial record.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const entries=[];
for(const c of config.cases)for(const variant of ['old','candidate']){
  const module=c.modules[variant];inputs.push(identity(module));
  const counterRuntime=config.runtimes[variant];inputs.push(identity(counterRuntime));
  const {size,seed,expected}=c.point;
  const directory=path.join(out,c.id+'-'+variant);
  const result=await runDiagnostic({module,counterRuntime,size,seed,expectedResult:expected,repetitions:10,counterRepetitions:10,warmup:3,modes:['counters']},directory);
  assert.equal(result.status,'pass');
  report.rows.push({id:c.id,variant,report:identity(path.join(directory,'report.json')),...result.counters});save();
  entries.push({id:c.id,variant,family:'selfhost',path:module,runtimePath:counterRuntime});
}
const structure=analyzeCorpus({entries});
const raw=Buffer.from(JSON.stringify(structure,null,2)+'\n'),compressed=gzipSync(raw);assert.deepEqual(gunzipSync(compressed),raw);
fs.writeFileSync(path.join(out,'structure.json.gz'),compressed,{flag:'wx'});report.structure=identity(path.join(out,'structure.json.gz'));
report.sizes=structure.entries.map(e=>({id:e.id,variant:e.variant,bytes:e.bytes,program:e.sections.program,prebindSites:fs.readFileSync(e.path,'utf8').split('/* prebind-arm */').length-1}));
for(const input of inputs)verifyIdentity(input);report.complete=true;save();
console.log(JSON.stringify({complete:true,counterRuns:report.rows.length}));
