// Bind each migrated compiler through its own verified frozen workflow and host.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {execFileSync} from 'node:child_process';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
import {supervise,requireExecution} from '../../development/process.mjs';
export {identity,verifyIdentity,supervise,requireExecution};
export const repo=path.resolve(import.meta.dirname,'../../../..');
export async function bindCandidate(bindingFile){
 bindingFile=fs.realpathSync(bindingFile);const config=JSON.parse(fs.readFileSync(bindingFile));
 assert.deepEqual(Object.keys(config).sort(),['baselineAttempt','candidateAttempt']);
 const dirs=[config.baselineAttempt,config.candidateAttempt].map(x=>fs.realpathSync(path.resolve(path.dirname(bindingFile),x)));
 const inputs=new Map(),add=file=>{const v=identity(file);inputs.set(v.file,v);return v;},models=[];
 for(const directory of dirs){
  const raw=JSON.parse(fs.readFileSync(path.join(directory,'attempt.json')));
  const verifier=path.join(raw.snapshot.root,'tools/development/workflow.mjs');
  const {verifyAttempt}=await import(pathToFileURL(verifier));const m=await verifyAttempt(directory);
  const validation=path.join(directory,'validation-001/report.json'),v=JSON.parse(fs.readFileSync(validation));
  assert.equal(v.complete,true);assert.equal(v.pass,true);assert.equal(v.api.sha256,m.api.sha256);
  assert.equal(execFileSync('git',['-C',m.config.upstream,'rev-parse','HEAD'],{encoding:'utf8'}).trim(),'018751270e800bc222a93dad7f257083ee53a5f7');
  assert.equal(m.artifactKind,'derived-b1');models.push(m);
  for(const f of [verifier,validation,path.join(directory,'attempt.json')])add(f);
  for(const row of [m.api,m.checkedApi,m.base,m.runtime,m.node,m.bootstrapReport,m.derivationReport,...m.artifacts,...m.snapshot.sources.map(x=>x.frozen)]){verifyIdentity(row);add(row.file);}
 }
 const [parent,candidate]=models;assert.equal(parent.base.sha256,candidate.base.sha256);assert.equal(parent.config.upstream,candidate.config.upstream);
 const files=m=>new Map(m.snapshot.sources.map(({frozen})=>[path.relative(m.snapshot.root,frozen.file),frozen]));
 const old=files(parent),current=files(candidate),names=[...new Set([...old.keys(),...current.keys()])].sort();
 const changes=names.filter(n=>old.get(n)?.sha256!==current.get(n)?.sha256).map(relative=>({relative,before:old.get(relative)??null,after:current.get(relative)??null}));
 const hostChecks={mode:'Each checked API uses its own frozen snapshot, runtime and independently validated Base cache',snapshotChanges:changes,runtimes:{baseline:parent.runtime,candidate:candidate.runtime},base:parent.base,upstream:parent.config.upstream,upstreamRevision:'018751270e800bc222a93dad7f257083ee53a5f7',allowedPairedResultDifference:'Only hostProvenance is separately checked against its bound driver and adapter. Every remaining result field must agree exactly; there is no diagnostic exception.'};
 for(const f of [import.meta.filename,process.execPath,bindingFile,path.resolve(import.meta.dirname,'../../development/workflow.mjs'),path.resolve(import.meta.dirname,'../../development/process.mjs')])add(f);assert.equal(process.version,'v24.18.0');
 const replay=()=>{for(const row of inputs.values())verifyIdentity(row);};replay();
 return {parent,candidate,manifest:add(bindingFile),inputs,add,replay,hostChecks};
}
export async function prepareVariant(binding,name,directory,cpu){
 const {parent,candidate,add}=binding;assert.ok(['baseline','candidate'].includes(name));
 const source=name==='baseline'?parent:candidate;fs.mkdirSync(directory);
 const project=path.join(directory,'project');fs.mkdirSync(project);
 for(const sub of ['src','tools','tests'])fs.cpSync(path.join(source.snapshot.root,sub),path.join(project,sub),{recursive:true});
 for(const {frozen}of source.snapshot.sources){const target=path.join(project,path.relative(source.snapshot.root,frozen.file));assert.equal(identity(target).sha256,frozen.sha256);add(target);}
 const cacheDir=path.join(project,'build/typed/cache');fs.mkdirSync(cacheDir,{recursive:true});
 const environment=Object.fromEntries(Object.entries(process.env).filter(([k])=>!k.startsWith('BEND_')&&!['NODE_OPTIONS','NODE_PATH'].includes(k)));
 Object.assign(environment,{BEND_TYPED_API:source.api.file,BEND_TYPED_RUNTIME:source.runtime.file,BEND_BASE:source.base.file,BEND_UPSTREAM:source.config.upstream,BEND_TYPED_TRACE:'1'});
 const driver=path.join(project,'tools/typed-driver.mjs');
 const preparation=await supervise('taskset',['-c',String(cpu),process.execPath,'--stack-size=4096','--max-old-space-size=4096',driver,'--prepare-base'],{directory:path.join(directory,'prepare-base'),env:environment,timeoutMs:180000});
 fs.writeFileSync(path.join(directory,'prepare-base.json'),JSON.stringify(preparation,null,2)+'\n');requireExecution(preparation);
 const {validatedCache}=await import(pathToFileURL(path.join(source.snapshot.root,'tools/development/workflow.mjs')));
 const cache=validatedCache(cacheDir,source.api.file,source.base.file);add(cache.file);
 const adapter=path.join(project,'tools/conformance/adapters/typed.mjs');add(adapter);
 return {name,directory,project,adapter,api:source.api,runtime:source.runtime,base:source.base,upstream:source.config.upstream,cache,preparation,environment,hostProvenance:{driverSha256:identity(driver).sha256,adapterSha256:identity(adapter).sha256}};
}
