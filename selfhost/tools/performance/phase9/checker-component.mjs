// Supplemental checked component, not a B1 bootstrap or performance sample.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
const [projectArg,upstreamArg,outputArg]=process.argv.slice(2);
const project=fs.realpathSync(projectArg),upstream=fs.realpathSync(upstreamArg),output=path.resolve(outputArg);
fs.mkdirSync(output,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const modules=JSON.parse(fs.readFileSync(path.join(project,'src/compiler.json'))).modules;
const controls=path.join(output,'controls.mjs');fs.copyFileSync(path.join(import.meta.dirname,'checker-controls.mjs'),controls);
const source=path.join(output,'compiler.bend'),api=path.join(output,'component.mjs');
const {assemble}=await import(pathToFileURL(path.join(project,'tools/assemble.mjs')));assemble(modules,source,{root:project});
const upstreamRevision=spawnSync('git',['-C',upstream,'rev-parse','HEAD'],{encoding:'utf8'});
if(upstreamRevision.status!==0||upstreamRevision.stdout.trim()!=='b2111cf43244e65f76ddc278ee695e669f720cbf')throw Error('Wrong upstream revision');
const inputs=[process.execPath,import.meta.filename,controls,source,path.join(project,'src/compiler.json'),...modules.map(f=>path.join(project,f)),...['tools/stage0-library.mjs','tools/assemble.mjs','tests/kernel.mjs','tests/normalize.mjs'].map(f=>path.join(project,f)),...['bend.ts','comp.ts','base.bend'].map(f=>path.join(upstream,'bend2',f))].map(identity);
const report={kind:'checked-checker-component',scope:'Complete source checked by pinned upstream, selected private exports emitted; not B1 or fixed point.',started:new Date().toISOString(),upstreamRevision:upstreamRevision.stdout.trim(),cpu:'1',inputs,commands:[],pass:false};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||key==='NODE_OPTIONS')delete env[key];
Object.assign(env,{BEND_UPSTREAM:upstream,BEND_BASE:path.join(upstream,'bend2/base.bend'),BEND_KERNEL_API:api,BEND_ANNOTATE_API:api,BEND_NORMALIZE_API:api});
function run(label,args){
  const argv=['-c','1',process.execPath,'--stack-size=4096','--max-old-space-size=4096',...args];
  const result=spawnSync('taskset',argv,{encoding:'utf8',env,cwd:project,timeout:120000,maxBuffer:32*1024*1024});
  fs.writeFileSync(path.join(output,label+'.stdout'),result.stdout??'');fs.writeFileSync(path.join(output,label+'.stderr'),result.stderr??'');
  report.commands.push({label,command:'taskset',argv,status:result.status,signal:result.signal,error:result.error?String(result.error):null});save();
  if(result.status!==0||result.signal||result.error)throw Error('Failed '+label);
}
try{
  run('build',[path.join(project,'tools/stage0-library.mjs'),source,api,'check_book','check','infer','annotate_book','wnf','strong','compare','norm_compare']);
  report.api=identity(api);save();
  run('kernel',[path.join(project,'tests/kernel.mjs')]);
  run('normalize',[path.join(project,'tests/normalize.mjs')]);
  run('boundaries',[controls,api]);
  report.changedInputs=inputs.filter(before=>identity(before.file).sha256!==before.sha256);
  report.pass=report.changedInputs.length===0;
}catch(error){report.error=String(error.stack??error);}
report.finished=new Date().toISOString();save();console.log(JSON.stringify({pass:report.pass,error:report.error,output}));
if(!report.pass)process.exitCode=1;
