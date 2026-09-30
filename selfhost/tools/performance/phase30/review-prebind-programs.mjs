// One untimed output gate per complete original program and isolated variant.
import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});const root=path.resolve(import.meta.dirname,'../../../build/phase30');
const ident=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-prebind-original-output-gates',complete:false,pass:false,inputs:[ident(import.meta.filename)],observations:[]};fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try{for(const [fixture,expected]of [['editdist',2065873279],['mandel',887240761]])for(const variant of ['baseline','candidate','fused']){const file=path.join(root,'review-prebind-'+fixture+'-01',variant+'.mjs');report.inputs.push(ident(file));const m=await import(pathToFileURL(file));const result=m.default.bench(2,0);assert.equal(result,expected,fixture+'/'+variant);report.observations.push({fixture,variant,args:[2,0],expected,result});}
 for(const input of report.inputs)assert.deepEqual(ident(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1;}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,observations:report.observations.length,error:report.error}));
