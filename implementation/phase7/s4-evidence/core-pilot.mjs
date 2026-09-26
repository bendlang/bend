// Bounded stage0/component gate for the declaration-authoring migration.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {assemble} from '../../../selfhost/tools/assemble.mjs';
import {supervise,requireExecution} from '../../../selfhost/tools/development/process.mjs';

const [baseline,pilot,upstream,destination]=process.argv.slice(2).map(x=>path.resolve(x));
const output=destination;
fs.mkdirSync(output,{recursive:false});
const digest=file=>createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity=file=>({file,sha256:digest(file)});
const modules=['src/core/term.bend','src/core/index.bend','src/core/normalize.bend','src/core/graph.bend'];
const roots=['wnf','strong','compare','lookup','book_cached','book_context','book_put'];
const report={kind:'S4-core-declaration-pilot',complete:false,pass:false,node:process.version,
  inputs:[identity(import.meta.filename),identity(process.execPath)],variants:[]};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2)+'\n');
save();
try {
  for(const [name,project] of [['baseline',baseline],['pilot',pilot]]) {
    const directory=path.join(output,name);fs.mkdirSync(directory);
    const source=path.join(directory,'core.bend'),api=path.join(directory,'api.mjs');
    const row={name,project,modules:modules.map(x=>identity(path.join(project,x))),runs:[]};
    report.variants.push(row);save();
    row.assembly=assemble(modules,source,{root:project});row.source=identity(source);save();
    const env={...process.env,BEND_UPSTREAM:upstream,BEND_NORMALIZE_API:api,BEND_INDEX_API:api};
    delete env.NODE_OPTIONS;
    async function run(label,args) {
      const execution=await supervise(process.execPath,['--stack-size=4096','--max-old-space-size=4096',...args],
        {directory:path.join(directory,label),cwd:project,env,timeoutMs:120000});
      row.runs.push({label,execution});save();requireExecution(execution);
    }
    await run('checked-build',[path.join(project,'tools/stage0-library.mjs'),source,api,...roots]);
    row.api=identity(api);
    await run('normalization',[path.join(project,'tests/normalize.mjs')]);
    await run('index',[path.join(project,'tests/index.mjs')]);
    for(const input of [...row.modules,row.source,row.api])assert.equal(digest(input.file),input.sha256,'changed '+input.file);
    save();
  }
  report.selectedApiByteIdentity=fs.readFileSync(report.variants[0].api.file).equals(fs.readFileSync(report.variants[1].api.file));
  for(const input of report.inputs)assert.equal(digest(input.file),input.sha256);
  report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
report.finished=new Date().toISOString();save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,selectedApiByteIdentity:report.selectedApiByteIdentity,error:report.error}));
