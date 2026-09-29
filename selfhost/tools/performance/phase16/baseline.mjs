import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity} from '../../development/workflow.mjs';
import {verifyRelease} from '../../development/release.mjs';
const root = path.resolve(import.meta.dirname, '../../../..');
const attempt = path.join(root, 'selfhost/build/phase15/combined-02');
const out = path.join(root, 'selfhost/build/phase16/baseline-01'); fs.mkdirSync(out);
const m = await verifyAttempt(attempt), release = verifyRelease(path.join(root, 'selfhost'));
assert.equal(m.api.sha256, 'b8d658c564226a52764a435df86059aa3cea6b0c428bbde5341a62c2253c2e2d');
assert.equal(release.files.find(f => f.path === 'dist/typed-api.mjs').sha256, m.api.sha256);
const inputs = [import.meta.filename, process.execPath, path.join(attempt, 'attempt.json'),
  path.join(root, 'selfhost/dist/release.json'), path.join(root, 'selfhost/build/phase16/start-state.json'),
  path.join(root, 'selfhost/build/phase15/frontend-01/candidate.json'),
  path.join(root, 'selfhost/build/phase8/reference-frontend-01/reference.json')].map(identity);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify({kind: 'phase16-baseline-verification',
  complete: true, pass: true, verifiedAt: new Date().toISOString(), api: m.api, checkedApi: m.checkedApi,
  inputs, scope: 'Verify actual installed release integrity and genuine checked/derived lineage; retained frontend vectors are bound, not rerun.'}, null, 2) + '\n');
console.log(JSON.stringify({pass: true, api: m.api.sha256}));
