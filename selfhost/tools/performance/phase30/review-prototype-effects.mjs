// Preserve raw ambient-prototype observations across all three generations.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [configFile,outArgument]=process.argv.slice(2);assert.ok(configFile&&outArgument);
const config=JSON.parse(fs.readFileSync(configFile)),out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-three-way-prototype-effects',complete:false,valuesAndErrorsAgree:false,node:process.version,
 scope:'Ambient standard-prototype monkeypatching is outside the optimization contract. Full raw counts/traces are retained without normalization or an effect-equivalence pass claim.',
 inputs:[configFile,import.meta.filename,...Object.values(config)].map(identity),observations:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-prototype-effects.mjs'));
try{
 const modules={};for(const name of ['preworker','phase29','candidate'])modules[name]=await import(pathToFileURL(path.resolve(config[name])));
 for(const [label,prototype]of [['Object',Object.prototype],['Boolean',Boolean.prototype],['Number',Number.prototype],['BigInt',BigInt.prototype]])for(const key of ['request','bounce','build','code']){
  const row={label,key,modules:{}};
  for(const [name,m]of Object.entries(modules)){
   const events=[],old=Object.getOwnPropertyDescriptor(prototype,key);let value,error;
   try{Object.defineProperty(prototype,key,{configurable:true,get(){events.push(label+'.'+key);return false}});value=m.default.mit(2n,255,384,0,0,0,0)}catch(e){error={name:e.name,message:e.message}}
   finally{if(old)Object.defineProperty(prototype,key,old);else delete prototype[key]}
   row.modules[name]={value,error,eventCount:events.length,events};
  }
  for(const name of ['phase29','candidate'])assert.deepEqual({value:row.modules[name].value,error:row.modules[name].error},{value:row.modules.preworker.value,error:row.modules.preworker.error},label+'.'+key+' value/error '+name);
  const equal=(a,b)=>JSON.stringify(row.modules[a])===JSON.stringify(row.modules[b]);
  row.equal={phase29ToPreworker:equal('phase29','preworker'),candidateToPreworker:equal('candidate','preworker'),candidateToPhase29:equal('candidate','phase29')};report.observations.push(row);
 }
 report.changedInputs=report.inputs.filter(x=>identity(x.file).sha256!==x.sha256);assert.deepEqual(report.changedInputs,[]);report.complete=true;report.valuesAndErrorsAgree=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,valuesAndErrorsAgree:report.valuesAndErrorsAgree,observations:report.observations.length,differences:report.observations.filter(x=>!x.equal.candidateToPreworker||!x.equal.phase29ToPreworker).map(x=>({label:x.label,key:x.key,counts:Object.fromEntries(Object.entries(x.modules).map(([k,v])=>[k,v.eventCount])),equal:x.equal})),error:report.error}));
