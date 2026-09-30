// Independent retained-row comparison under the existing explicit layout policy.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';
import {compareReports} from '../phase22/frontend-layout-compare.mjs';
const [beforeArg,afterArg,layoutArg,outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const before=JSON.parse(fs.readFileSync(beforeArg)),after=JSON.parse(fs.readFileSync(afterArg)),layout=JSON.parse(fs.readFileSync(layoutArg));
const report={kind:'phase30-independent-frontend-layout-review',complete:false,pass:false,inputs:[import.meta.filename,beforeArg,afterArg,layoutArg,path.resolve(import.meta.dirname,'../phase22/frontend-layout-compare.mjs')].map(ident),
 scope:'No probe rerun and no fixture/path/result normalization. Retained rows compared using the existing exact module-layout policy plus all behavioral fields and registered metadata.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review.mjs'));
const fields=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','diagnostic','stdout','stderr','output','error','signal','reason'];
const allowed=new Set([...fields,'files','sourceFile','hostProvenance']);
try{
 for(const raw of [before,after]){assert.ok(raw.finished);assert.equal(raw.changedInputs.length,0);assert.equal(raw.identity.adapterChangedDuringRun,false);assert.equal(raw.identity.changedArtifacts.length,0);assert.equal(raw.workers.length,4);
  for(const w of raw.workers){assert.equal(w.errors.length,0);assert.equal(w.stats.timeouts,0);assert.equal(w.stats.failures,0);}
  for(const [file,sha]of Object.entries(raw.inputHashes)){assert.equal(fs.realpathSync(file),raw.inputPaths[file]);assert.equal(ident(file).sha256,sha);}
  for(const [name,entry]of Object.entries(raw.identity.artifacts)){assert.equal(raw.identity.finalArtifactHashes[name],entry.sha256);assert.equal(ident(entry.file).sha256,entry.sha256);}
 }
 const comparison=compareReports(before,after,{strictPaths:true,moduleLayoutMigration:layout});
 assert.equal(comparison.pathComparison,'exact');assert.equal(comparison.sameObservedBehavior,true);assert.deepEqual(comparison.changes,[]);assert.deepEqual(comparison.missing,[]);
 const expectedAdded=['src/back/js/u32.bend','src/back/js/primitive.bend','src/back/js/region.bend','src/back/js/worker.bend','src/back/js/tree.bend'];
 assert.deepEqual(comparison.moduleLayout.added,expectedAdded);assert.deepEqual(comparison.moduleLayout.removed,[]);
 assert.deepEqual(comparison.moduleLayout.orderedAfter.filter(x=>!expectedAdded.includes(x)),comparison.moduleLayout.orderedBefore);
 assert.deepEqual(comparison.moduleLayout.before.nonModules,{upstream:'018751270e800bc222a93dad7f257083ee53a5f7',targetVersion:'2.0.34'});
 assert.deepEqual(comparison.moduleLayout.after.nonModules,comparison.moduleLayout.before.nonModules);
 const map=new Map(before.results.map(x=>[x.id+'\0'+x.lane,x]));assert.equal(map.size,before.results.length);const rows=[];
 for(const row of after.results){const key=row.id+'\0'+row.lane,prior=map.get(key);assert.ok(prior,key);map.delete(key);
  for(const [side,item,raw]of [['before',prior,before],['after',row,after]]){const r=item.result??{};for(const k of Object.keys(r))assert.ok(allowed.has(k),'Unknown '+side+' result field '+k);
   if(r.hostProvenance){assert.equal(r.hostProvenance.driverSha256,raw.identity.artifacts.driver.sha256);assert.equal(r.hostProvenance.adapterSha256,raw.identity.adapterSha256);}
   for(const file of [...(r.files??[]),...(r.sourceFile?[r.sourceFile]:[])]){assert.equal(typeof file,'string');assert.ok(path.isAbsolute(file));assert.ok(raw.inputHashes[file]||Object.values(raw.identity.artifacts).some(a=>a.file===file),'Unregistered source metadata');}
  }
  const observed=x=>fields.map(k=>[k,x.result?.[k]??null]);assert.deepEqual(observed(row),observed(prior),key);rows.push({id:row.id,lane:row.lane,verdict:row.status,exact:true});
 }
 assert.equal(map.size,0);assert.equal(rows.length,after.results.length);fs.writeFileSync(path.join(out,'per-probe.json'),JSON.stringify(rows,null,2)+'\n',{flag:'wx'});fs.writeFileSync(path.join(out,'comparison.json'),JSON.stringify(comparison,null,2)+'\n',{flag:'wx'});
 report.comparison=ident(path.join(out,'comparison.json'));report.perProbe=ident(path.join(out,'per-probe.json'));report.probes=rows.length;report.moduleLayout=comparison.moduleLayout;report.referenceSummary=comparison.beforeSummary;report.candidateSummary=comparison.afterSummary;
 for(const input of report.inputs)assert.deepEqual(ident(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,probes:report.probes,error:report.error}));
