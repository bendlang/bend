import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
const out=path.resolve(process.argv[2]);
fs.mkdirSync(out,{recursive:false});
const root=process.cwd(), upstream=path.join(root,'selfhost/.bootstrap/upstream-phase8');
const node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';
const helper=path.join(root,'selfhost/tools/stage0-library.mjs');
const identity=file=>({file,bytes:fs.statSync(file).size,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const inputs=[import.meta.filename,node,helper,...['bend.ts','comp.ts','base.bend'].map(x=>path.join(upstream,'bend2',x))].map(identity);
const rev=spawnSync('git',['-C',upstream,'rev-parse','HEAD'],{encoding:'utf8'});
const cases={local:`import Base\n\ndef local_choice(+x: U32) -> U32:\n  +flag = U32.is_eq(x, 0)\n  match flag:\n    case True{}: 7\n    case False{}: U32.inc(x)\n`,parameter:`import Base\n\ndef parameter_choice(+flag: Bool, +x: U32) -> U32:\n  match flag:\n    case True{}: 7\n    case False{}: U32.inc(x)\n`};
const results=[];
for(const [name,source] of Object.entries(cases)){
 const file=path.join(out,name+'.bend'),api=path.join(out,name+'.mjs');fs.writeFileSync(file,source);
 const command=['taskset','-c','3',node,'--stack-size=4096',helper,file,api,name+'_choice'];
 const r=spawnSync(command[0],command.slice(1),{encoding:'utf8',timeout:30000,env:{...process.env,BEND_UPSTREAM:upstream,BEND_BASE:path.join(upstream,'bend2/base.bend')}});
 fs.writeFileSync(path.join(out,name+'.stdout'),r.stdout||'');fs.writeFileSync(path.join(out,name+'.stderr'),r.stderr||'');
 results.push({name,command,status:r.status,signal:r.signal,error:r.error?.message,input:identity(file),output:fs.existsSync(api)?identity(api):null});
}
for(const x of inputs)if(identity(x.file).sha256!==x.sha256)throw Error('Input changed: '+x.file);
const report={kind:'phase10-local-boolean-feasibility',revision:rev.stdout.trim(),inputs,results,cpu:3,componentNotB1:true};
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
