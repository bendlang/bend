import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {supervise} from '../../development/process.mjs';
const project=path.resolve(import.meta.dirname,'../../..');
const out=path.resolve(process.argv[2]);
const source=path.resolve(process.argv[3]||path.join(project,'build/phase9/integrated-03/equality/api.mjs'));
fs.mkdirSync(out);
const hash=f=>crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const names=['j_layout_term','j_layout_kind','j_layout_match','j_layout_fields','j_find_ctor','j_found_ctor','j_literal_typed','j_literal','j_nat','j_arm_type','j_arm_tel','j_type','j_type_kind','j_specialize','j_app_type','wnf','subst','j_layout_visit','j_layout_def','j_layout_open','j_constructor_count','lookup'];
let text=fs.readFileSync(source,'utf8');const found=[];
for(const name of names){const re=new RegExp('function \\$'+name+'\\$\\([^\\n]*\\) \\{');let count=0;text=text.replace(re,x=>{count++;return x+'\n  globalThis.__layoutCounts["'+name+'"]=(globalThis.__layoutCounts["'+name+'"]??0)+1;';});if(count)found.push(name);}
fs.writeFileSync(path.join(out,'instrumented-api.mjs'),'globalThis.__layoutCounts={};\n'+text);
const worker=path.join(out,'worker.mjs');fs.copyFileSync(path.join(import.meta.dirname,'layout-worker.mjs'),worker);
const report={kind:'diagnostic-layout-entry-counts',source:{file:source,sha256:hash(source)},instrumented:{file:path.join(out,'instrumented-api.mjs'),sha256:hash(path.join(out,'instrumented-api.mjs'))},driver:{file:path.join(project,'tools/typed-driver.mjs'),sha256:hash(path.join(project,'tools/typed-driver.mjs'))},node:{file:process.execPath,version:process.version,sha256:hash(process.execPath)},found,omitted:names.filter(x=>!found.includes(x)),resource:{cpu:'2',stackKiB:4096,heapMiB:4096,deadlineMs:60000},scope:'Concurrent diagnostic helper entries; compilation deliberately stops after layout; not an emitted-program success.',rows:[]};
for(const n of (process.argv[4]||'8,16,32,64,128').split(',').map(Number)){
 const file=path.join(out,'nat-'+n+'.bend');fs.writeFileSync(file,`import Base\n\ndef down(n: Nat) -> Nat:\n  match n:\n    case ${n}n:\n      down(${n-1}n)\n    case _:\n      n\n\ndef main() -> Nat:\n  Nat.add(down(${n}n), down(7n))\n\n#|${n+6}n\n`);
 const result=path.join(out,'nat-'+n+'.json');const start=performance.now();const child=await supervise('taskset',['-c','2',process.execPath,'--stack-size=4096','--max-old-space-size=4096',worker,path.join(project,'tools/typed-driver.mjs'),file,result],{env:{...process.env,BEND_TYPED_API:path.join(out,'instrumented-api.mjs'),BEND_BASE:path.join(project,'dist/base.bend')},timeoutMs:60000,directory:path.join(out,'process-'+n)});
 report.rows.push({n,file,sha256:hash(file),processMs:performance.now()-start,execution:child,result:fs.existsSync(result)?JSON.parse(fs.readFileSync(result)):null});
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report.rows.at(-1)));
}
