// One bounded source-confound test; the frozen broad helper is never installed.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
import {deriveEquality,verifyEqualityDerivation} from '../../../build/phase12/call-maintained-01/project/tools/development/equality.mjs';
const [parentArg,outArg]=process.argv.slice(2),out=path.resolve(outArg),parent=await verifyAttempt(path.resolve(parentArg));fs.mkdirSync(out);
const helper=path.resolve('selfhost/build/phase12/call-maintained-01/project/tools/development/equality.mjs');assert.equal(identity(helper).sha256,'dbfc09f0656e3d46fb0f1a4b56e264ba819e3022f4a224c25f65bd56ca7f66ca');
const inputs=[import.meta.filename,helper,path.join(parentArg,'attempt.json'),parent.checkedApi.file,parent.bootstrapReport.file,parent.base.file,parent.runtime.file].map(identity);
const plan={kind:'phase12-broad-without-seed-confound',complete:false,inputs,scope:'Bounded confound test after matched-history seed regression: original frozen broad-v5 helper, genuine JS-only checked parent without seed cleanup; fresh long-string and matched prefix only, unchanged4MiBstack4GiBheap. No live helper edits, timing or promotion.'};
fs.writeFileSync(path.join(out,'plan.json'),JSON.stringify(plan,null,2)+'\n');fs.copyFileSync(import.meta.filename,path.join(out,path.basename(import.meta.filename)));
const broad=path.join(out,'broad');fs.mkdirSync(broad);const project=path.join(broad,'project');fs.mkdirSync(project);for(const name of ['src','tools'])fs.cpSync(path.join(parent.snapshot.root,name),path.join(project,name),{recursive:true});
const derivative=await deriveEquality({api:parent.checkedApi.file,bootstrapReport:parent.bootstrapReport.file,outputDirectory:path.join(broad,'derivation')});verifyEqualityDerivation(derivative.report);inputs.forEach(verifyIdentity);
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify({...plan,complete:true,parentApi:parent.api,derivation:identity(derivative.report),variants:[{name:'broad',api:identity(derivative.api),host:path.join(project,'tools/typed-driver.mjs')}],base:parent.base,runtime:parent.runtime},null,2)+'\n');
console.log(JSON.stringify({api:identity(derivative.api),sites:derivative.metadata.transform.tailChoices.sites,source:derivative.metadata.original.source}));
