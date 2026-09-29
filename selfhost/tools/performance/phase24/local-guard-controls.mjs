// Private diagnostic wrapper for a genuinely checked candidate; not a release API.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import {pathToFileURL} from 'node:url';

const [apiArgument, outputArgument] = process.argv.slice(2);
assert(apiArgument && outputArgument, 'Usage: local-guard-controls.mjs API NEW_DIRECTORY');
const apiFile = fs.realpathSync(apiArgument), out = path.resolve(outputArgument);
fs.mkdirSync(out);
const identity = file => ({file: fs.realpathSync(file), bytes: fs.statSync(file).size,
  sha256: crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
const report = {kind: 'phase24-local-absence-guard-controls', complete: false, pass: false,
  scope: 'Private unchecked test exports appended to the unchanged checked/derived API. Exact local lookup for producer-consistent states; deliberately inconsistent scope counterexample retained. Not a public conformance or performance gate.',
  inputs: [identity(apiFile), identity(import.meta.filename)], controls: [], property: {states: 0, lookups: 0}};
const save = () => fs.writeFileSync(path.join(out, 'report.json'), JSON.stringify(report, null, 2) + '\n');
fs.copyFileSync(import.meta.filename, path.join(out, 'consumed-tool.mjs')); save();
try {
  const original = fs.readFileSync(apiFile);
  for (const name of ['f_decl_local', 'f_find', 'f_context_declare', 'index_build', 'index_find', 'index_hash', 'f_alias', 'f_qual_name'])
    assert(original.includes(Buffer.from('function $' + name + '$(')), 'Missing compiled helper ' + name);
  const extension = path.join(out, 'private-extension.mjs');
  const suffix = `
export const __local=(name,book,scope)=>run_loop($f_decl_local$(name,book,scope));
export const __linear=(name,book)=>run_loop($f_find$(name,book));
export const __scope=(prior,ns,aliases)=>({$:"FParseScope",prior,index:run_loop($index_build$(run_loop($List$reverse$(prior)))),ctors:run_loop($missing$()),ns,aliases});
export const __publish=(d,scope)=>run_loop($f_context_declare$(d,scope));
export const __mapped=(name,scope)=>{const alias=run_loop($f_alias$(name,scope.aliases));return alias===name?run_loop($f_qual_name$(name,scope.ns)):alias;};
export const __indexed=(name,scope)=>run_loop($index_find$(scope.index,name,run_loop($index_hash$(name,2166136261)),32));
export const __hash=name=>run_loop($index_hash$(name,2166136261));
`;
  fs.writeFileSync(extension, Buffer.concat([original, Buffer.from(suffix)]), {flag: 'wx'});
  assert(fs.readFileSync(extension).subarray(0, original.length).equals(original));
  report.extension = {...identity(extension), originalPrefixBytes: original.length, originalPrefixUnchanged: true};
  const P = await import(pathToFileURL(extension));
  const nil = {$: 'Nil'}, cons = (head, tail) => ({$: 'Con', head, tail});
  const list = values => values.reduceRight((tail, head) => cons(head, tail), nil);
  const term = (tag, name = '', kids = []) => ({$: 'KTerm', tag, name, id: 0, quant: 0,
    kids: list(kids), removed: nil, originBegin: 0, originEnd: 0});
  const def = (name, arity = 0, options = {}) => ({$: 'KDef', name, kind: 'Def', arity,
    templates: arity, typ: term('Typ'), value: term('Absent'), ctors: nil,
    native: false, unsafe: false, ...options});
  const alias = (short, target) => term('Import', target, [term('Alias', short)]);
  const state = (ns = '', aliases = nil, prior = nil) => ({book: nil, scope: P.__scope(prior, ns, aliases)});
  const publish = (s, d) => ({book: cons(d, s.book), scope: P.__publish(d, s.scope)});
  const check = (label, s, name) => {
    const actual = P.__local(name, s.book, s.scope), expected = P.__linear(name, s.book);
    assert.deepEqual(actual, expected, label);
    report.controls.push({name: label, query: name, result: {name: actual.name, kind: actual.kind, arity: actual.arity}, pass: true});
    return actual;
  };
  const empty = state();
  check('empty named missing sentinel', empty, 'missing');
  check('empty name remains missing', empty, '');
  let s = publish(empty, def('old', 1));
  check('new declaration miss after publication', s, 'new');
  check('published local returns raw definition', s, 'old');
  s = publish(s, def('old', 2, {value: term('Rfl')}));
  assert.equal(check('duplicate local first-visible fill wins', s, 'old').arity, 2);
  check('duplicate local missing remains missing', s, 'other');
  const opposite = state('', nil, list([def('same', 1), def('same', 2)]));
  assert.equal(P.__indexed('same', opposite.scope).arity, 2);
  assert.equal(P.__linear('same', opposite.scope.prior).arity, 1);
  check('prior hit never leaks a definition into empty local book', opposite, 'same');
  check('published local overrides opposite initial-prior winners', publish(opposite, def('same', 3)), 'same');
  s = publish(state('module'), def('item', 3));
  assert.equal(P.__mapped('item', s.scope), 'module.item');
  check('namespace publication maps raw name', s, 'item');
  check('qualified query is not raw local membership', s, 'module.item');
  s = publish(state('module'), def('nested.item', 4));
  assert.equal(P.__mapped('nested.item', s.scope), 'module.nested.item');
  check('dotted raw name receives module qualification', s, 'nested.item');
  const imports = list([alias('short', 'dependency')]);
  s = publish(state('module', imports), def('short.item', 5));
  assert.equal(P.__mapped('short.item', s.scope), 'dependency.item');
  check('alias mapping takes precedence over namespace', s, 'short.item');
  check('alias target alone is not raw local membership', s, 'dependency.item');
  let collision = publish(publish(state('', imports), def('short.item', 5)), def('dependency.item', 6));
  check('different raw names can share an indexed alias key first', collision, 'short.item');
  check('different raw names can share an indexed alias key second', collision, 'dependency.item');
  s = state();
  s.scope = P.__publish(def('self', 2), s.scope);
  check('temporary self header gives harmless false positive', s, 'self');
  s = publish(state(), def('Family', 1, {kind: 'ADT', ctors: list([def('Make', 0, {kind: 'Ctr'})])}));
  check('constructor child is not a top-level local entry', s, 'Make');
  check('datatype top-level header is present', s, 'Family');
  assert.equal(P.__hash('costarring'), P.__hash('liquid'));
  s = publish(publish(state(), def('costarring', 7)), def('liquid', 8));
  check('full hash collision retains first name', s, 'costarring');
  check('full hash collision retains second name', s, 'liquid');
  check('full hash collision does not invent absent name', s, 'missing');

  // Model the actual publication transition; this also covers invalid duplicates
  // conservatively, without assuming the parser would accept their source text.
  const events = [def('plain', 1), def('short.item', 2), def('plain', 3, {value: term('Rfl')}),
    def('dependency.item', 4), def('Type', 2, {kind: 'ADT'}), def('costarring', 5), def('liquid', 6)];
  const queries = ['', 'plain', 'short.item', 'dependency.item', 'Type', 'costarring', 'liquid', 'absent', 'mod.plain'];
  for (const ns of ['', 'mod', 'nested.module']) for (const aliases of [nil, imports, list([alias('short', 'other.target'), alias('unused', 'dep')])]) {
    let current = state(ns, aliases, list([def('prior', 8), def('prior', 9), def('plain', 10)]));
    for (const d of events) {
      current = publish(current, d); report.property.states++;
      for (const name of queries) {
        assert.deepEqual(P.__local(name, current.book, current.scope), P.__linear(name, current.book));
        report.property.lookups++;
      }
      for (let xs = current.book; xs.$ === 'Con'; xs = xs.tail)
        assert.notEqual(P.__indexed(P.__mapped(xs.head.name, current.scope), current.scope).kind, 'Absent');
    }
  }
  const inconsistent = {book: list([def('lost', 99)]), scope: empty.scope};
  assert.notDeepEqual(P.__local('lost', inconsistent.book, inconsistent.scope), P.__linear('lost', inconsistent.book));
  report.outOfDomainCounterexample = {name: 'nonempty local book with missing scope index', retained: true,
    linearKind: P.__linear('lost', inconsistent.book).kind,
    guardedKind: P.__local('lost', inconsistent.book, inconsistent.scope).kind,
    meaning: 'The helper depends on the parser publication invariant; arbitrary inconsistent private states are not equivalent.'};
  for (const item of report.inputs) assert.deepEqual(identity(item.file), item);
  report.complete = true; report.pass = true;
} catch (error) { report.error = String(error.stack ?? error); process.exitCode = 1; }
save();
console.log(JSON.stringify({complete: report.complete, pass: report.pass, controls: report.controls.length,
  property: report.property, counterexampleRetained: report.outOfDomainCounterexample?.retained, error: report.error}));
