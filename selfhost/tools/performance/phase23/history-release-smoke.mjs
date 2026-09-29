// Phase15 release checks retained; Phase23 pin/version and CPU1 explicitly bound.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {spawnSync} from 'node:child_process';
const [projectArg,outArg,expectedApi]=process.argv.slice(2);
if(!projectArg||!outArg||!/^([0-9a-f]{64})$/.test(expectedApi??''))throw Error('Usage: release-smoke.mjs PROJECT NEW_OUTPUT EXPECTED_API_SHA256');
const project=fs.realpathSync(projectArg),out=path.resolve(outArg),relocated=path.join(out,'relocated');
fs.mkdirSync(out);fs.copyFileSync(import.meta.filename,path.join(out,'consumed-runner.mjs'));
const actualCpu=fs.readFileSync('/proc/self/status','utf8').match(/^Cpus_allowed_list:\s*(.+)$/m)?.[1];
if(actualCpu!=='1')throw Error('Release smoke must inherit CPU1 affinity; observed '+actualCpu);
const hash=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identify=file=>({file:fs.realpathSync(file),sha256:hash(file),bytes:fs.statSync(file).size});
const releaseFile=path.join(project,'dist/release.json'),release=JSON.parse(fs.readFileSync(releaseFile,'utf8'));
const target=JSON.parse(fs.readFileSync(path.join(project,'src/compiler.json'),'utf8'));
if(target.upstream!=='018751270e800bc222a93dad7f257083ee53a5f7'||target.targetVersion!=='2.0.34')throw Error('Unexpected Phase23 compiler target');
if(release.artifact!=='equality-derived-b1'||release.files.find(x=>x.path==='dist/typed-api.mjs')?.sha256!==expectedApi)throw Error('Unexpected installed release');
fs.mkdirSync(relocated,{recursive:false});
const extras=['dist/release.json','tools/development/release.mjs','tools/development/workflow.mjs','tools/development/equality.mjs','tools/development/process.mjs','tools/conformance/inventory.mjs'];
const copied=[...new Set([...release.files,...release.checkout].map(x=>x.path).concat(extras))].sort();
for(const file of copied){if(path.isAbsolute(file)||file.split('/').includes('..'))throw Error('Invalid copy path');const target=path.join(relocated,file);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(project,file),target);}
const fixtures=[{name:'base-u32',source:path.join(project,'tests/conformance/typed-smoke/base-u32.bend'),expected:'42\n'},{name:'user-clo-apply',source:path.resolve(project,'../tests/check/name_owned_def.bend'),expected:'False{}\n'}];
fixtures.push({name:'compact-nat',source:path.join(project,'tests/phase9-literals/fixtures/nat-boundaries.bend'),expected:fs.readFileSync(path.join(project,'tests/phase9-literals/fixtures/nat-boundaries.bend'),'utf8').split('\n').filter(line=>line.startsWith('#|')).map(line=>line.slice(2)).join('\n')+'\n'});
for(const fixture of fixtures){fixture.input=identify(fixture.source);fixture.relative='smoke/'+fixture.name+'.bend';const target=path.join(relocated,fixture.relative);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(fixture.source,target);}
const env={...process.env},removedEnv=Object.keys(env).filter(key=>key.startsWith('BEND_'));for(const key of removedEnv)delete env[key];delete env.NODE_OPTIONS;delete env.NODE_PATH;
const clangRoot=path.join(project,'build/phase1/clang/root');
Object.assign(env,{CC:path.join(clangRoot,'usr/bin/clang-16'),CPATH:path.join(clangRoot,'usr/include'),LIBRARY_PATH:path.join(clangRoot,'usr/lib/x86_64-linux-gnu'),LD_LIBRARY_PATH:path.join(clangRoot,'usr/lib/x86_64-linux-gnu')});
const extraInputs=extras.filter(file=>![...release.files,...release.checkout].some(x=>x.path===file));
const report={kind:'phase23-installed-and-relocated-release-smoke',started:new Date().toISOString(),pass:false,node:{...identify(process.execPath),version:process.version},cpu:1,actualCpu,artifact:release.artifact,apiSha256:expectedApi,release:identify(releaseFile),fixtureInputs:fixtures.map(x=>({name:x.name,...x.input})),ordinaryInputs:[...new Set([...release.files,...release.checkout].map(x=>x.path).concat(extraInputs))].map(file=>({relative:file,...identify(path.join(project,file))})),relocation:{root:relocated,copiedFiles:copied.map(file=>({relative:file,...identify(path.join(relocated,file))})),extraVerificationFiles:extraInputs,noUpstreamCheckout:!fs.existsSync(path.join(relocated,'.bootstrap'))&&!fs.existsSync(path.join(relocated,'bend2')),note:'No upstream checkout is copied or supplied; historical absolute provenance paths remain data in the preserved bootstrap report. This is relocation evidence, not an OS filesystem isolation claim.'},environment:{removedBendKeys:removedEnv,remainingBendKeys:Object.keys(env).filter(key=>key.startsWith('BEND_')),removedNodeOptions:true,CC:env.CC,CPATH:env.CPATH,LIBRARY_PATH:env.LIBRARY_PATH,LD_LIBRARY_PATH:env.LD_LIBRARY_PATH},toolchain:identify(env.CC),runner:identify(import.meta.filename),steps:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
function run(name,cwd,command,args,expected){
 const index=String(report.steps.length).padStart(2,'0'),directory=path.join(out,'logs');fs.mkdirSync(directory,{recursive:true});
 const stdout=path.join(directory,index+'.stdout'),stderr=path.join(directory,index+'.stderr');const a=fs.openSync(stdout,'wx'),b=fs.openSync(stderr,'wx');let child;
 try{child=spawnSync(command,args,{cwd,env,timeout:180000,stdio:['ignore',a,b]});}finally{fs.closeSync(a);fs.closeSync(b);}
 const logBytes=fs.statSync(stdout).size+fs.statSync(stderr).size,overflow=logBytes>16*1024*1024,timedOut=child.error?.code==='ETIMEDOUT';
 const result=fs.readFileSync(stdout,'utf8');let assertion=true,error=null;
 try{if(typeof expected==='string')assertion=result===expected;else if(expected)assertion=Boolean(expected(result));}catch(caught){assertion=false;error=String(caught);}
 const row={name,cwd,command:[command,...args],exitCode:child.status,signal:child.signal,timedOut,overflow,logBytes,error:child.error?.message??error,stdout:path.relative(out,stdout),stderr:path.relative(out,stderr),outputSha256:hash(stdout),expected:typeof expected==='string'?expected:expected?'structured output predicate':null,assertion,pass:child.status===0&&child.signal===null&&!child.error&&!timedOut&&!overflow&&assertion};
 report.steps.push(row);save();console.log((row.pass?'PASS ':'FAIL ')+name);return row.pass;
}
const nodeArgs=['--stack-size=4096','--max-old-space-size=4096'];
function integrity(mode,root,when){return run(mode+' release integrity '+when,root,process.execPath,[...nodeArgs,'tools/development/release.mjs','--verify'],stdout=>{const result=JSON.parse(stdout);return result.complete===true&&result.artifact==='equality-derived-b1'&&result.newBootstrap===false&&result.api.sha256===expectedApi;});}
for(const [mode,root]of [['ordinary',project],['relocated',relocated]]){
 if(!integrity(mode,root,'before'))continue;
 run(mode+' CLI version',root,process.execPath,[...nodeArgs,'cli.mjs','--version'],stdout=>stdout.trim()==='Bend2 port targeting 2.0.34');
 for(const fixture of fixtures){
  const input=mode==='ordinary'?fixture.source:path.join(root,fixture.relative),directory=path.join(out,mode,fixture.name);fs.mkdirSync(directory,{recursive:true});
  run(mode+' '+fixture.name+' check',root,process.execPath,[...nodeArgs,'cli.mjs',input,'--check-only'],stdout=>stdout.includes('ALL PROOFS CHECK'));
  run(mode+' '+fixture.name+' interpreter',root,process.execPath,[...nodeArgs,'cli.mjs',input,'--interpret'],fixture.expected);
  const js=path.join(directory,'program.mjs');if(run(mode+' '+fixture.name+' emit JS',root,process.execPath,[...nodeArgs,'cli.mjs',input,'-o',js],''))run(mode+' '+fixture.name+' run JS',root,process.execPath,[...nodeArgs,js],fixture.expected);
  const c=path.join(directory,'program.c'),binary=path.join(directory,'program.bin');if(run(mode+' '+fixture.name+' emit and build CPU',root,process.execPath,[...nodeArgs,'cli.mjs',input,'--cpu','-o',c,'-o',binary],''))run(mode+' '+fixture.name+' run CPU',root,binary,['--threads','1'],fixture.expected);
 }
 integrity(mode,root,'after');
}
report.changedOrdinaryInputs=report.ordinaryInputs.filter(item=>hash(item.file)!==item.sha256);report.changedRelocatedInputs=report.relocation.copiedFiles.filter(item=>hash(item.file)!==item.sha256);report.changedFixtures=fixtures.filter(item=>hash(item.source)!==item.input.sha256).map(x=>x.name);
report.relocation.createdUpstreamCheckout=fs.existsSync(path.join(relocated,'.bootstrap'))||fs.existsSync(path.join(relocated,'bend2'));
const walk=directory=>fs.readdirSync(directory,{withFileTypes:true}).flatMap(entry=>entry.isDirectory()?walk(path.join(directory,entry.name)):[path.join(directory,entry.name)]);
report.outputs=['ordinary','relocated'].flatMap(mode=>fs.existsSync(path.join(out,mode))?walk(path.join(out,mode)).filter(file=>/\/program\.(mjs|c|bin)$/.test(file)).map(identify):[]);
report.finished=new Date().toISOString();report.pass=report.steps.length===42&&report.steps.every(x=>x.pass)&&!report.changedOrdinaryInputs.length&&!report.changedRelocatedInputs.length&&!report.changedFixtures.length&&!report.relocation.createdUpstreamCheckout;save();console.log(JSON.stringify({pass:report.pass,steps:report.steps.length,report:path.join(out,'report.json')}));if(!report.pass)process.exitCode=1;
