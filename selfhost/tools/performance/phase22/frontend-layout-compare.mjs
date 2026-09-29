#!/usr/bin/env node
// Compare observed behavior, not compiler speed or diagnostic-rule soundness.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {semanticSummary} from '../../conformance/semantic-summary.mjs';

const key=r=>r.id+'\0'+r.lane;
function unique(rows,makeKey,label) {
  const map=new Map();
  for(const row of rows){const k=makeKey(row);if(map.has(k))throw Error('Duplicate '+label+': '+k);map.set(k,row);}
  return map;
}
function targetManifest(report) {
  const name=report.identity?.artifacts?.['harness/compilerManifest']?'harness/compilerManifest':'compilerManifest';
  const artifact=report.identity?.artifacts?.[name];
  if(!artifact?.sha256||report.identity.finalArtifactHashes?.[name]!==artifact.sha256)throw Error('Missing or changed target manifest identity');
  return artifact.sha256;
}
function layoutAudit(before,after,migration) {
  if(!migration||migration.kind!=='explicit-compiler-module-layout-migration')throw Error('Explicit module-layout descriptor required');
  if(before.schemaVersion!==after.schemaVersion)throw Error('Different report schemas');
  const readManifest=(report,expected)=>{
    const digest=targetManifest(report), records=Object.entries(report.identity.artifacts).filter(([name])=>name==='compilerManifest'||name==='harness/compilerManifest');
    if(!expected||digest!==expected.sha256)throw Error('Unapproved target manifest identity');
    const files=records.map(([name,row])=>{
      const bytes=fs.readFileSync(row.file),actual=crypto.createHash('sha256').update(bytes).digest('hex');
      if(row.sha256!==digest||report.identity.finalArtifactHashes?.[name]!==digest||actual!==digest)throw Error('Missing or changed target manifest bytes');
      return {file:row.file,sha256:actual,manifest:JSON.parse(bytes)};
    });
    const manifest=files[0].manifest;
    if(JSON.stringify(manifest.modules)!==JSON.stringify(expected.modules))throw Error('Unapproved module layout');
    const rest=Object.fromEntries(Object.entries(manifest).filter(([key])=>key!=='modules'));
    if(JSON.stringify(rest)!==JSON.stringify(migration.expectedNonModules))throw Error('Different non-module manifest fields');
    return {files,modules:manifest.modules,nonModules:rest};
  };
  const a=readManifest(before,migration.before),b=readManifest(after,migration.after);
  return {policy:'Explicit exact module-layout migration; all non-module target fields and all strict paths/oracles remain identical.',before:a,after:b,
    removed:a.modules.filter(x=>!b.modules.includes(x)),added:b.modules.filter(x=>!a.modules.includes(x)),orderedBefore:a.modules,orderedAfter:b.modules};
}
export function compareReports(before,after,{strictPaths=false,moduleLayoutMigration=null}={}) {
  if(moduleLayoutMigration&&!strictPaths)throw Error('Module-layout migration requires strict paths');
  const moduleLayout=moduleLayoutMigration?layoutAudit(before,after,moduleLayoutMigration):null;
  if(before.inventory.revision!==after.inventory.revision)throw Error('Different upstream pins');
  const a=unique(before.inventory.tests,t=>t.id,'fixture'),b=unique(after.inventory.tests,t=>t.id,'fixture');
  if(a.size!==b.size||[...a].some(([id,t])=>b.get(id)?.sha256!==t.sha256))throw Error('Different fixture inventory');
  if(strictPaths){
    if(before.options.upstream!==after.options.upstream)throw Error('Different upstream paths in strict comparison');
    if(!moduleLayout&&targetManifest(before)!==targetManifest(after))throw Error('Different target manifests in strict comparison');
    const oracle=t=>({file:t.file,expected:t.expected,negative:t.negative,failureKind:t.failureKind??null,main:t.main});
    if([...a].some(([id,t])=>JSON.stringify(oracle(t))!==JSON.stringify(oracle(b.get(id)))))throw Error('Different fixture paths or oracles in strict comparison');
    for(const report of [before,after]){
      if(!report.finished||report.changedInputs?.length!==0||report.identity.adapterChangedDuringRun!==false||report.identity.changedArtifacts?.length!==0||report.workers?.some(w=>w.errors?.length))throw Error('Incomplete or changed report identities');
    }
  }
  const prior=unique(before.results,key,'probe');unique(after.results,key,'probe');
  const normalize=(value,report)=>typeof value==='string'&&!strictPaths?value.split(report.options.upstream).join('$UPSTREAM'):value??null;
  const observed=(r,report)=>({verdict:r.status,evidence:r.evidence??null,
    status:r.result?.status??null,phase:r.result?.phase??null,checked:r.result?.checked??null,
    typeAccepted:r.result?.typeAccepted??null,proofTrust:r.result?.proofTrust??null,kernelChecked:r.result?.kernelChecked??null,
    unsafeDefinitions:r.result?.unsafeDefinitions??null,exitCode:r.result?.exitCode??null,
    diagnostic:normalize(r.result?.diagnostic,report),output:normalize(r.result?.output??r.result?.stdout,report)});
  const changes=[],missing=[],negative=[];
  for(const r of after.results){
    const p=prior.get(key(r));if(!p){missing.push({side:'before',id:r.id,lane:r.lane});continue;}
    prior.delete(key(r));const x=observed(p,before),y=observed(r,after),same=JSON.stringify(x)===JSON.stringify(y);
    if(!same)changes.push({id:r.id,lane:r.lane,negative:r.negative,before:x,after:y});
    if(r.negative&&r.lane==='check')negative.push({id:r.id,sameObservedBehavior:same,before:x,after:y});
  }
  for(const r of prior.values())missing.push({side:'after',id:r.id,lane:r.lane});
  return {
    ...(moduleLayout?{moduleLayout}:{}),
    method:'Compare verdict, evidence, phase, checked/type-acceptance/trust/kernel metadata, exit, diagnostic and output. '+(strictPaths?'All paths and fixture oracles are exact; target manifest identities must match or satisfy the separately recorded explicit module-layout audit.':'Only the exact upstream checkout prefix is normalized; this is the historical path policy.')+' Compiler timing and artifact identity are not program observations.',
    pathComparison:strictPaths?'exact':'upstream-prefix-normalized',
    sameObservedBehavior:changes.length===0&&missing.length===0,changes,missing,
    beforeSummary:semanticSummary(before.results,before.inventory.tests),afterSummary:semanticSummary(after.results,after.inventory.tests),negativeChecks:negative,
    limitation:'Unchanged observations preserve existing diagnostic differences and unproven intended-rule coverage. This does not prove checker equivalence or validate GPU hardware gates.'
  };
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const args=process.argv.slice(2),strictPaths=args.includes('--strict-paths'),at=args.indexOf('--module-layout');
  const layoutFile=at<0?null:args[at+1];if(at>=0){if(!layoutFile)throw Error('Missing module-layout descriptor');args.splice(at,2);}
  const positional=args.filter(a=>a!=='--strict-paths');
  if(positional.length!==3||positional.some(a=>a.startsWith('--')))throw Error('Usage: frontend-layout-compare.mjs --strict-paths [--module-layout DESCRIPTOR.json] BEFORE.json AFTER.json OUTPUT.json');
  const [beforeFile,afterFile,outputFile]=positional,read=file=>JSON.parse(fs.readFileSync(file,'utf8'));
  const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  const report={before:{file:beforeFile,sha256:sha(beforeFile)},after:{file:afterFile,sha256:sha(afterFile)},
    ...(layoutFile?{descriptor:{file:layoutFile,sha256:sha(layoutFile)}}:{}),
    ...compareReports(read(beforeFile),read(afterFile),{strictPaths,moduleLayoutMigration:layoutFile?read(layoutFile):null})};
  fs.writeFileSync(outputFile,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({changed:report.changes.length,missing:report.missing.length}));
}
