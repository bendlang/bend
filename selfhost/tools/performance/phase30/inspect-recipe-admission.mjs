#!/usr/bin/env node
// Reviewed bootstrap recipe admission and exact derivative replay controls.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {deriveEquality,transformEquality,verifyEqualityDerivation} from '../../development/equality.mjs';
const root=path.resolve(import.meta.dirname,'../../../..'),out=path.resolve(process.argv[2]);
fs.mkdirSync(out,{recursive:false});
const hash=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
const identity=file=>({file:path.resolve(file),canonicalPath:fs.realpathSync(file),sha256:hash(file)});
const priorTool=path.join(root,'selfhost/build/phase30/attempt-03/snapshot/tools/development/equality.mjs');
const prior=await import(pathToFileURL(priorTool));
const currentTool=path.join(root,'selfhost/tools/development/equality.mjs');
const inputs=[identity(import.meta.filename),identity(priorTool),identity(currentTool)];
const report={kind:'phase30-reviewed-bootstrap-recipes',complete:false,pass:false,scope:'Only exact Phase23 old/new recipe bundles; transformation version6 and previous generated-byte replay unchanged.',inputs,checks:[],cases:[]};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
const check=async(name,body)=>{try{const observation=await body();report.checks.push({name,pass:true,observation});}catch(error){report.checks.push({name,pass:false,error:error.stack});}save();};
const contexts=[];
for(const [name,attempt]of [['old','attempt-03'],['new','attempt-04']]){
  const dir=path.join(root,'selfhost/build/phase30',attempt),api=path.join(dir,'api.mjs'),bootstrap=path.join(dir,'api.mjs.bootstrap.json');
  inputs.push(identity(api),identity(bootstrap));
  const manifest=JSON.parse(fs.readFileSync(bootstrap,'utf8'));
  contexts.push({name,api,bootstrap,manifest});
  await check(name+' reviewed bundle derives and replays',async()=>{const result=await deriveEquality({api,bootstrapReport:bootstrap,outputDirectory:path.join(out,name+'-derive')});const replay=verifyEqualityDerivation(result.report);assert.equal(replay.metadata.transform.version,6);return {api:identity(api),derived:identity(result.api),report:identity(result.report)};});
  await check(name+' version6 bytes and stats match unchanged transformation',()=>{const source=fs.readFileSync(api,'utf8'),before=prior.transformEquality(source,6),after=transformEquality(source,6);assert.deepEqual(after,before);return {version:after.stats.version,outputSha256:crypto.createHash('sha256').update(after.source).digest('hex')};});
}
for(const context of contexts){
  for(const kind of ['stage0-changed','assembler-changed','stage0-missing','stage0-duplicate','stage0-wrong-role','unverified']){
    const name=context.name+'-'+kind,manifest=structuredClone(context.manifest);
    const find=name=>manifest.provenance.inputs.find(x=>x.role==='host-tool'&&path.basename(x.file)===name);
    if(kind.endsWith('-changed')){
      const filename=kind==='stage0-changed'?'stage0-library.mjs':'assemble.mjs',original=find(filename);
      const dir=path.join(out,name+'-inputs');fs.mkdirSync(dir);const file=path.join(dir,filename);fs.writeFileSync(file,fs.readFileSync(original.file,'utf8')+'\n// unreviewed mutation\n');Object.assign(original,identity(file));
    }else if(kind==='stage0-missing')manifest.provenance.inputs=manifest.provenance.inputs.filter(x=>x!==find('stage0-library.mjs'));
    else if(kind==='stage0-duplicate')manifest.provenance.inputs.push({...find('stage0-library.mjs')});
    else if(kind==='stage0-wrong-role')find('stage0-library.mjs').role='unreviewed';
    else manifest.provenance.verifiedAfterBuild=false;
    const file=path.join(out,name+'.json');fs.writeFileSync(file,JSON.stringify(manifest,null,2)+'\n');
    const target=path.join(out,name+'-derive');
    await check(name+' rejects before output',async()=>{await assert.rejects(()=>deriveEquality({api:context.api,bootstrapReport:file,outputDirectory:target}),kind==='unverified'?/Incomplete bootstrap provenance/:/bootstrap recipe/);assert.equal(fs.existsSync(path.join(target,'api.mjs')),false);return {mutation:identity(file),failure:identity(path.join(target,'api.mjs.derivation.json'))};});
  }
}
const legacyDir=path.join(root,'selfhost/build/phase22/context-build-09');
const legacyApi=path.join(legacyDir,'api.mjs'),legacyBootstrap=path.join(legacyDir,'api.mjs.bootstrap.json');
inputs.push(identity(legacyApi),identity(legacyBootstrap));
await check('historical Phase8 recipe still derives version5 and replays',async()=>{
  const result=await deriveEquality({api:legacyApi,bootstrapReport:legacyBootstrap,outputDirectory:path.join(out,'historical-derive')});
  assert.equal(result.metadata.transform.version,5);verifyEqualityDerivation(result.report);
  const source=fs.readFileSync(legacyApi,'utf8');
  for(const version of [2,3,4,5])assert.deepEqual(transformEquality(source,version),prior.transformEquality(source,version));
  return {derived:identity(result.api),replayedVersions:[2,3,4,5]};
});
await check('new stage0 recipe remains rejected under historical pin',async()=>{
  const manifest=JSON.parse(fs.readFileSync(legacyBootstrap,'utf8'));
  const oldRecipe=manifest.provenance.inputs.find(x=>x.role==='host-tool'&&path.basename(x.file)==='stage0-library.mjs');
  const newRecipe=contexts[1].manifest.provenance.inputs.find(x=>x.role==='host-tool'&&path.basename(x.file)==='stage0-library.mjs');
  Object.assign(oldRecipe,structuredClone(newRecipe));
  const file=path.join(out,'historical-new-recipe.json');fs.writeFileSync(file,JSON.stringify(manifest,null,2)+'\n');
  const target=path.join(out,'historical-new-recipe-derive');
  await assert.rejects(()=>deriveEquality({api:legacyApi,bootstrapReport:file,outputDirectory:target}),/Unreviewed bootstrap recipe bundle/);
  assert.equal(fs.existsSync(path.join(target,'api.mjs')),false);
  return {mutation:identity(file),failure:identity(path.join(target,'api.mjs.derivation.json'))};
});
await check('all consumed originals unchanged',()=>{for(const item of inputs)assert.equal(hash(item.file),item.sha256);});
report.complete=true;report.pass=report.checks.every(x=>x.pass);save();fs.copyFileSync(import.meta.filename,path.join(out,'consumed-tool.mjs'));
console.log(JSON.stringify({complete:report.complete,pass:report.pass,checks:report.checks.length,failed:report.checks.filter(x=>!x.pass).map(x=>x.name)}));
if(!report.pass)process.exitCode=1;
