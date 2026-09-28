// Count only the modules in each immutable compiler's ordered assembly manifest.
import fs from 'node:fs';
import path from 'node:path';
import {verifyAttempt, identity, verifyIdentity} from '../../development/workflow.mjs';
const [baseline, candidate, output] = process.argv.slice(2);
const rows = [];
for (const [name, attempt] of [['baseline', baseline], ['candidate', candidate]]) {
  const m = await verifyAttempt(attempt), manifest = path.join(m.snapshot.root, 'src/compiler.json');
  const files = JSON.parse(fs.readFileSync(manifest)).modules.map(relative => {
    const file = path.join(m.snapshot.root, relative), text = fs.readFileSync(file, 'utf8');
    const lines = text.split('\n'); if (lines.at(-1) === '') lines.pop();
    return {...identity(file), relative, bytes: Buffer.byteLength(text), physical: lines.length,
      nonblank: lines.filter(x => x.trim()).length,
      defs: lines.filter(x => /^def\s/.test(x)).length,
      laws: lines.filter(x => /^law\s/.test(x)).length,
      types: lines.filter(x => /^type\s/.test(x)).length};
  });
  const totals = Object.fromEntries(['bytes', 'physical', 'nonblank', 'defs', 'laws', 'types']
    .map(key => [key, files.reduce((n, f) => n + f[key], 0)]));
  files.forEach(verifyIdentity);
  rows.push({name, attempt: identity(path.join(attempt, 'attempt.json')), manifest: identity(manifest),
    modules: files.length, totals, files, api: {...m.api, bytes: fs.statSync(m.api.file).size}});
}
const report = {method: 'Physical/nonblank lines and column-zero def/law/type declarations in ordered linked modules. Excludes historical unlinked compiler, generated API and host tools. Counts do not prove conceptual complexity.',
  tool: identity(import.meta.filename), node: identity(process.execPath), rows};
fs.writeFileSync(output, JSON.stringify(report, null, 2) + '\n', {flag: 'wx'});
console.log(JSON.stringify(rows.map(({name, modules, totals, api}) => ({name, modules, totals, api}))));
