// Exact diagnostic regression gate. Run after a checked candidate build; this
// compares complete port observations to a frozen pre-compact baseline.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const [baselineArg,candidateArg,casesArg,output]=process.argv.slice(2);
const sha=f=>createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const baseline=JSON.parse(fs.readFileSync(path.join(baselineArg,'attempt.json'))),candidate=JSON.parse(fs.readFileSync(path.join(candidateArg,'attempt.json')));
const cases=JSON.parse(fs.readFileSync(casesArg)).cases;
const inputs=[baselineArg,candidateArg].map(x=>path.join(x,'attempt.json')).concat(casesArg,...cases.map(x=>x.file),baseline.api.file,candidate.api.file,baseline.runtime.file,candidate.runtime.file,baseline.base.file);
const identities=[...new Set(inputs)].map(file=>({file:fs.realpathSync(file),sha256:sha(file)}));
const verify=()=>identities.forEach(i=>assert.equal(sha(i.file),i.sha256,'Changed input '+i.file));
const observed=r=>Object.fromEntries(['status','phase','checked','typeAccepted','proofTrust','kernelChecked','exitCode','diagnostic'].map(k=>[k,r[k]??null]));
const report={kind:'phase9-literal-inference-exact-baseline-controls',complete:false,pass:false,inputs:identities,cases,rows:[],scope:'Exact baseline diagnostic and metadata parity; not merely any rejection, and not a claim of upstream caret parity.'};
const save=()=>fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n');save();
try{
 for(const [variant,m] of [['baseline',baseline],['candidate',candidate]]){
  verify();Object.assign(process.env,{BEND_TYPED_API:m.api.file,BEND_TYPED_RUNTIME:m.runtime.file,BEND_BASE:m.base.file,BEND_UPSTREAM:m.config.upstream,BEND_TYPED_TRACE:''});
  const {inspect}=await import(pathToFileURL(path.join(m.snapshot.root,'tools/typed-driver.mjs')));
  for(const c of cases){const result=observed(await inspect(c.file,{mode:'check',timeoutMs:10000,combinedOutput:true}));const expectedError='- expected : '+c.expectedMessage+'\n- observed : '+c.expectedObserved+'\n';const proper=result.status==='error'&&result.phase==='check'&&result.checked===true&&result.typeAccepted===false&&result.proofTrust==='not-assessed'&&result.exitCode===1&&result.diagnostic.includes(expectedError);report.rows.push({variant,id:c.id,proper,result});save();assert.ok(proper,variant+' wrong diagnostic category '+c.id);}
 }
 const base=new Map(report.rows.filter(x=>x.variant==='baseline').map(x=>[x.id,x.result]));report.comparisons=report.rows.filter(x=>x.variant==='candidate').map(x=>({id:x.id,exactBaselineAgreement:JSON.stringify(base.get(x.id))===JSON.stringify(x.result)}));assert.ok(report.comparisons.every(x=>x.exactBaselineAgreement),'Complete baseline diagnostic changed');verify();report.complete=true;report.pass=true;
}catch(e){report.error=String(e.stack??e);process.exitCode=1;}
save();console.log(JSON.stringify({complete:report.complete,pass:report.pass,rows:report.rows.length,error:report.error}));
