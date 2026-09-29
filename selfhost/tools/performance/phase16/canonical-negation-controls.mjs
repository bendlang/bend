import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {verifyAttempt, identity, verifyIdentity} from '../../development/workflow.mjs';

const [baselineArg, candidateArg, outputArg] = process.argv.slice(2);
const out = path.resolve(outputArg);
fs.mkdirSync(out);
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-runner.mjs'));
const baseline = await verifyAttempt(path.resolve(baselineArg));
const candidate = await verifyAttempt(path.resolve(candidateArg));
assert.equal(baseline.config.upstream, candidate.config.upstream);
async function view(attempt, name) {
  const source = fs.readFileSync(attempt.api.file, 'utf8');
  const target = path.join(out, name + '.mjs');
  fs.writeFileSync(target, source + '\nexport const canonicalControl=run_lib((text,ns)=>run_loop($f_fresh_result$(run_loop($f_parse_at$(text,ns)))),2);\n');
  return (await import(pathToFileURL(target))).canonicalControl;
}
const B = await view(baseline, 'baseline'), C = await view(candidate, 'candidate');
const upstream = path.join(candidate.config.upstream, 'bend2/bend.ts');
const U = await import(pathToFileURL(upstream));
const inputs = [import.meta.filename, baseline.api.file, candidate.api.file, upstream, process.execPath].map(identity);
const cases = [
  {name: 'absent-global', source: 'law probe: {Type != Type : Type}\n'},
  {name: 'global-adt', source: 'type Empty is Type:\nlaw probe: {Type != Type : Type}\n'},
  {name: 'global-alias', source: 'def Empty() -> Type: Type\nlaw probe: {Type != Type : Type}\n'},
  {name: 'lexical-shadow', source: 'law probe:\n  for -Empty : Type\n  {Type != Type : Type}\n'},
  {name: 'module-adt', ns: 'module', source: 'type Empty is Type:\nlaw probe: {Type != Type : Type}\n'},
  {name: 'module-alias', ns: 'module', source: 'def Empty() -> Type: Type\nlaw probe: {Type != Type : Type}\n'},
  {name: 'module-and-lexical', ns: 'module', source: 'type Empty is Type:\nlaw probe:\n  for -Empty : Type\n  {Type != Type : Type}\n'},
  {name: 'explicit-lexical', unchanged: true, source: 'law probe:\n  for -Empty : Type\n  Empty\n'},
  {name: 'explicit-module', unchanged: true, ns: 'module', source: 'type Empty is Type:\nlaw probe: Empty\n'},
  {name: 'explicit-global-alias', unchanged: true, source: 'def Empty() -> Type: Type\nlaw probe: Empty\n'},
  {name: 'ordinary-equality', unchanged: true, source: 'law probe: {Type == Type : Type}\n'},
];
const array = xs => {const values=[]; while(xs.$==='Con'){values.push(xs.head);xs=xs.tail;} assert.equal(xs.$,'Nil'); return values;};
const terminalB = t => t.tag === 'All' ? terminalB(array(t.kids)[1]) : {tag:t.tag, name:t.name};
const terminalU = t => t.$ === 'All' ? terminalU(t.B) : t.$ === 'Var' && t.v ? terminalU(t.v) : {tag:t.$, name:t.k??''};
const canonical = t => ({...t, tag:t.tag==='ADT'?'Ref':t.tag});
const marker = x => x && typeof x === 'object' && (x.tag==='FGlobal' || Object.values(x).some(marker));
const report = {kind:'phase16-canonical-reference-controls', complete:false, pass:false, inputs, rows:[], scope:'Parsed, scoped, module-qualified and freshened reference identity; separate paired checking required.'};
const save=()=>fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n'); save();
try {
  for (const test of cases) {
    const ns=test.ns??'', name=ns?ns+'.probe':'probe';
    const before=B(test.source,ns), after=C(test.source,ns);
    const book=U.book_nil(); U.parse_book(book,'',test.source,ns,{});
    assert.equal(before.error,''); assert.equal(after.error,'');
    const a=array(before.book).find(d=>d.name===name), b=array(after.book).find(d=>d.name===name);
    const expected=terminalU(U.term_lower(book.tlds[name].T));
    const row={...test,baseline:terminalB(a.typ),candidate:terminalB(b.typ),reference:expected,pass:false};report.rows.push(row);
    assert(!marker(after));
    assert.deepEqual(canonical(row.candidate),canonical(expected));
    if (test.unchanged) assert.deepEqual(after,before);
    else assert.deepEqual(row.candidate,{tag:'Ref',name:'Empty'});
    row.pass=true;save();
  }
  inputs.forEach(verifyIdentity);report.complete=true;report.pass=true;save();
} catch(e) {report.error=String(e.stack??e);save();process.exitCode=1;}
console.log(JSON.stringify({complete:report.complete,pass:report.pass,cases:report.rows.length,error:report.error}));
