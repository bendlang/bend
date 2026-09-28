import path from 'node:path';
import fs from 'node:fs';
import crypto from 'node:crypto';
import {inspect,execute,createPersistentInspector,apiPath,basePath,project,runtimePath,driverPath,compilerAbiPath,nodeResourceArgsPath} from '../../typed-driver.mjs';
// Resolve environment paths before isolated workers change their directory.
process.env.BEND_TYPED_API=apiPath;
process.env.BEND_TYPED_RUNTIME=runtimePath;
process.env.BEND_BASE=basePath;
process.env.BEND_TYPED_TRACE??='1';
export const name='typed-bend';
export const artifacts={compilerManifest:path.join(project,'src/compiler.json'),compiler:apiPath,base:basePath,runtime:runtimePath,driver:driverPath,compilerAbi:compilerAbiPath,nodeResources:nodeResourceArgsPath,
  nativeBuild:path.join(path.dirname(driverPath),'native-build.mjs'),assemble:path.join(path.dirname(driverPath),'assemble.mjs'),nativeRuntime:path.join(project,'src/runtime/native/runtime.c')};
const nativeEffects=path.join(project,'src/runtime/native/effs');
for(const file of fs.readdirSync(nativeEffects))if(fs.statSync(path.join(nativeEffects,file)).isFile())artifacts['nativeEffect/'+file]=path.join(nativeEffects,file);
const driverDigest=crypto.createHash('sha256').update(fs.readFileSync(driverPath)).digest('hex');
const adapterDigest=crypto.createHash('sha256').update(fs.readFileSync(new URL(import.meta.url))).digest('hex');
const digest=crypto.createHash('sha256').update(fs.readFileSync(apiPath)).digest('hex');
const livePath=path.join(project,'build/typed',`live-${digest.slice(0,12)}.jsonl`);
export const capabilities={parse:true,check:true,interpreter:true,js:true,native:true,metal:true,cuda:true,
  modules:true,foreign:true,dependentTypes:true,affine:true,termination:true,proofs:true,proofKernel:false,checkOracle:'validation-plus-declaration-verdict'};
// A persistent session owns the loaded API and one immutable decoded Base cache.
// Every request verifies the complete cache bytes, discovers sources, constructs
// a fresh graph, validates its prefix and gets its own work directory.
// Execution lanes remain isolated because they spawn a separate program.
export const persistentLanes=['parse','check'];
async function probeWithApi({test,lane,workdir,timeoutMs},inspector) {
  if(!capabilities[lane]) return {status:'unsupported',reason:'Typed driver does not implement '+lane};
  const result=['js','native','metal','cuda'].includes(lane)?await execute(test.file,{workdir,timeoutMs:Math.max(100,timeoutMs-250),backend:lane,combinedOutput:true}):
    await (inspector?inspector.inspect:inspect)(test.file,{mode:lane==='parse'?'parse':lane==='interpreter'?'interpreter':'check',timeoutMs:Math.max(100,timeoutMs-250),combinedOutput:true});
  result.hostProvenance={driverSha256:driverDigest,adapterSha256:adapterDigest};
  fs.mkdirSync(path.dirname(livePath),{recursive:true});
  fs.appendFileSync(livePath,JSON.stringify({id:test.id,lane,negative:test.negative,expected:test.expected,compilerSha256:digest,run:path.dirname(workdir),result})+'\n');
  return result;
}
export async function probe(request) { return probeWithApi(request,null); }
export async function createPersistentSession() {
  const inspector=await createPersistentInspector();
  return {probe:request=>probeWithApi(request,inspector)};
}
