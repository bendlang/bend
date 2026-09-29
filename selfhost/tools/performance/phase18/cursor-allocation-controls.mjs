#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';

// Untimed, separately identified instrumentation. Never substitutes for an API.
const [candidate, parent, directArg, outArg] = process.argv.slice(2);
const out = path.resolve(outArg); fs.mkdirSync(out);
const sha = x => createHash('sha256').update(x).digest('hex');
const id = file => ({ file: path.resolve(file), sha256: sha(fs.readFileSync(file)) });
const report = { complete: false, pass: false, timed: false,
  inputs: [id(import.meta.filename), id(directArg)], artifacts: [], rows: [] };
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs')); save();
const nil = { $: 'Nil' };
try {
  const direct = JSON.parse(fs.readFileSync(directArg)); assert(direct.complete && direct.pass);
  for (const [role, directory] of [['candidate', candidate], ['parent', parent]]) {
    const m = JSON.parse(fs.readFileSync(path.join(directory, 'attempt.json')));
    const W = await import(pathToFileURL(path.join(m.snapshot.root, 'tools/development/workflow.mjs')));
    await W.verifyAttempt(path.resolve(directory));
    const production = fs.readFileSync(m.api.file, 'utf8');
    const functions = role === 'candidate'
      ? ['f_input', 'f_empty', 'f_prepend', 'f_tl', 'f_skip', 'f_space', 'f_raw_tl'] : ['f_tl'];
    let instrumented = production;
    const sites = [];
    for (const name of functions) {
      const pattern = new RegExp('^function \\$' + name + '\\$\\([^\\n]*\\) \\{', 'gm');
      const matches = [...production.matchAll(pattern)]; assert.equal(matches.length, 1, name);
      const start = matches[0].index, end = production.indexOf('\nfunction ', start + 1);
      const body = production.slice(start, end < 0 ? undefined : end);
      const constructors = [...body.matchAll(/\{\$: "FInput"/g)].length;
      if (role === 'candidate') assert.equal(constructors,
        ['f_tl', 'f_skip', 'f_space'].includes(name) ? 2 : name === 'f_raw_tl' ? 0 : 1, name);
      sites.push({ name, constructors, bodySha256: sha(body) });
      instrumented = instrumented.replace(pattern, x => x + '\n  __cursorCounts.' + name + '++;');
    }
    if (role === 'candidate') assert.equal([...production.matchAll(/\{\$: "FInput"/g)].length, 9);
    const initial = Object.fromEntries(functions.map(x => [x, 0]));
    instrumented = 'const __cursorCounts = ' + JSON.stringify(initial) + ';\n' + instrumented
      + '\nexport const __counts = __cursorCounts;\n'
      + 'export const __lex = run_lib((start, text) => run_loop($f_lex_indexed$(start, text)), 2);\n';
    const file = path.join(out, role + '-instrumented.mjs'); fs.writeFileSync(file, instrumented);
    report.artifacts.push({ role, production: id(m.api.file), instrumented: id(file), sites,
      productionPrefixUnchanged: false, reason: 'Exact named-function entry counters only; untimed.' });
    report.inputs.push(id(path.join(directory, 'attempt.json')), id(m.api.file));
    const mod = await import(pathToFileURL(file));
    const compiler = m.artifacts.find(x => x.file.includes('/snapshots/') && x.file.endsWith('/compiler.bend'));
    // Both variants count exactly the unchanged parent compiler source.
    const pm = JSON.parse(fs.readFileSync(path.join(parent, 'attempt.json')));
    const pc = pm.artifacts.find(x => x.file.includes('/snapshots/') && x.file.endsWith('/compiler.bend'));
    assert(compiler && pc);
    for (const [name, source] of [['Base', pm.base.file], ['compiler', pc.file]]) {
      report.inputs.push(id(source)); const text = fs.readFileSync(source, 'utf8');
      let tokens = mod.__lex(1, text), tokenCount = 0;
      while (tokens.$ === 'Con') { tokenCount++; tokens = tokens.tail; } assert.equal(tokens.$, 'Nil');
      for (const n of functions) mod.__counts[n] = 0;
      const result = mod.default.f_parse_indexed(1, text); assert.equal(result.error, '');
      const resultHash = sha(JSON.stringify(result));
      assert.equal(resultHash, direct.controls.find(x => x.name === 'full raw ' + name).evidence.sha256);
      const counts = { ...mod.__counts };
      const wrappers = role === 'candidate'
        ? ['f_input', 'f_empty', 'f_prepend', 'f_tl', 'f_skip', 'f_space'].reduce((n, x) => n + counts[x], 0) : 0;
      report.rows.push({ role, name, tokenCount, utf16: text.length, counts,
        wrapperAllocations: wrappers, contextAllocations: role === 'candidate' ? counts.f_input : 0,
        wrappersPerLexedToken: wrappers / tokenCount, resultSha256: resultHash }); save();
    }
    await W.verifyAttempt(path.resolve(directory));
  }
  for (const x of report.inputs) assert.equal(id(x.file).sha256, x.sha256);
  report.complete = true; report.pass = true;
} catch (e) { report.error = String(e.stack ?? e); }
save(); console.log(JSON.stringify(report)); if (!report.pass) process.exitCode = 1;
