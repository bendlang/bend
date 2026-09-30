// Freeze/check the larger fold timing point with a separate BigInt oracle.
import fs from'node:fs';import path from'node:path';import assert from'node:assert/strict';import{createHash}from'node:crypto';import{pathToFileURL}from'node:url';
const [outArg,...moduleArgs]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase31-fold4096-oracle',complete:false,pass:false,inputs:[import.meta.filename,...moduleArgs].map(identity),point:{args:[4096,17]},modules:[]};fs.copyFileSync(import.meta.filename,path.join(out,'consumed-point.mjs'));
try{const cells=Array(128).fill(17n),mask=(1n<<32n)-1n;let total=0n;for(let i=0;i<4096;i++){const at=i%128;total=(total+cells[at])&mask;cells[at]=(total^BigInt(i))&mask}report.point.expected=Number(total);
 for(const file of moduleArgs){const m=await import(pathToFileURL(fs.realpathSync(file))),result=m.default.bench(...report.point.args);assert.equal(result,report.point.expected);report.modules.push({file:fs.realpathSync(file),result})}
 for(const r of report.inputs)assert.deepEqual(identity(r.file),r);report.complete=true;report.pass=true;
}catch(e){report.error=e.stack;process.exitCode=1}fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,point:report.point,modules:report.modules.length,error:report.error}));
