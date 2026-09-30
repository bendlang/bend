// Explicit corpus metadata preparation; invocation rewrites only metadata.json.
import fs from 'node:fs';
import path from 'node:path';
import {expected} from './oracles.mjs';
const file=path.join(import.meta.dirname,'metadata.json');
const rows=JSON.parse(fs.readFileSync(file,'utf8'));
const tail=new Set(['scalar-arithmetic','boolean-choice','boolean-worker','closure-capture','string-hash','string-scan','string-equality','tree-fold','tree-shared','pinned-u32-wide']);
for(const r of rows){
 const point=(size,seed)=>({size,seed,expected:expected(r.id,size,seed)});
 r.inputs=r.inputs.map(x=>point(x.size,x.seed));
 r.benchmarkInputs=r.id==='host-boundary'?[point(0,17)]:tail.has(r.id)?[point(256,17),point(1024,18)]:[point(32,17),point(256,18)];
 const seen=new Set();
 r.correctness=[...r.inputs,...r.benchmarkInputs].filter(x=>{const k=x.size+':'+x.seed;if(seen.has(k))return false;seen.add(k);return true;});
 r.oracle='corpus/oracles.mjs:expected';
}
fs.writeFileSync(file,JSON.stringify(rows,null,2)+'\n');
