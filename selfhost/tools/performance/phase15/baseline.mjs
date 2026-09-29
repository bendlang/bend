import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {verifyAttempt, identity} from '../../development/workflow.mjs';
import {verifyRelease} from '../../development/release.mjs';
const root = path.resolve(import.meta.dirname, '../../../..');
const attempt = path.join(root, 'selfhost/build/phase14/combined-01');
const out = path.join(root, 'selfhost/build/phase15/baseline-01'); fs.mkdirSync(out);
const m = await verifyAttempt(attempt), release = verifyRelease(path.join(root, 'selfhost'));
assert.equal(m.api.sha256, '9136be92928eda4b3b8e9c99e4e35d62504a825b458ff237c514d4e99f21206b');
assert.equal(release.files.find(f => f.path === 'dist/typed-api.mjs').sha256, m.api.sha256);
const inputs = [import.meta.filename, process.execPath, path.join(attempt, 'attempt.json'),
  path.join(root, 'selfhost/dist/release.json'), path.join(root, 'selfhost/build/phase15/start-state.json'),
  path.join(root, 'selfhost/build/phase14/frontend-audit-02/candidate.json'),
  path.join(root, 'selfhost/build/phase8/reference-frontend-01/reference.json')].map(identity);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs'));
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify({kind: 'phase15-baseline-verification',
  complete: true, pass: true, verifiedAt: new Date().toISOString(), api: m.api, checkedApi: m.checkedApi,
  inputs, scope: 'Verify actual installed release integrity and genuine checked/derived lineage; retained frontend vectors are bound, not rerun.'}, null, 2) + '\n');
console.log(JSON.stringify({pass: true, api: m.api.sha256}));
