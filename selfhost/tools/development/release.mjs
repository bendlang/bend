#!/usr/bin/env node
// Releases preserve original checked provenance; installation creates no bootstrap.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt,runDevelopment,identity,digest} from './workflow.mjs';
import {verifyEqualityDerivation,transformEquality} from './equality.mjs';

const project=path.resolve(import.meta.dirname,'../..');
const dist=path.join(project,'dist');
const read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
const relative=file=>path.relative(project,file).split(path.sep).join('/');
function local(name,root=project){
 assert.ok(typeof name==='string'&&!path.isAbsolute(name)&&!name.split('/').includes('..'),'Invalid release-relative path');
 return path.join(root,name);
}
const record=file=>({path:relative(file),sha256:identity(file).sha256,bytes:fs.statSync(file).size});
function check(item,root=project){const file=local(item.path,root);assert.equal(identity(file).sha256,item.sha256,'Changed release input: '+item.path);assert.equal(fs.statSync(file).size,item.bytes);return file;}
const hostNames=['typed-driver','compiler-abi','native-build','node-resource-args','assemble'];

export function verifyRelease(root=project){
 const dist=path.join(root,'dist');
 const manifest=read(path.join(dist,'release.json'));
 const checked=manifest.kind==='bend-default-checked-release';
 assert.ok(checked||manifest.kind==='bend-default-equality-release','Unsupported release kind');assert.equal(manifest.version,1);assert.equal(manifest.newBootstrap,false);
 assert.equal(manifest.artifact,checked?'checked-b1':'equality-derived-b1');
 assert.equal(fs.existsSync(path.join(dist,'typed-api.mjs.bootstrap.json')),false,'Installed provenance belongs in release-lineage');
 assert.equal(fs.existsSync(path.join(dist,'typed-bootstrap-report.json')),false,'Stale default bootstrap report');
 for(const items of [manifest.files,manifest.checkout]){assert.equal(new Set(items.map(x=>x.path)).size,items.length,'Duplicate release paths');for(const item of items)check(item,root);}
 const files=Object.fromEntries(manifest.files.map(x=>[x.path,x]));
 const api=files['dist/typed-api.mjs'],parent=files['dist/release-lineage/checked-api.mjs'];assert.ok(api&&parent);
 const bootstrap=read(path.join(dist,'release-lineage/checked-bootstrap.json'));
 assert.equal(bootstrap.stage,'upstream-bootstrap');assert.equal(bootstrap.provenance.verifiedAfterBuild,true);assert.equal(bootstrap.apiSha256,parent.sha256);
 assert.equal(bootstrap.sourceSha256,manifest.sourceSha256);assert.equal(bootstrap.baseSha256,files['dist/base.bend'].sha256);
 assert.equal(bootstrap.revision,manifest.lineage.upstreamRevision);
 assert.equal(manifest.checkout.find(x=>x.path==='src/runtime.mjs')?.sha256,manifest.runtimeSha256);
 if(checked){
  assert.equal(api.sha256,parent.sha256,'Checked default differs from checked API');
  assert.equal(manifest.lineage.checkedApiSha256,parent.sha256);
  assert.equal(manifest.lineage.bootstrapSha256,files['dist/release-lineage/checked-bootstrap.json'].sha256);
  assert.equal(bootstrap.provenance.upstream.revision,bootstrap.revision);
  assert.equal(bootstrap.provenance.upstream.trackedSourcesClean,true);
  const checkout=Object.fromEntries(manifest.checkout.map(x=>[x.path,x]));
  const sourceManifest=read(local('src/compiler.json',root));
  assert.equal(sourceManifest.upstream,bootstrap.revision,'Compiler target differs from checked upstream');
  assert.deepEqual(sourceManifest.modules,bootstrap.modules.map(x=>x.file),'Compiler module membership differs');
  const inputs=bootstrap.provenance.inputs;
  assert.ok(inputs.some(x=>x.role==='assembled-source'&&x.sha256===bootstrap.sourceSha256),'Missing checked source identity');
  for(const module of bootstrap.modules){
   assert.equal(checkout[module.file]?.sha256,module.sha256,'Module differs from checked source: '+module.file);
   assert.ok(inputs.some(x=>x.role==='compiler-module'&&x.file.endsWith('/'+module.file)&&x.sha256===module.sha256),'Missing checked module identity: '+module.file);
  }
  assert.ok(inputs.some(x=>x.role==='compiler-manifest'&&x.sha256===checkout['src/compiler.json']?.sha256),'Missing compiler manifest identity');
  for(const name of [...hostNames,'stage0-library'])assert.ok(inputs.some(x=>x.role==='host-tool'&&path.basename(x.file)===name+'.mjs'&&x.sha256===checkout['tools/'+name+'.mjs']?.sha256),'Host differs from checked recipe: '+name);
  for(const name of ['derivation.json','equality.mjs'])assert.equal(fs.existsSync(path.join(dist,'release-lineage',name)),false,'Stale equality lineage in checked release');
  return manifest;
 }
 const derivation=read(path.join(dist,'release-lineage/derivation.json'));
 assert.equal(derivation.kind,'bend-derived-b1-equality');assert.equal(derivation.complete,true);assert.equal(derivation.newBootstrap,false);
 assert.equal(derivation.original.api.sha256,parent.sha256);assert.equal(derivation.output.sha256,api.sha256);
 assert.equal(derivation.original.bootstrapReport.sha256,files['dist/release-lineage/checked-bootstrap.json'].sha256);
 assert.equal(derivation.toolSnapshot.sha256,files['dist/release-lineage/equality.mjs'].sha256);
 const replay=transformEquality(fs.readFileSync(check(parent,root),'utf8'),derivation.transform.version);
 assert.equal(digest(replay.source),api.sha256);assert.deepEqual(replay.stats,derivation.transform);
 return manifest;
}

export async function installAttempt(directory,derivationFile){
 directory=fs.realpathSync(directory);
 const attempt=await verifyAttempt(directory);
 const derivation=derivationFile??attempt.derivationReport?.file;
 const derived=derivation?verifyEqualityDerivation(derivation):null;
 if(derived){
  assert.equal(derived.metadata.original.api.sha256,attempt.checkedApi.sha256);
  assert.equal(derived.metadata.original.bootstrapReport.sha256,attempt.bootstrapReport.sha256);
 }else assert.equal(attempt.artifactKind,'checked-b1','Checked release requires a genuine checked attempt');
 const bootstrap=read(attempt.bootstrapReport.file),checkout=[];
 // Prove the default source/host actually corresponds to this frozen attempt.
 for(const module of bootstrap.modules){
  const file=path.join(project,'src',module.file.replace(/^src\//,''));
  assert.equal(identity(file).sha256,module.sha256,'Current source differs: '+module.file);checkout.push(record(file));
 }
 for(const name of [...hostNames,...(derived?[]:['stage0-library'])]){const file=path.join(project,'tools',name+'.mjs');assert.equal(identity(file).sha256,identity(path.join(attempt.snapshot.root,'tools',name+'.mjs')).sha256);checkout.push(record(file));}
 for(const name of ['src/compiler.json','src/runtime.mjs']){const file=path.join(project,name);assert.equal(identity(file).sha256,identity(path.join(attempt.snapshot.root,name)).sha256);checkout.push(record(file));}
 const walk=directory=>fs.readdirSync(directory,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(path.join(directory,e.name)):[path.join(directory,e.name)]);
 for(const file of walk(path.join(project,'src/runtime/native'))){assert.equal(identity(file).sha256,identity(path.join(attempt.snapshot.root,relative(file))).sha256);checkout.push(record(file));}
 checkout.push(record(path.join(project,'cli.mjs')));
 const stage=fs.mkdtempSync(path.join(dist,'.release-'));
 try {
  const lineage=path.join(stage,'release-lineage');fs.mkdirSync(lineage);
  const copies=[[derived?.api??attempt.checkedApi.file,'typed-api.mjs'],[attempt.base.file,'base.bend'],[attempt.checkedApi.file,'release-lineage/checked-api.mjs'],[attempt.bootstrapReport.file,'release-lineage/checked-bootstrap.json'],...(derived?[[derived.report,'release-lineage/derivation.json'],[derived.metadata.toolSnapshot.file,'release-lineage/equality.mjs']]:[])];
  for(const [source,target] of copies)fs.copyFileSync(source,path.join(stage,target));
  await verifyAttempt(directory);if(derived)verifyEqualityDerivation(derived.report);
  // Preserve the previous default's Base and lineage as well as its API.
  const previous=[];
  const priorManifest=path.join(dist,'release.json');
  const priorFiles=fs.existsSync(priorManifest)?read(priorManifest).files.map(item=>{const file=local(item.path);assert.ok(file.startsWith(dist+path.sep),'Previous release artifact is outside dist');return path.relative(dist,file);}):[];
  for(const name of new Set(['typed-api.mjs','typed-api.mjs.bootstrap.json','typed-bootstrap-report.json',...(fs.existsSync(priorManifest)?['release.json',...priorFiles]:[])]))if(fs.existsSync(path.join(dist,name)))previous.push({name,...identity(path.join(dist,name))});
  if(previous.length&&previous[0].sha256!==(derived?.metadata.output.sha256??attempt.checkedApi.sha256)){const history=path.join(dist,'release-history',previous[0].sha256);fs.mkdirSync(history,{recursive:true});for(const item of previous){const target=path.join(history,item.name);fs.mkdirSync(path.dirname(target),{recursive:true});if(fs.existsSync(target))assert.equal(identity(target).sha256,item.sha256);else fs.copyFileSync(item.file,target);}}
  fs.mkdirSync(path.join(dist,'release-lineage'),{recursive:true});
  const names=copies.map(([,name])=>name);
  for(const name of names)fs.renameSync(path.join(stage,name),path.join(dist,name));
  for(const name of ['typed-api.mjs.bootstrap.json','typed-bootstrap-report.json',...(derived?[]:['release-lineage/derivation.json','release-lineage/equality.mjs'])])fs.rmSync(path.join(dist,name),{force:true});
  const manifest={kind:derived?'bend-default-equality-release':'bend-default-checked-release',version:1,newBootstrap:false,installed:new Date().toISOString(),
   artifact:derived?'equality-derived-b1':'checked-b1',sourceSha256:bootstrap.sourceSha256,runtimeSha256:attempt.runtime.sha256,
   files:names.map(name=>record(path.join(dist,name))),checkout,
   lineage:{...(derived?{checkedParentSha256:attempt.checkedApi.sha256,derivationSha256:identity(derived.report).sha256}:{checkedApiSha256:attempt.checkedApi.sha256,bootstrapSha256:attempt.bootstrapReport.sha256}),upstreamRevision:bootstrap.revision},
   provenanceScope:derived?'Original checked bootstrap and derivation reports are preserved byte-for-byte with historical paths. Local verification checks relative installed/checkout identities and exact transformation replay; it does not create or relocate bootstrap provenance.':'The installed API is byte-identical to the genuine checked attempt. Its original bootstrap report is retained byte-for-byte with historical paths; relocated verification binds local source, recipe, Base and runtime identities without creating new bootstrap provenance.',
   validationScope:'Installation verifies the completed checked attempt and any explicit derivation. Release build additionally requires maintained focused validation; broad conformance and self-reproduction are separate evidence.'};
  fs.writeFileSync(path.join(stage,'release.json'),JSON.stringify(manifest,null,2)+'\n');fs.renameSync(path.join(stage,'release.json'),path.join(dist,'release.json'));
  return verifyRelease();
 }finally{fs.rmSync(stage,{recursive:true,force:true});}
}

export async function buildRelease(configFile,output){
 output=path.resolve(output??path.join(project,'build/releases',new Date().toISOString().replace(/[:.]/g,'-')));
 fs.mkdirSync(path.dirname(output),{recursive:true});
 const config=configFile?read(fs.realpathSync(configFile)):{};
 // Resolve user configuration before writing the durable effective configuration.
 for(const name of ['project','upstream','selection'])if(config[name])config[name]=path.resolve(path.dirname(path.resolve(configFile)),config[name]);
 config.project=project;config.profile??='equality';
 const effective=output+'.release-config.json';fs.writeFileSync(effective,JSON.stringify(config,null,2)+'\n',{flag:'wx'});
 const result=await runDevelopment(effective,output);
 assert.equal(result.build?.complete,true,'Checked release build failed');assert.equal(result.validation?.complete,true,'Focused release validation incomplete');assert.equal(result.validation?.pass,true,'Focused release validation failed');
 return installAttempt(output);
}

if(process.argv[1]&&import.meta.url===pathToFileURL(path.resolve(process.argv[1])).href){
 try{
  const [mode,...args]=process.argv.slice(2);let result;
  if(mode==='--verify'&&!args.length)result=verifyRelease();
  else if(mode==='--install-attempt'&&(args.length===1||args.length===2))result=await installAttempt(...args);
  else if(mode==='--build'&&(args.length===0||args.length===2))result=await buildRelease(...args);
  else throw Error('Usage: release.mjs --build [CONFIG NEW_ATTEMPT] | --install-attempt ATTEMPT [DERIVATION] | --verify');
  console.log(JSON.stringify({complete:true,artifact:result.artifact,api:result.files.find(x=>x.path==='dist/typed-api.mjs'),sourceSha256:result.sourceSha256,newBootstrap:false}));
 }catch(error){console.error(error.stack??error);process.exitCode=1;}
}
