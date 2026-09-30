// Function source text is not an ABI promise; callable kind/name/length are.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [oldFile,newFile,outArgument,mode='counterexample']=process.argv.slice(2);assert.ok(oldFile&&newFile&&outArgument);
const out=path.resolve(outArgument);fs.mkdirSync(out,{recursive:false});const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-public-callback-callable-shape',complete:false,mode,inputs:[import.meta.filename,oldFile,newFile].map(identity),observations:[]};fs.copyFileSync(import.meta.filename,path.join(out,'consumed-review-callable-shape.mjs'));
function shape(code){let constructible;try{Reflect.construct(Object,[],code);constructible=true}catch{constructible=false}return {name:code.name,length:code.length,own:Object.getOwnPropertyNames(code),constructible,functionPrototype:Object.getPrototypeOf(code)===Function.prototype}}
try{
 const old=await import(pathToFileURL(path.resolve(oldFile))),next=await import(pathToFileURL(path.resolve(newFile)));
 for(const name of ['direct','annotated','captured','equalArity','zeroFields']){const baseline=shape(old.G[name].code),candidate=shape(next.G[name].code),same=JSON.stringify(baseline)===JSON.stringify(candidate);report.observations.push({name,baseline,candidate,same});if(mode==='repaired')assert.deepEqual(candidate,baseline,name)}
 if(mode==='counterexample')assert.ok(report.observations.some(x=>!x.same));report.complete=true;
}catch(error){report.error=error.stack??String(error);process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify(report));
