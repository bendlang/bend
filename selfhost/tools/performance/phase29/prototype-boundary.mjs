// ABI controls on the disposable worker; not proof of a general compiler rule.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [originalPath,...candidatePaths]=process.argv.slice(2);
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const report={kind:'phase29-prototype-public-boundary',complete:false,modules:[],observations:[]};
function shape(value){
  if(value?.code)return {arity:value.arity,bound:value.bound.map(v=>typeof v==='bigint'?v+'n':v),env:value.env};
  return {value};
}
function observe(module){
  const rows=[];
  for(const n of [0n,1n,7n]) {
    let f=module.G.mit;rows.push({case:'initial',n:n+'n',shape:shape(f)});
    for(const [index,arg] of [n,0,0,0,0,0,91].entries()) {
      f=module.call(f,[arg]);rows.push({case:'one-at-a-time',n:n+'n',applied:index+1,shape:shape(f)});
    }
    assert.equal(f,91+Number(n));
    for(let cut=1;cut<7;cut++) {
      const args=[n,0,0,0,0,0,91];
      const partial=module.call(module.G.mit,args.slice(0,cut));
      const actual=module.call(partial,args.slice(cut));
      assert.equal(actual,91+Number(n));
      rows.push({case:'grouped-prefix',n:n+'n',cut,shape:shape(partial),actual});
    }
    try {module.call(module.G.mit,[n,0,0,0,0,0,91,0]);assert.fail('oversaturation should fail');}
    catch(error){rows.push({case:'oversaturated',n:n+'n',error:error.name+': '+error.message});}
  }
  for(const invalid of ['invalid',{},null]) {
    let laterReached=false;
    try {const partial=module.call(module.G.mit,[invalid]);laterReached=true;module.call(partial,[0]);}
    catch(error){rows.push({case:'early-invalid-first-argument',invalid,laterReached,error:error.name+': '+error.message});}
    assert.equal(laterReached,false);
  }
  return rows;
}
try {
  let expected;
  for(const modulePath of [originalPath,...candidatePaths]) {
    const identity={file:modulePath,sha256:sha(modulePath)};report.modules.push(identity);
    const module=await import(pathToFileURL(modulePath));const observations=observe(module);
    report.observations.push({module:identity,observations});
    if(expected)assert.deepEqual(observations,expected);else expected=observations;
    assert.equal(sha(modulePath),identity.sha256);
  }
  report.complete=true;
} catch(error){report.error=error.stack??String(error);process.exitCode=1;}
console.log(JSON.stringify(report));
