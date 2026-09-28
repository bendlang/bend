import fs from 'node:fs';import path from 'node:path';
import {identity,verifyIdentity,verifyAttempt} from '../../development/workflow.mjs';
import {transform} from './rewriter-lift-v2.mjs';
const [outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const parentAttempt=path.resolve('selfhost/build/phase12/integrated-03'),m=await verifyAttempt(parentAttempt);
const helper=path.join(import.meta.dirname,'rewriter-lift-v2.mjs'),helperInputs=[helper,path.join(import.meta.dirname,'rewriter-structure.mjs'),path.join(import.meta.dirname,'rewriter-v5.mjs'),path.join(m.snapshot.root,'tools/development/equality.mjs')].map(identity);
const options={families:['$norm_eval_node$']},inputs=[import.meta.filename,path.resolve('experiments/phase13/P13-002-structured-branches.md'),path.join(parentAttempt,'attempt.json'),m.checkedApi.file,m.api.file,m.base.file,m.runtime.file,process.execPath].map(identity);
const report={kind:'phase13-structured-worker-candidate',complete:false,parentAttempt,checkedApi:m.checkedApi,baselineApi:m.api,base:m.base,runtime:m.runtime,helper:identity(helper),helperInputs,options,inputs,scope:'Explicit derived image from verified checked parent, no new bootstrap. One family; immutable parameter captures; no compiler performance claim.'};
const save=()=>fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(report,null,2)+'\n');save();
const consumed=path.join(out,'consumed');fs.mkdirSync(consumed);for(const i of [...helperInputs,...inputs.filter(x=>x.file.endsWith('.mjs')||x.file.endsWith('.md'))])fs.copyFileSync(i.file,path.join(consumed,path.basename(i.file)));
try{
 const result=transform(fs.readFileSync(m.checkedApi.file,'utf8'),options),api=path.join(out,'api.mjs');fs.writeFileSync(api,result.source);fs.writeFileSync(path.join(out,'transform.json'),JSON.stringify(result.report,null,2)+'\n');
 report.api=identity(api);report.transformReport=result.report;report.transformReportIdentity=identity(path.join(out,'transform.json'));[...inputs,...helperInputs].forEach(verifyIdentity);report.complete=true;report.inputsVerified=true;
 console.log(JSON.stringify({api:report.api,sites:result.report.sites,workers:result.report.workers.length,captureElements:result.report.staticCaptureElements,captures:result.report.workers.map(w=>w.captures.length)}));
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}save();
