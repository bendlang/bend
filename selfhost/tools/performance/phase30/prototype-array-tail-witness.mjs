// Retain the counterexample to the rejected prospective eager tail lowering.
import fs from 'node:fs';import crypto from 'node:crypto';import assert from 'node:assert/strict';import {pathToFileURL} from 'node:url';
const [modulePath,out]=process.argv.slice(2);fs.mkdirSync(out);const m=await import(pathToFileURL(modulePath));
const ident=file=>({file,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const observe=eager=>{const events=[],storage=[0],array={get array(){events.push('array-get');return storage}};
 const copied=new Proxy([1,2,3],{get(t,k,r){if(k==='length')events.push('copied.length');return Reflect.get(t,k,r)}});
 const f={arity:2,env:null,bound:[],code(){events.push('body');const args=[null,array,0,19];return eager?m.call(m.G['Array.set'],args):{bounce:true,f:m.G['Array.set'],args}}};
 let error;try{m.call(f,{slice(){events.push('input.slice');return copied}})}catch(e){error={name:e.name,message:e.message}}
 return {events,storage,error};};
const original=observe(false),eager=observe(true);assert.deepEqual(original.storage,eager.storage);assert.deepEqual(original.error,eager.error);assert.notDeepEqual(original.events,eager.events);
assert.equal(original.events[original.events.indexOf('body')+1],'copied.length');assert.equal(eager.events[eager.events.indexOf('body')+1],'array-get');
const report={kind:'phase30-rejected-array-tail-order-witness',complete:true,unsafeRejected:true,scope:'Actual unchanged runtime call/apply and native Array.set; a foreign copied-vector length observation separates deferred jump from eager execution.',inputs:[ident(import.meta.filename),ident(modulePath)],node:process.version,original,eager};
fs.copyFileSync(import.meta.filename,out+'/consumed-tool.mjs');fs.writeFileSync(out+'/report.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
