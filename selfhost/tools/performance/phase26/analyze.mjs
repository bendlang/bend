// Untimed mechanism evidence: exact guarded counters and parsed JS structure.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {gzipSync,gunzipSync} from 'node:zlib';
import {fileURLToPath} from 'node:url';
import {runDiagnostic} from '../phase25/diagnostics.mjs';
import {analyzeCorpus} from '../phase25/structure.mjs';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
const [configFile,output]=process.argv.slice(2),config=JSON.parse(fs.readFileSync(configFile));
fs.mkdirSync(output);
const save=(name,x)=>fs.writeFileSync(path.join(output,name),JSON.stringify(x,null,2)+'\n',{flag:'wx'});
const inputs=[identity(configFile),identity(import.meta.filename),identity(process.execPath),identity(fileURLToPath(new URL('../phase25/diagnostics.mjs',import.meta.url))),identity(fileURLToPath(new URL('../phase25/structure.mjs',import.meta.url)))];
const chosen=config.cases.filter(c=>['pinned-u32-table','pinned-u32-wide','numeric-direct'].includes(c.id));
const entries=[],counters=[];
for(const c of chosen)for(const [variant,module] of Object.entries(c.modules)){
  const source=identity(module);inputs.push(source);
  entries.push({id:c.id,variant,family:variant==='upstream'?'upstream':'selfhost',path:module});
  if(variant==='upstream')continue;
  const {size,seed,expected}=c.point;
  const out=path.join(output,c.id+'-'+variant);
  const report=await runDiagnostic({module,size,seed,expectedResult:expected,repetitions:10,counterRepetitions:10,warmup:3,modes:['counters']},out);
  assert.equal(report.status,'pass');
  counters.push({id:c.id,variant,report:identity(path.join(out,'report.json')),...report.counters});
}
const structure=analyzeCorpus({entries}),raw=Buffer.from(JSON.stringify(structure,null,2)+'\n'),compressed=gzipSync(raw);
assert.deepEqual(gunzipSync(compressed),raw);
fs.writeFileSync(path.join(output,'structure.json.gz'),compressed,{flag:'wx'});
const owners={'pinned-u32-table':['pop'],'pinned-u32-wide':['key'],'numeric-direct':['dense','sparse']};
const summary=structure.entries.map(e=>({id:e.id,variant:e.variant,moduleBytes:e.bytes,
  selectedOwners:e.programUnits.filter(u=>u.owners.some(n=>owners[e.id].includes(n))).map(u=>({owners:u.owners,bytes:u.bytes,metrics:u.metricsInclusive}))}));
for(const i of inputs)verifyIdentity(i);
save('report.json',{complete:true,inputs,counters,structure:identity(path.join(output,'structure.json.gz')),summary,
  scope:'Ten checked calls per counter run; separate from uninstrumented timing. Static counts do not measure allocation or frequency; counters count exact runtime helper entries, not all JS allocations.'});
console.log(JSON.stringify({complete:true,counterRuns:counters.length,structureEntries:entries.length,summary}));
