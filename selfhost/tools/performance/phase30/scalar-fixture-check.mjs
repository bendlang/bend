// Independent numeric oracle for the differently shaped, forward helper graph.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [moduleFile,out]=process.argv.slice(2);
assert.ok(moduleFile&&out,'usage: scalar-fixture-check.mjs MODULE NEW_JSON');
assert.ok(!fs.existsSync(out),'fresh report');
const bytes=fs.readFileSync(moduleFile),m=await import(pathToFileURL(path.resolve(moduleFile)));
const api=m.default;
function oracle(n,seed){
  let x=seed>>>0,flag=(x&1)===0;
  for(let i=0;i<n;i++){
    const b=(x^2654435761)>>>0;
    const y=flag?((x+(b>>>3))>>>0):((b^(x<<5))>>>0);
    const z=Math.imul((y+1013904223)>>>0,1664525)>>>0;
    x=z;flag=y<z;
  }
  return (x+(flag?7:19))>>>0;
}
const observations=[];
for(const n of [0,1,2,3,7,31,128,1000,50000])for(const seed of [0,1,2,17,2147483648,4294967294,4294967295]){
  const expected=oracle(n,seed),actual=api.bench(n,seed);
  assert.equal(actual,expected,`n=${n}, seed=${seed}`);
  observations.push({n,seed,expected,actual});
}
for(const n of [0,1,2,31,1000])assert.equal(api.fallback(BigInt(n),4294967290),(4294967290+2*n)>>>0);
fs.writeFileSync(out,JSON.stringify({complete:true,pass:true,module:{file:fs.realpathSync(moduleFile),sha256:createHash('sha256').update(bytes).digest('hex')},observations,fallbackPoints:5},null,2)+'\n');
console.log(JSON.stringify({pass:true,scalarPoints:observations.length,fallbackPoints:5}));
