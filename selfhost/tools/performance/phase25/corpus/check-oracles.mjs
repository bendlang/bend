// Small correctness acquisition. Timings are intentionally absent.
import fs from 'node:fs';
import path from 'node:path';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
const directory=path.join(import.meta.dirname,'pilot-evidence',process.argv[2]);
const emission=path.join(import.meta.dirname,'pilot-evidence','attempt-03');
fs.mkdirSync(directory,{recursive:false});
const rows=JSON.parse(fs.readFileSync(path.join(import.meta.dirname,'metadata.json'),'utf8'));
fs.copyFileSync(import.meta.filename,path.join(directory,'consumed-check-oracles.mjs'));
fs.copyFileSync(path.join(import.meta.dirname,'oracles.mjs'),path.join(directory,'oracles.mjs'));
fs.copyFileSync(path.join(import.meta.dirname,'metadata.json'),path.join(directory,'metadata.json'));
const observations=[];
for(const row of rows){
 const file=path.join(emission,row.id+'.mjs');
 const generatedSha256=createHash('sha256').update(fs.readFileSync(file)).digest('hex');
 const api=(await import(pathToFileURL(file))).default;
 for(const point of row.correctness){
  let actual,error;try{actual=api.bench(point.size,point.seed);}catch(e){error=String(e.stack??e);}
  observations.push({id:row.id,...point,actual,error,pass:!error&&actual===point.expected,generatedSha256});
 }
 const subset=observations.filter(x=>x.id===row.id);
 console.log(row.id,subset.filter(x=>x.pass).length+'/'+subset.length);
 fs.writeFileSync(path.join(directory,'report.json'),JSON.stringify({kind:'upstream-generated-corpus-oracles',performanceMeasurement:false,observations},null,2)+'\n');
}
if(observations.some(x=>!x.pass))process.exitCode=1;
