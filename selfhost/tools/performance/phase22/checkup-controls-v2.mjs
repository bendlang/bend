// Actual CLI checkup behavior, including import order and failure continuation.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {identity, verifyIdentity, verifyAttempt} from '../../development/workflow.mjs';
import {supervise, requireExecution} from '../../development/process.mjs';

const [attemptArg, outArg, fixtureRootArg] = process.argv.slice(2);
assert.ok(fixtureRootArg, "Reuse the original frozen fixture root");
const m = await verifyAttempt(attemptArg), out = path.resolve(outArg);
fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
const report = {kind:'phase22-actual-checkup-controls', complete:false, pass:false,
  api:m.api, started:new Date().toISOString(), inputs:[identity(import.meta.filename), identity(path.join(attemptArg,'attempt.json'))], rows:[],
  scope:'Candidate public CLI versus unchanged pinned cli_checkup function, exposed by import relocation and one export only; no Bun entry, updater, network or publishing route executes.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
const add=file=>{const x=identity(file);report.inputs.push(x);return x;};
const write=(name,text)=>{const file=path.join(name.startsWith('fixtures/')?path.resolve(fixtureRootArg):out,name);if(name.startsWith('fixtures/'))assert.equal(fs.readFileSync(file,'utf8'),text);else fs.writeFileSync(file,text,{flag:'wx'});add(file);return file;};
save();
try {
  const input=path.join(out,'fixtures');fs.mkdirSync(input);
  write('fixtures/first.bend','import Base\n\ndef main() -> U32:\n  42\n');
  write('fixtures/second.bend','import Base\n\ndef main() -> U32:\n  7\n');
  write('fixtures/bad.bend','import Base\n\ndef main() -> U32:\n  )\n');
  const cases=[
    ['invalid-parent','import Base\nimport ./first.bend as First\n\n) invalid parent body\nimport ./second.bend as Second\n'],
    ['line-policy','  import ./second.bend as Second  \nimport ./first.bend as First # ignored by checkup\nimport ./first.bend as First\nimport ./second.bend as Again\n'],
    ['failure-continues','import ./bad.bend as Bad\nimport ./second.bend as Second\n'],
    ['missing-continues','import ./absent.bend as Absent\nimport ./second.bend as Second\n'],
  ].map(([id,source])=>({id,input:write('fixtures/'+id+'.bend',source)}));
  const pinned=path.join(m.config.upstream,'bend2/main.ts'), original=fs.readFileSync(pinned,'utf8');add(pinned);
  let exposed=original;
  for(const name of ['bend','comp','safe']) {
    const module=path.join(m.config.upstream,'bend2',name+'.ts');add(module);
    exposed=exposed.replace('"./'+name+'.ts"',JSON.stringify(pathToFileURL(module).href));
  }
  write('reference-main.ts',exposed+'\nexport { cli_checkup };\n');
  write('reference-run.mjs',"import {cli_checkup} from './reference-main.ts';\nawait cli_checkup(process.argv[2]);\n");
  const bundle=path.join(out,'candidate');fs.mkdirSync(bundle);
  for(const item of m.snapshot.sources) {
    verifyIdentity(item.frozen);const relative=path.relative(m.snapshot.root,item.frozen.file),to=path.join(bundle,relative);
    fs.mkdirSync(path.dirname(to),{recursive:true});fs.copyFileSync(item.frozen.file,to);add(to);
  }
  const project=path.resolve(import.meta.dirname,'../../..');
  const cli=path.join(project,'cli.mjs');add(cli);fs.copyFileSync(cli,path.join(bundle,'cli.mjs'));add(path.join(bundle,'cli.mjs'));
  const env={...process.env};for(const key of Object.keys(env))if(key.startsWith('BEND_')||['NODE_OPTIONS','NODE_PATH'].includes(key))delete env[key];
  Object.assign(env,{BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file,BEND_UPSTREAM:m.config.upstream});
  report.environment=Object.fromEntries(Object.entries(env).filter(([k])=>k.startsWith('BEND_')));
  report.plan={cases,referenceTransform:'Exactly three relative TS import specifiers replaced by pinned absolute URLs; append export cli_checkup. All function bodies unchanged.',outputs:'Compare process exit, stdout and stderr bytes; retain mismatches. No output normalization.'};save();
  for(const test of cases) {
    const row={id:test.id,variants:{}};report.rows.push(row);
    for(const variant of ['reference','candidate']) {
      const script=variant==='reference'?path.join(out,'reference-run.mjs'):path.join(bundle,'cli.mjs');
      const args=['--experimental-transform-types','--disable-warning=ExperimentalWarning','--stack-size=4096','--max-old-space-size=4096',script,test.input,...(variant==='candidate'?['--checkup']:[])];
      const execution=await supervise(process.execPath,args,{directory:path.join(out,test.id+'-'+variant),env,timeoutMs:120000});
      requireExecution(execution,[0,1]);
      row.variants[variant]={execution,stdout:fs.readFileSync(execution.stdout,'utf8'),stderr:fs.readFileSync(execution.stderr,'utf8')};save();
    }
    const a=row.variants.reference,b=row.variants.candidate;
    assert.ok(a.stdout.startsWith("--- "), "Reference checkup must execute the frozen import loop");
    row.exact=a.execution.exitCode===b.execution.exitCode&&a.stdout===b.stdout&&a.stderr===b.stderr;save();
  }
  report.inputs.forEach(verifyIdentity);await verifyAttempt(attemptArg);
  report.complete=true;report.pass=report.rows.length===4&&report.rows.every(r=>r.exact);
  if(!report.pass)process.exitCode=1;
} catch(error) {report.error=String(error.stack??error);process.exitCode=1;}
report.finished=new Date().toISOString();save();
console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.map(r=>({id:r.id,exact:r.exact})),error:report.error}));
