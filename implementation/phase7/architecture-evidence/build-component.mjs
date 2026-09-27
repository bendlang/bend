// Research components are actually checked by the maintained stage0 builder.
// They are not B1 compiler releases and do not change the installed compiler.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {pathToFileURL} from 'node:url';
const repo=path.resolve(import.meta.dirname,'../../..');
const project=path.join(repo,'selfhost');
const upstream=path.join(project,'.bootstrap/upstream');
const [destination,extra,...roots]=process.argv.slice(2);
if(!destination||!extra||!roots.length)throw Error('destination module root...');
const out=path.resolve(destination),module=path.resolve(extra);
if(fs.existsSync(out))throw Error('Fresh evidence directory required');
fs.mkdirSync(out,{recursive:true});
const sha=b=>createHash('sha256').update(b).digest('hex');
const report={kind:'checked-stage0-research-component',started:new Date().toISOString(),node:process.version,complete:false,pass:false,roots,inputs:[]};
const save=()=>fs.writeFileSync(path.join(out,'build.json'),JSON.stringify(report,null,2)+'\n');
const capture=file=>{const bytes=fs.readFileSync(file);report.inputs.push({file,sha256:sha(bytes),bytes:bytes.length});return bytes};
try {
  const manifest=JSON.parse(capture(path.join(project,'src/compiler.json')));
  const revision=spawnSync('git',['-C',upstream,'rev-parse','HEAD'],{encoding:'utf8'});
  if(revision.status!==0||revision.stdout.trim()!==manifest.upstream)throw Error('Upstream pin mismatch');
  report.upstream=manifest.upstream;
  for(const file of ['bend.ts','comp.ts','base.bend'])capture(path.join(upstream,'bend2',file));
  const snapshot=path.join(out,'snapshot');fs.mkdirSync(snapshot);
  for(const relative of manifest.modules){const target=path.join(snapshot,relative);fs.mkdirSync(path.dirname(target),{recursive:true});fs.writeFileSync(target,capture(path.join(project,relative)))}
  fs.writeFileSync(path.join(snapshot,'experiment.bend'),capture(module));
  for(const name of ['assemble.mjs','stage0-library.mjs'])fs.writeFileSync(path.join(snapshot,name),capture(path.join(project,'tools',name)));
  fs.writeFileSync(path.join(out,'runner.mjs'),capture(import.meta.filename));
  const {assemble}=await import(pathToFileURL(path.join(snapshot,'assemble.mjs')));
  const source=path.join(out,'component.bend'),api=path.join(out,'api.mjs');
  report.assembly=assemble([...manifest.modules,'experiment.bend'],source,{root:snapshot});
  const args=['-c','0',process.execPath,'--stack-size=4096','--max-old-space-size=4096',path.join(snapshot,'stage0-library.mjs'),source,api,...roots];
  report.command=['taskset',...args];save();
  const start=performance.now();
  const child=spawnSync('taskset',args,{cwd:project,env:{...process.env,BEND_UPSTREAM:upstream,BEND_BASE:path.join(upstream,'bend2/base.bend')},encoding:'utf8',timeout:180000,maxBuffer:32*1024*1024});
  fs.writeFileSync(path.join(out,'stdout.txt'),child.stdout??'');fs.writeFileSync(path.join(out,'stderr.txt'),child.stderr??'');
  report.execution={exit:child.status,signal:child.signal,error:child.error?.message,wallMs:performance.now()-start};
  report.unchanged=report.inputs.every(x=>sha(fs.readFileSync(x.file))===x.sha256);
  report.complete=child.status!==null&&!child.error&&report.unchanged;
  report.pass=report.complete&&child.status===0;
  if(fs.existsSync(api))report.api={path:api,sha256:sha(fs.readFileSync(api)),bytes:fs.statSync(api).size};
}catch(error){report.error=String(error.stack??error)}
report.finished=new Date().toISOString();save();console.log(JSON.stringify(report));
process.exitCode=report.pass?0:1;
