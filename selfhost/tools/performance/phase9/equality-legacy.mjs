// Verify the retained authentic old equality release with the new dual-profile tool.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {verifyRelease} from '../../development/release.mjs';
import {transformEquality} from '../../development/equality.mjs';
const [rootArg,outArg]=process.argv.slice(2),root=fs.realpathSync(rootArg),out=path.resolve(outArg);
fs.mkdirSync(out);
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const files=[import.meta.filename,new URL('../../development/equality.mjs',import.meta.url),new URL('../../development/release.mjs',import.meta.url),path.join(root,'dist/release.json')];
const inputs=files.map(file=>({file:String(file),sha256:sha(fs.readFileSync(file))}));
const report={kind:'phase9-legacy-equality-release-replay',pass:false,inputs};
try{
 const release=verifyRelease(root);assert.equal(release.artifact,'equality-derived-b1');
 const checked=fs.readFileSync(path.join(root,'dist/release-lineage/checked-api.mjs'),'utf8'),replay=transformEquality(checked);
 const expected=sha(fs.readFileSync(path.join(root,'dist/typed-api.mjs')));
 assert.equal(replay.stats.version,1);assert.equal(sha(replay.source),expected);
 files.forEach((file,i)=>assert.equal(sha(fs.readFileSync(file)),inputs[i].sha256));
 report.replaySha256=expected;report.transform=replay.stats;report.pass=true;
}catch(error){report.error=String(error.stack??error);process.exitCode=1}
fs.copyFileSync(import.meta.filename,path.join(out,'equality-legacy.mjs.source'));
fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({pass:report.pass,error:report.error}));
