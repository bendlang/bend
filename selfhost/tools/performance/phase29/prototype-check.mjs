// Untimed correctness acquisition for disposable generated-JavaScript variants.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [modulePath,pointsPath]=process.argv.slice(2);
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const report={kind:'phase29-prototype-correctness',complete:false,module:{file:modulePath,sha256:sha(modulePath)},points:{file:pointsPath,sha256:sha(pointsPath)},observations:[]};
try {
  const module=await import(pathToFileURL(modulePath));
  for(const p of JSON.parse(fs.readFileSync(pointsPath)).points) {
    const actual=module.default[p.exportName](...p.args);
    report.observations.push({...p,actual});
    assert.equal(actual,p.expected);
  }
  assert.equal(sha(modulePath),report.module.sha256);
  assert.equal(sha(pointsPath),report.points.sha256);
  report.complete=true;
} catch(error) { report.error=error.stack??String(error);process.exitCode=1; }
console.log(JSON.stringify(report));
