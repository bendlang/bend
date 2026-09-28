import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {identity,verifyAttempt} from '../../development/workflow.mjs';

const [baseArg,outArg]=process.argv.slice(2),base=path.resolve(baseArg),out=path.resolve(outArg);
const prior=await verifyAttempt(base);
assert.equal(prior.api.sha256,'63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f');
fs.mkdirSync(out,{recursive:false});const project=path.join(out,'project');fs.mkdirSync(project);
for(const part of ['src','tools','tests'])fs.cpSync(path.join(prior.snapshot.root,part),path.join(project,part),{recursive:true});
const relative='src/core/normalize.bend',file=path.join(project,relative),source=fs.readFileSync(file,'utf8');
const before='norm_eval(book, t, Nil{}, 0, atom("Absent"))',after='norm_eval(book, t, Nil{}, 0, t)';
assert.equal(source.split(before).length,2);fs.writeFileSync(file,source.replace(before,()=>after));
const config=path.join(out,'config.json');fs.writeFileSync(config,JSON.stringify({project,upstream:path.resolve('selfhost/.bootstrap/upstream-phase8'),cpu:'2',profile:'equality',jobs:1,timeoutMs:30000},null,2)+'\n');
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify({kind:'phase12-unused-initial-fallback-ablation',
  baseline:prior.api,inputs:[identity(import.meta.filename),identity(path.join(base,'attempt.json'))],project,config,
  source:{file:relative,preimage:identity(path.join(prior.snapshot.root,relative)),candidate:identity(file),before,after},
  delta:{physical:0,nonblank:0,bytes:Buffer.byteLength(after)-Buffer.byteLength(before),helpers:0,types:0},
  invariant:'The initial fallback cannot be returned while left is zero; every transition to positive left replaces it with the reference fallback.'},null,2)+'\n');
console.log(JSON.stringify({project,config,source:identity(file)}));
