// Compare unchanged-source and candidate observations, retaining TS differences.
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
const [baselineArg,candidateArg,outputArg]=process.argv.slice(2);
const baseline=fs.realpathSync(baselineArg),candidate=fs.realpathSync(candidateArg),output=path.resolve(outputArg);
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const load=(directory,name)=>{const file=path.join(directory,'validation-001/selected',name+'.json');return {identity:identity(file),data:JSON.parse(fs.readFileSync(file))};};
const before=load(baseline,'candidate'),after=load(candidate,'candidate'),reference=load(candidate,'reference');
const observation=result=>Object.fromEntries(Object.entries(result).filter(([key])=>key!=='hostProvenance'));
const semantics=result=>Object.fromEntries(['status','phase','checked','typeAccepted','proofTrust','kernelChecked','exitCode'].map(key=>[key,result[key]??null]));
const canonical=value=>JSON.stringify(value,Object.keys(value).sort());
const index=doc=>new Map(doc.results.map(row=>[row.id+'\0'+row.lane,row]));
const old=index(before.data),next=index(after.data),ref=index(reference.data),rows=[];
for(const [key,row] of next){
  const prior=old.get(key),oracle=ref.get(key);
  rows.push({id:row.id,lane:row.lane,baselinePresent:!!prior,referencePresent:!!oracle,
    exactBaselineMatch:!!prior&&JSON.stringify(observation(prior.result))===JSON.stringify(observation(row.result)),
    semanticReferenceMatch:!!oracle&&canonical(semantics(oracle.result))===canonical(semantics(row.result)),
    baselineStrictStatus:prior?.status,candidateStrictStatus:row.status,referenceStrictStatus:oracle?.status});
}
const healthy=doc=>doc.changedInputs?.length===0&&doc.identity?.changedArtifacts?.length===0&&doc.identity?.adapterChangedDuringRun===false&&doc.results.every(r=>!['crash','timeout','unsupported'].includes(r.result?.status));
const pass=rows.length===old.size&&rows.length===ref.size&&rows.every(r=>r.exactBaselineMatch&&r.semanticReferenceMatch)&&[before.data,after.data,reference.data].every(healthy);
const report={kind:'checker-observation-preservation',scope:'Full selected result objects versus unchanged B1, excluding hostProvenance only; semantic metadata versus pinned reference. Upstream diagnostic equality remains a separate known-failing gate.',inputs:[identity(import.meta.filename),before.identity,after.identity,reference.identity],selected:rows.length,pass,rows};
fs.writeFileSync(output,JSON.stringify(report,null,2)+'\n',{flag:'wx'});
console.log(JSON.stringify({pass,selected:rows.length,changed:rows.filter(r=>!r.exactBaselineMatch||!r.semanticReferenceMatch)}));if(!pass)process.exitCode=1;
