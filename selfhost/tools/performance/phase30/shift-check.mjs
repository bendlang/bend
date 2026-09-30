import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [dir,out]=process.argv.slice(2);
assert.ok(dir&&out&&!fs.existsSync(out),'usage: shift-check.mjs DERIVED_DIR NEW_JSON');
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const names=['baseline','region','constant','upstream'],mods={};
const files=names.map(n=>path.resolve(dir,n+'.mjs'));
for(let i=0;i<names.length;i++)mods[names[i]]=await import(pathToFileURL(files[i]));
const pointsFile=path.resolve(import.meta.dirname,'../phase29/fixture-points.json');
const points=JSON.parse(fs.readFileSync(pointsFile)).points;
const rows=[];
for(const p of [...points,{exportName:'point',args:[50000,0,0,0,0,0,0],expected:50000}]){
 const values={};for(const n of names){values[n]=mods[n].default[p.exportName](...p.args);assert.equal(values[n],p.expected,n+' '+JSON.stringify(p.args));}
 rows.push({...p,values});
}
const host=[];
for(const value of [0,1,1.5,'0',null,undefined]){
 const values=[];
 for(const n of names.slice(0,3)){
  const m=mods[n],f=m.default.mit(2n);
  try{values.push({value:f.code.call(null,[value,255,384,0,0,0,0])});}
  catch(e){values.push({error:{name:e.name,message:e.message}});}
 }
 assert.deepEqual(values[1],values[0]);assert.deepEqual(values[2],values[0]);host.push({input:String(value),values});
}
for(const n of names.slice(0,3)){
 const m=mods[n],f=m.default.mit(50000n),before=[...f.bound];
 assert.equal(m.call(f,[0,0,0,0,0,0]),50000);assert.deepEqual(f.bound,before);
}
fs.writeFileSync(out,JSON.stringify({complete:true,pass:true,scope:'Literal-shift ablation under the frozen private-region input and mutation assumptions; not production semantic admission',inputs:[...files.map(identity),identity(pointsFile),identity(import.meta.filename)],scalarPoints:rows.length,variantObservations:rows.length*4,hostFallbacks:host,retainedPartials:3,rows},null,2)+'\n');
console.log(JSON.stringify({pass:true,scalarPoints:rows.length,variantObservations:rows.length*4,hostFallbacks:host.length,retainedPartials:3}));
