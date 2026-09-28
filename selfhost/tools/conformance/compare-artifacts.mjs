#!/usr/bin/env node
// Compare observed behavior, not compiler speed or diagnostic-rule soundness.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {semanticSummary} from './semantic-summary.mjs';

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
export function compareReports(before,after,{strictPaths=false}={}) {
  if(before.inventory.revision!==after.inventory.revision)throw Error('Different upstream pins');
  const a=unique(before.inventory.tests,t=>t.id,'fixture'),b=unique(after.inventory.tests,t=>t.id,'fixture');
  if(a.size!==b.size||[...a].some(([id,t])=>b.get(id)?.sha256!==t.sha256))throw Error('Different fixture inventory');
  if(strictPaths){
    if(before.options.upstream!==after.options.upstream)throw Error('Different upstream paths in strict comparison');
    if(targetManifest(before)!==targetManifest(after))throw Error('Different target manifests in strict comparison');
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
    method:'Compare verdict, evidence, phase, checked/type-acceptance/trust/kernel metadata, exit, diagnostic and output. '+(strictPaths?'All paths and fixture oracles are exact; target manifest identities must match.':'Only the exact upstream checkout prefix is normalized; this is the historical path policy.')+' Compiler timing and artifact identity are not program observations.',
    pathComparison:strictPaths?'exact':'upstream-prefix-normalized',
    sameObservedBehavior:changes.length===0&&missing.length===0,changes,missing,
    beforeSummary:semanticSummary(before.results,before.inventory.tests),afterSummary:semanticSummary(after.results,after.inventory.tests),negativeChecks:negative,
    limitation:'Unchanged observations preserve existing diagnostic differences and unproven intended-rule coverage. This does not prove checker equivalence or validate GPU hardware gates.'
  };
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const args=process.argv.slice(2),strictPaths=args.includes('--strict-paths'),positional=args.filter(a=>a!=='--strict-paths');
  if(positional.length!==3||positional.some(a=>a.startsWith('--')))throw Error('Usage: compare-artifacts.mjs [--strict-paths] BEFORE.json AFTER.json OUTPUT.json');
  const [beforeFile,afterFile,outputFile]=positional;
  const read=file=>JSON.parse(fs.readFileSync(file,'utf8')),before=read(beforeFile),after=read(afterFile);
  const sha=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  const report={before:{file:beforeFile,sha256:sha(beforeFile),identity:before.identity},after:{file:afterFile,sha256:sha(afterFile),identity:after.identity},...compareReports(before,after,{strictPaths})};
  fs.writeFileSync(outputFile,JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify({changed:report.changes.length,missing:report.missing.length,negativeChecks:report.negativeChecks.length}));
}
