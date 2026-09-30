import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';import {createHash} from 'node:crypto';import {pathToFileURL} from 'node:url';
const [outArg,...files]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out,{recursive:false});
const identity=file=>({file:fs.realpathSync(file),sha256:createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report={kind:'phase32-local-scope-controls',complete:false,pass:false,inputs:[import.meta.filename,...files,...files.map(f=>f+'.json')].map(identity),oracle:[],boundaries:[]};
fs.copyFileSync(import.meta.filename,path.join(out,'consumed-controls.mjs'));
try{
 const modules=await Promise.all(files.map(p=>import(pathToFileURL(fs.realpathSync(p)))));
 for(const n of [0,1,2,3,7,16,32,257])for(const seed of [0,1,5,17,4294967295]){let value=BigInt(seed);for(let i=0;i<n;i++)value=(3n*value+27n)&0xffffffffn;const expected=Number(value),results=modules.map(m=>m.default.bench(n,seed));for(const r of results)assert.equal(r,expected);report.oracle.push({n,seed,expected,results})}
 for(const name of ['scope.mix','scope.score','scope.walk']){const observations=[];for(const m of modules){const f=m.G[name],old=f.code,events=[];try{f.code=()=>{events.push(name);throw Error('mutation:'+name)};try{observations.push({value:m.default.bench(2,5),events})}catch(e){observations.push({error:e.message,events})}}finally{f.code=old}}for(const o of observations.slice(1))assert.deepEqual(o,observations[0]);report.boundaries.push({name,observations})}
 for(const input of report.inputs)assert.deepEqual(identity(input.file),input);report.complete=true;report.pass=true;
}catch(error){report.error=error.stack;process.exitCode=1}
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify({complete:report.complete,pass:report.pass,oracle:report.oracle.length,boundaries:report.boundaries.length,error:report.error}));
