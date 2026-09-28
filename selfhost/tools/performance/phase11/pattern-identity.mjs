import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { pathToFileURL } from 'node:url';

const baseline = path.resolve(process.argv[2]), candidate = path.resolve(process.argv[3]), out = path.resolve(process.argv[4]);
fs.mkdirSync(out);
const modules = [];
for (const [label, file] of [['baseline', baseline], ['candidate', candidate]]) {
  const view = path.join(out, label + '.mjs');
  fs.writeFileSync(view, fs.readFileSync(file, 'utf8') + '\nexport const erase=(b,t,y)=>run_loop($nc_erase_annotated$(b,t,y));\nexport const compact=t=>run_loop($nc_compact$(t));\n');
  modules.push(await import(pathToFileURL(view)));
}
const list = xs => xs.reduceRight((tail, head) => ({ $: 'Con', head, tail }), { $: 'Nil' });
const term = (tag, name = '', kids = [], quant = 0) => ({ $: 'KTerm', tag, name, id: 0, quant, kids: list(kids), removed: list([]) });
const def = (name, kind, native, ctors = [], typ = term('Absent'), arity = 0) => ({ $: 'KDef', name, kind, arity, templates: 0, typ, value: term('Absent'), ctors: list(ctors), native, unsafe: false });
const ty = term('ADT', 'Counter'), tele = term('All', 'n', [ty, ty], 1);
const succ = x => term('Ctr', 'Succ', [x]), variable = term('Var', 'tail');
const collect = t => { const xs = [t]; for (let k = t.kids; k.$ === 'Con'; k = k.tail) xs.push(...collect(k.head)); return xs; };
const rows = [];
for (const native of [false, true]) {
  const book = list([def('Counter', 'ADT', native, [def('Zero', 'Ctr', native, [], ty), def('Succ', 'Ctr', native, [], tele, 1)])]);
  for (const closed of [false, true]) {
    const input = succ(succ(closed ? term('Ctr', 'Zero') : variable));
    const erased = modules.map(m => m.erase(book, input, ty));
    const compact = modules.map((m, i) => m.compact(erased[i]));
    const erasedEqual = JSON.stringify(erased[0]) === JSON.stringify(erased[1]);
    const compactEqual = JSON.stringify(compact[0]) === JSON.stringify(compact[1]);
    const expectedTag = !native ? 'Ctr' : closed ? 'NWord' : 'NNatAdd';
    const userIdentitySafe = native || collect(compact[1]).every(t => t.tag !== 'NNatAdd' && t.tag !== 'NNatSum' && (t.tag !== 'Ctr' || t.name.startsWith('$ctor.')));
    rows.push({ native, closed, erased, compact, erasedEqual, compactEqual, expectedTag, pass: erasedEqual && compact[1].tag === expectedTag && userIdentitySafe && (native && !closed || compactEqual) });
  }
}
for (const arity of [0, 2]) {
  const input = term('Ctr', 'Succ', Array.from({ length: arity }, () => variable));
  const compact = modules.map(m => m.compact(input));
  rows.push({ malformedSuccArity: arity, input, compact, pass: JSON.stringify(compact[0]) === JSON.stringify(compact[1]) && compact[1].tag === 'Ctr' });
}
const identity = file => ({ file, sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') });
const report = { scope: 'Disposable raw checked-image views: exact erasure and user-constructor identity, native versus user-owned same spelling, closed-literal parity, malformed constructor fallback. Does not imply malformed source acceptance.', inputs: [baseline, candidate, import.meta.filename, path.join(out, 'baseline.mjs'), path.join(out, 'candidate.mjs')].map(identity), rows, pass: rows.every(row => row.pass) };
fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({ pass: report.pass, rows: rows.length }));
if (!report.pass) process.exitCode = 1;
