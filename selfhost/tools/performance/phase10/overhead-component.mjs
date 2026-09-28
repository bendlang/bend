// Actual checked source components, not generated transforms or B1 artifacts.
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [beforeArg,afterArg,outArg]=process.argv.slice(2);
const out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const upstream=path.resolve('selfhost/.bootstrap/upstream-phase8');
const node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const roots=['lookup','book_cached','book_context','book_put','index_hash','index_set','index_find','index_child_list','missing'];
const modules=['term','index','normalize','graph'].map(x=>'src/core/'+x+'.bend');
const control=path.join(out,'persistent-index.test.mjs');
// Existing controls import their ABI helper; preserve them at a depth where that
// relative import resolves to a frozen copy, with an explicit source identity.
const abiSource=path.resolve('selfhost/tools/compiler-abi.mjs');
let controlText=fs.readFileSync('selfhost/tools/performance/rapid/persistent-index.test.mjs','utf8');
controlText=controlText.replace("'../../compiler-abi.mjs'",JSON.stringify(pathToFileURL(abiSource).href));
fs.writeFileSync(control,controlText);
const report={kind:'phase10-checked-index-components',cpu:3,componentNotB1:true,pass:false,inputs:[identity(import.meta.filename),identity(node),identity('selfhost/tools/performance/rapid/persistent-index.test.mjs'),identity(abiSource),...['bend.ts','comp.ts','base.bend'].map(x=>identity(path.join(upstream,'bend2',x)))],commands:[],apis:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const env={...process.env};for(const k of Object.keys(env))if(k.startsWith('BEND_')||k==='NODE_OPTIONS')delete env[k];
Object.assign(env,{BEND_UPSTREAM:upstream,BEND_BASE:path.join(upstream,'bend2/base.bend')});
function run(label,args){const argv=['-c','3',node,'--stack-size=4096',...args];const r=spawnSync('taskset',argv,{encoding:'utf8',env,timeout:90000,maxBuffer:16*1024*1024});fs.writeFileSync(path.join(out,label+'.stdout'),r.stdout??'');fs.writeFileSync(path.join(out,label+'.stderr'),r.stderr??'');report.commands.push({label,argv,status:r.status,signal:r.signal,error:r.error?.message});save();if(r.status!==0)throw Error(label+' failed');}
try{
 for(const [label,arg] of [['baseline',beforeArg],['candidate',afterArg]]){
  const project=fs.realpathSync(arg),source=path.join(out,label+'.bend'),api=path.join(out,label+'.mjs');
  const {assemble}=await import(pathToFileURL(path.join(project,'tools/assemble.mjs')));assemble(modules,source,{root:project});
  report.inputs.push(identity(source),...modules.map(x=>identity(path.join(project,x))),identity(path.join(project,'tools/assemble.mjs')),identity(path.join(project,'tools/stage0-library.mjs')));save();
  run(label+'-build',[path.join(project,'tools/stage0-library.mjs'),source,api,...roots]);report.apis.push({label,...identity(api)});save();
 }
 run('persistent',[control,path.join(out,'candidate.mjs'),path.join(out,'baseline.mjs')]);
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);report.pass=report.changedInputs.length===0;
}catch(e){report.error=e.stack;}
save();console.log(JSON.stringify({pass:report.pass,error:report.error,out}));if(!report.pass)process.exitCode=1;
