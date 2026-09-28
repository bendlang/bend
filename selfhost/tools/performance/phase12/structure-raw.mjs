import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

const baseline = path.resolve(process.argv[2]), candidate = path.resolve(process.argv[3]), out = path.resolve(process.argv[4]); fs.mkdirSync(out);
const modules = [];
for (const [label, file] of [['baseline', baseline], ['candidate', candidate]]) {
  const view = path.join(out, label + '.mjs');
  const lookup = label === 'baseline' ? '$j_find_ctor$(b,n)' : '$j_layout_ctor$(b,t,n)';
  fs.writeFileSync(view, fs.readFileSync(file, 'utf8') + `\nexport const lookup=(b,t,n)=>run_loop(${lookup});\nexport const mode=(b,t,y,z)=>run_loop($j_constructor_mode$(b,{$:'Nil'},t,y,z));\n`);
  modules.push(await import(pathToFileURL(view)));
}
const list = xs => xs.reduceRight((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
const term = (tag, name = '', kids = []) => ({ $: 'KTerm', tag, name, id: 0, quant: 1, kids: list(kids), removed: list([]) });
const def = (name, kind, typ = term('Typ'), ctors = [], native = false) => ({ $: 'KDef', name, kind, arity: 0, templates: 0, typ, value: term('Absent'), ctors: list(ctors), native, unsafe: false });
const a = def('Make', 'Ctr', term('ADT', 'A')), b = def('Other', 'Ctr', term('ADT', 'B'));
const book = list([def('A', 'ADT', term('Typ'), [a]), def('B', 'ADT', term('Typ'), [b])]);
const cases = [['local', book, term('ADT', 'A'), 'Make'], ['other-family', book, term('ADT', 'B'), 'Make'], ['missing-family', book, term('ADT', 'Missing'), 'Make'], ['metatype', book, term('Typ', 'A'), 'Make'], ['missing-constructor', book, term('ADT', 'A'), 'Absent'], ['empty-book', list([]), term('ADT', 'A'), 'Make']];
cases.push(['unchecked-duplicate', list([def('Wrong', 'ADT', term('Typ'), [def('Make', 'Ctr', term('ADT', 'Wrong'))]), def('A', 'ADT', term('Typ'), [a])]), term('ADT', 'A'), 'Make']);
const rows = cases.map(([name, book, type, constructor]) => {
  const values = modules.map(m => m.lookup(book, type, constructor));
  const equal = JSON.stringify(values[0]) === JSON.stringify(values[1]);
  return { name, book, type, constructor, values, equal, expectedEqual: name !== 'unchecked-duplicate', pass: equal === (name !== 'unchecked-duplicate') };
});
const native = list([def('Nat', 'ADT', term('Typ'), [], true)]), ty = term('ADT', 'Nat');
const observations = [];
for (const input of [term('Ctr', 'Zero'), term('Ctr', 'Zero', [term('Hol')]), term('Ctr', 'Succ', [term('Ctr', 'Zero')]), term('Ctr', 'Succ', [term('Ctr', 'Zero'), term('Hol')]), term('Ctr', 'U32'), null]) {
  for (const tail of [false, true]) {
    const results = modules.map(m => { try { return { value: m.mode(native, input, ty, tail) }; } catch (error) { return { error: error.message, kind: error.constructor.name }; } });
    observations.push({ input, tail, results, pass: JSON.stringify(results[0]) === JSON.stringify(results[1]) });
  }
}
const identity = file => ({ file, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') });
const report = { scope: 'Finite raw helper controls and preserved errors. Forged duplicate ownership deliberately differs; no arbitrary reflective/raw-JS equivalence claim.', inputs: [baseline, candidate, import.meta.filename, path.join(out, 'baseline.mjs'), path.join(out, 'candidate.mjs')].map(identity), rows, observations, pass: rows.every(row => row.pass) && observations.every(row => row.pass) };
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n'); console.log(JSON.stringify({ pass: report.pass, lookupRows: rows.length, emissionRows: observations.length })); if (!report.pass) process.exitCode = 1;
