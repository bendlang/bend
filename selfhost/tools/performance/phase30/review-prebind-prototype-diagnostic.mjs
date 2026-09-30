// Preserve every ambient-prototype trace; no effect-equivalence pass is claimed.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-partial-prebinding-ambient-prototype-diagnostic',complete:false,fusedEquivalent:false,genericMatchesOriginal:false,inputs:[import.meta.filename,path.join(base,'derive.json')].map(ident),observations:[],
 scope:'Ambient Object.prototype mutation is outside the frozen standard-intrinsic contract. Generic/reference and fused/current must match. All generic/current trace or result differences remain visible; they are not a full equivalence pass.'};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
const modules={};for(const side of ['baseline','candidate','fused']){const source=path.join(base,'core-'+side+'.mjs'),target=path.join(out,side+'.mjs');report.inputs.push(ident(source));fs.writeFileSync(target,fs.readFileSync(source,'utf8')+'\nexport {fn,call,matcher1,matcher1p};\n',{flag:'wx'});modules[side]=await import(pathToFileURL(target));}
function observe(m,reference,key,throws){const events=[],old=Object.getOwnPropertyDescriptor(Object.prototype,key);let value,error,count=0;
 const c=(a)=>a[0]+a[1]+a[2],f=reference?m.matcher1('ReviewRec',()=>m.fn(3,c)):m.matcher1p('ReviewRec',2,3,()=>c);
 try{Object.defineProperty(Object.prototype,key,{configurable:true,get(){events.push(key);if(++count===throws)throw Error('prototype sentinel '+key);return false;}});
  const p=m.call(f,[{$:'ReviewRec',a:[7,11]}]);value=m.call(p,[13]);
 }catch(e){error={name:e.name,message:e.message};}
 finally{if(old)Object.defineProperty(Object.prototype,key,old);else delete Object.prototype[key];}
 return {value,error,eventCount:events.length,events};
}
try{
 for(const key of ['request','bounce','build','code','io','typeName'])for(const throws of [0,2,4,8]){
  const results={reference:observe(modules.baseline,true,key,throws)};for(const side of Object.keys(modules))results[side]=observe(modules[side],false,key,throws);
  const same=(a,b)=>JSON.stringify(results[a])===JSON.stringify(results[b]);
  report.observations.push({key,throws,results,genericMatchesOriginal:same('candidate','reference'),fusedMatchesCurrent:same('fused','baseline'),genericMatchesCurrent:same('candidate','baseline')});
 }
 report.fusedEquivalent=report.observations.every(x=>x.fusedMatchesCurrent);report.genericMatchesOriginal=report.observations.every(x=>x.genericMatchesOriginal);
 report.genericCurrentDifferences=report.observations.filter(x=>!x.genericMatchesCurrent).map(x=>({key:x.key,throws:x.throws}));
 assert.equal(report.fusedEquivalent,true);assert.equal(report.genericMatchesOriginal,true);
 for(const item of report.inputs)assert.deepEqual(ident(item.file),item);report.complete=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,fusedEquivalent:report.fusedEquivalent,genericMatchesOriginal:report.genericMatchesOriginal,observations:report.observations.length,differences:report.genericCurrentDifferences,error:report.error}));
