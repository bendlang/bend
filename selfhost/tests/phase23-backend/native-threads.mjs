// Reuse retained emitted binaries; no compiler rebuild or artifact mutation.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {spawnSync} from 'node:child_process';
const out=path.resolve(process.argv[2]),runs=process.argv.slice(3).map(p=>path.resolve(p));if(fs.existsSync(out))throw Error('Use a fresh output directory');fs.mkdirSync(out,{recursive:true});
const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const wanted=new Set(['run/array_redirect_race.bend','reg/spin_array_hold.bend','shared_array_ownership_v2','parallel_rows','atomic_operations_v3']);
const programs=[];
for(const run of runs){const dir=path.join(run,'selected/candidate.json.artifacts');for(const child of fs.readdirSync(dir)){const file=path.join(dir,child,'request.json');if(!fs.existsSync(file))continue;const r=JSON.parse(fs.readFileSync(file));if(r.lane!=='native'||!wanted.has(r.test.id))continue;const binary=path.join(dir,child,path.basename(r.test.file,'.bend'));programs.push({id:r.test.id,file:binary,sha256:sha(binary),sourceSha256:sha(binary+'.c'),expected:r.test.expected+'\n'});}}
if(programs.length!==5)throw Error('Expected five retained native programs');
const report={kind:'phase23-native-thread-repeat',cpu:'3,4,5,6',programs,complete:false,pass:false,rows:[]},save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));save();
for(const p of programs)for(const threads of [1,2,3,4])for(let repetition=0;repetition<5;repetition++){
 const run=spawnSync('taskset',['-c','3,4,5,6',p.file,'--threads',String(threads),'--gpu','off'],{encoding:'utf8',timeout:10000,maxBuffer:1<<20});
 const row={id:p.id,threads,repetition,status:run.status,signal:run.signal,error:run.error?.message??null,stdout:run.stdout,stderr:run.stderr};row.pass=run.status===0&&run.stdout===p.expected&&run.stderr==='';report.rows.push(row);save();
}
for(const p of programs)if(sha(p.file)!==p.sha256||sha(p.file+'.c')!==p.sourceSha256)throw Error('Native artifact changed');report.complete=true;report.pass=report.rows.every(x=>x.pass);save();console.log(JSON.stringify({pass:report.pass,cases:report.rows.length,failures:report.rows.filter(x=>!x.pass).slice(0,5)}));process.exitCode=report.pass?0:1;
