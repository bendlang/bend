// Untimed mechanism counters; never a runtime performance measurement.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
const [modulePath,pointPath]=process.argv.slice(2);
const sha=p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const report={kind:'phase29-untimed-operation-counts',complete:false,module:{file:modulePath,sha256:sha(modulePath)},points:{file:pointPath,sha256:sha(pointPath)},observations:[]};
try {
  const module=await import(pathToFileURL(modulePath));
  for(const point of JSON.parse(fs.readFileSync(pointPath)).points.filter(p=>p.exportName==='bench')) {
    module.prototypeCounters(true);
    const actual=module.default[point.exportName](...point.args);
    const counters=module.prototypeCounters();
    report.observations.push({...point,actual,counters});
    assert.equal(actual,point.expected);
  }
  assert.equal(sha(modulePath),report.module.sha256);assert.equal(sha(pointPath),report.points.sha256);
  report.complete=true;
} catch(error) {report.error=error.stack??String(error);process.exitCode=1;}
console.log(JSON.stringify(report));
