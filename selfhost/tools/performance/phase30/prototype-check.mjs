import fs from 'node:fs';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [root,...selected]=process.argv.slice(2);
const identity=file=>({file,sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase30-edit-row-correctness',complete:false,scope:'Complete four-array state against independent Python oracle, no timing.',inputs:[identity(import.meta.filename),identity(root+'/points.json')],observations:[]};
try{
 const points=JSON.parse(fs.readFileSync(root+'/points.json'));
 for(const variant of (selected.length?selected:['unchanged','private','upstream'])){
  const path=root+'/'+variant+'.mjs';report.inputs.push(identity(path));const mod=await import(pathToFileURL(path));
  for(const point of points){const actual=mod.default.bench(...point.args);assert.equal(actual,point.expected,variant+':'+point.args);report.observations.push({variant,args:point.args,actual});}
 }
 for(const p of report.inputs)assert.deepEqual(identity(p.file),p);
 report.complete=true;
}catch(e){report.error=e.stack;process.exitCode=1;}
console.log(JSON.stringify(report));
