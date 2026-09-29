// Build only the shared foreign scanner; its complete dependencies are checked.
import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {assemble} from '../../tools/assemble.mjs';
const root=path.resolve(import.meta.dirname,'../..');
const output=path.resolve(process.argv[2]);
const source=path.join(output,'scanner.bend'),api=path.join(output,'api.mjs');
if(fs.existsSync(api)||fs.existsSync(source))throw Error('Use a fresh output directory');
fs.mkdirSync(output,{recursive:true});
fs.copyFileSync(import.meta.filename,path.join(output,'scanner-build.mjs'));
// Isolate scanner edits from the concurrently owned graph-conversion changes.
const stable=['normalize','graph'].map(name=>{
  const r=spawnSync('git',['show','fb4245719005f3c84000a4ff710ddfd180179e01:selfhost/src/core/'+name+'.bend'],{cwd:root,encoding:'utf8'});
  if(r.status!==0)throw Error(r.stderr||r.error?.message);
  const file=path.join(output,name+'.bend');fs.writeFileSync(file,r.stdout);return file;
});
assemble(['src/core/term.bend','src/core/index.bend',...stable,'src/core/reach.bend'],source,{root});
const run=spawnSync(process.execPath,['--stack-size=4096','--max-old-space-size=1024',path.join(root,'tools/stage0-library.mjs'),source,api,'kf_source'],{encoding:'utf8',timeout:120000,env:{...process.env,BEND_UPSTREAM:process.env.BEND_UPSTREAM||path.join(root,'.bootstrap/upstream-phase23')}});
fs.writeFileSync(path.join(output,'build.json'),JSON.stringify({status:run.status,signal:run.signal,stdout:run.stdout,stderr:run.stderr,error:run.error?.message},null,2)+'\n');
process.stdout.write(run.stdout);process.stderr.write(run.stderr);process.exitCode=run.status??1;
