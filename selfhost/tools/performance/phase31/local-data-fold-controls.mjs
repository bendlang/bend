// Independent BigInt oracle for one array with first-field delayed writes.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [sourceArg,outArg,...moduleArgs]=process.argv.slice(2),source=fs.realpathSync(sourceArg),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase31-local-array-fold-oracle',complete:false,pass:false,inputs:[import.meta.filename,source,...moduleArgs].map(identity),points:[],negative:[]};fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
function oracle(n,seed,late=false){let acc=0n;const mask=0xffffffffn,a=Array(128).fill(BigInt(seed));for(let i=0;i<n;i++){acc=(acc+a[i%128])&mask;if(!late)a[i%128]=(acc^BigInt(i))&mask}return Number(acc)}
try{
 const modules=await Promise.all(moduleArgs.map(file=>import(pathToFileURL(fs.realpathSync(file)))));
 for(const n of[0,1,2,7,32,64,128,129,130,257])for(const seed of[0,1,17,4294967295]){
  const expected=oracle(n,seed),results=modules.map(m=>m.default.bench(n,seed));for(const v of results)assert.equal(v,expected);report.points.push({args:[n,seed],expected,results});
 }
 for(const [n,seed]of[[130,17],[257,1],[257,4294967295]]){const expected=oracle(n,seed),late=oracle(n,seed,true);assert.equal(expected===late,seed===4294967295);report.negative.push({n,seed,expected,deferredUntilEnd:late,distinguishes:expected!==late})}
 for(const x of report.inputs)assert.deepEqual(identity(x.file),x);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,points:report.points.length,negative:report.negative.length,error:report.error}));
