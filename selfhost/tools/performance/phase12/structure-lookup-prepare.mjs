import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';

const project = path.resolve(import.meta.dirname, '../../..');
const baseline = path.resolve(process.argv[2]), out = path.resolve(process.argv[3]);
fs.mkdirSync(out);
const candidate = path.join(out, 'project'); fs.mkdirSync(candidate);
for (const directory of ['src', 'tools', 'tests']) fs.cpSync(path.join(baseline, directory), path.join(candidate, directory), { recursive: true });
const file = path.join(candidate, 'src/back/js/emit.bend'), before = fs.readFileSync(file, 'utf8');
const old = 'j_specialize(book, dt(j_find_ctor(book, nm(t))), ks(wnf(book, ty)))';
if (before.split(old).length !== 4) throw Error('Expected exactly three constructor sites');
const replacement = 'j_specialize(book, dt(j_layout_ctor(book, wnf(book, ty), nm(t))), ks(wnf(book, ty)))';
const after = before.split(old).join(replacement); fs.writeFileSync(file, after);
const hash = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
fs.writeFileSync(path.join(out, 'manifest.json'), JSON.stringify({ baseline, candidate, file, beforeSha256: hash(before), afterSha256: hash(after), lineDelta: 0, byteDelta: Buffer.byteLength(after) - Buffer.byteLength(before), change: 'Three JS constructor telescope sites reuse the existing normalized-ADT local lookup with general fallback.' }, null, 2) + '\n');
fs.writeFileSync(path.join(out, 'config.json'), JSON.stringify({ project: candidate, upstream: path.join(project, '.bootstrap/upstream-phase8'), profile: 'equality', jobs: 1, cpu: '1', timeoutMs: 30000 }, null, 2) + '\n');
