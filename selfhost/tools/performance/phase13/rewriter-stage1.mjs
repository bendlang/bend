import fs from 'node:fs';import path from 'node:path';import assert from 'node:assert/strict';
import {identity,verifyIdentity} from '../../development/workflow.mjs';
import {transformEquality,verifyEqualityDerivation} from '../../../build/phase12/integrated-03/snapshot/tools/development/equality.mjs';
import {transform} from './rewriter-v5.mjs';
const [outArg]=process.argv.slice(2),out=path.resolve(outArg);fs.mkdirSync(out);
const files=[import.meta.filename,path.join(import.meta.dirname,'rewriter-v5.mjs'),path.join(import.meta.dirname,'rewriter-structure.mjs'),path.resolve('experiments/phase13/P13-002-structured-branches.md'),path.resolve('selfhost/build/phase12/integrated-03/snapshot/tools/development/equality.mjs'),process.execPath];
const consumed=path.join(out,'consumed');fs.mkdirSync(consumed);for(const f of files.slice(0,-1))fs.copyFileSync(f,path.join(consumed,path.basename(f)));
const inputs=files.map(identity),report={kind:'phase13-structured-v5-compatibility',complete:false,pass:false,inputs,rows:[],scope:'Exact source bytes and JSON.stringify statistics against authentic v1-v5 derivations. No compiler timing, new bootstrap, worker lifting or promotion.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');save();
const cases=[
 [1,'selfhost/build/phase8/release-verification-01/legacy/dist/release-lineage/derivation.json'],
 [2,'selfhost/build/phase9/equality-derivation-01/api.mjs.derivation.json'],
 [3,'selfhost/build/phase10/release-smoke-02/relocated/dist/release-lineage/derivation.json'],
 [4,'selfhost/build/phase11/release-smoke-01/relocated/dist/release-lineage/derivation.json'],
 [5,'selfhost/build/phase12/integrated-03/equality/api.mjs.derivation.json']
];
try{
 for(const [version,file] of cases){
  const verified=verifyEqualityDerivation(path.resolve(file)),m=verified.metadata;
  assert.equal(m.transform.version,version);for(const f of [file,m.original.api.file,m.output.file])inputs.push(identity(f));
  const source=fs.readFileSync(m.original.api.file,'utf8'),expected=transformEquality(source,version),actual=transform(source,{version});
  const dir=path.join(out,'version-'+version);fs.mkdirSync(dir);fs.writeFileSync(path.join(dir,'actual-api.mjs'),actual.source);fs.writeFileSync(path.join(dir,'actual-stats.json'),JSON.stringify(actual.stats,null,2)+'\n');fs.writeFileSync(path.join(dir,'expected-stats.json'),JSON.stringify(expected.stats,null,2)+'\n');
  const row={version,parent:identity(m.original.api.file),expected:identity(m.output.file),actual:identity(path.join(dir,'actual-api.mjs')),sourceEqual:actual.source===expected.source,statsEqual:JSON.stringify(actual.stats)===JSON.stringify(expected.stats),authenticStatsEqual:JSON.stringify(actual.stats)===JSON.stringify(m.transform)};report.rows.push(row);save();
  assert.equal(actual.source,fs.readFileSync(m.output.file,'utf8'),'Authentic source bytes differ');assert.ok(row.sourceEqual&&row.statsEqual&&row.authenticStatsEqual,'Exact transformation compatibility');console.log(JSON.stringify(row));
 }
 inputs.forEach(verifyIdentity);report.inputsVerified=true;report.complete=true;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1;}
save();
