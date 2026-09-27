import fs from 'node:fs';
import assert from 'node:assert/strict';
import {pathToFileURL} from 'node:url';
import {spawnSync} from 'node:child_process';
import path from 'node:path';

const {default: K} = await import(pathToFileURL(process.argv[2]));
const nil = {$: 'Nil'};
const list = xs => xs.reduceRight((tail, head) => ({$: 'Con', head, tail}), nil);
const term = (tag, name = '', id = 0, quant = 0, kids = [], removed = []) => ({$: 'KTerm', tag, name, id, quant, kids: list(kids), removed: list(removed)});
const variable = id => term('Var', 'x', id);
const ref = name => term('Ref', name);
const ctr = (name, ...kids) => term('Ctr', name, 0, 0, kids);
const lam = (id, body, q = 1) => term('Lam', 'x', id, q, [body]);
const all = (id, domain, body, q = 1) => term('All', 'x', id, q, [domain, body]);
const app = (fn, arg) => term('App', '', 0, 0, [fn, arg]);
const bind = (id, value) => term('Bind', 'x', id, 1, [value]);
const let_ = (bindings, body) => term('Let', '', 0, 1, [...bindings, body]);
const qua = q => term('Qua', '', 0, q);
const type = q => term('Typ', '', 0, 0, [qua(q)]);
const A = ctr('A'), B = ctr('B'), identity = lam(1, variable(1));
const rows = [];
const record = (name, action, detail = {}) => {
  try { action(); rows.push({name, pass: true, ...detail}); }
  catch (error) { rows.push({name, pass: false, error: error.stack, ...detail}); }
};

// Compare presentation metadata as well as semantic equality, while factoring
// out the deliberately fresh binder numbers in independently quoted terms.
const array = xs => { const out = []; for (; xs.$ === 'Con'; xs = xs.tail) out.push(xs.head); return out; };
const canonical = (t, env = new Map(), depth = 0) => {
  const children = array(t.kids);
  if (t.tag === 'Lam' || t.tag === 'All') {
    const next = new Map(env); next.set(t.id, depth);
    return {tag: t.tag, name: t.name, id: depth, quant: t.quant, removed: array(t.removed),
      kids: t.tag === 'Lam' ? [canonical(children[0], next, depth + 1)]
        : [canonical(children[0], env, depth + 1), canonical(children[1], next, depth + 1)]};
  }
  return {tag: t.tag, name: t.name, id: t.tag === 'Var' && env.has(t.id) ? env.get(t.id) : t.id,
    quant: t.quant, removed: array(t.removed), kids: children.map(child => canonical(child, env, depth + 1))};
};

const normalizations = [
  ['constructor', A],
  ['identity beta', app(identity, A)],
  ['open variable', variable(12)],
  ['opaque reference', ref('opaque')],
  ['opaque application spine', app(app(ref('opaque'), A), B)],
  ['closure capture', app(lam(2, lam(3, ctr('Pair', variable(2), variable(3)))), A)],
  ['normalization under lambda', lam(4, app(identity, variable(4)))],
  ['dependent telescope', all(5, type(2), all(6, variable(5), app(identity, variable(6))))],
  ['parallel let', let_([bind(7, A), bind(8, B)], ctr('Pair', variable(7), variable(8)))],
  ['parallel let RHS outer scope', app(lam(9, let_([bind(7, A), bind(8, variable(9))], ctr('Pair', variable(7), variable(8)))), B)],
  ['parallel let RHS does not see sibling', let_([bind(7, A), bind(8, variable(7))], variable(8))],
  ['nested let', let_([bind(7, A)], let_([bind(8, variable(7))], variable(8)))],
  ['legacy shared variable payload', term('Var', 'cell', 20, 0, [app(identity, A)])],
  ['annotation', term('Ann', '', 0, 0, [app(identity, A), type(2)])],
  ['equality data', term('Eql', '', 0, 0, [app(identity, A), A, type(2)])],
  ['constructor field closure', ctr('Wrap', lam(21, app(identity, variable(21))))],
  ['quantity', qua(2)],
  ['erased dependent function', all(22, type(2), variable(22), 0)],
  ['applied inert All preserves spine', app(all(23, type(2), variable(23)), A)],
  ['nested textual shadowing', lam(80, lam(81, ctr('Pair', variable(80), variable(81))))],
  ['fresh opening avoids high free identifier', lam(82, ctr('Pair', variable(82), variable(1000000)))],
  ['capture after beta under telescope', app(lam(83, all(84, type(2), ctr('Pair', variable(83), variable(84)))), variable(85))],
  ['dependent domain contains binder', all(86, lam(87, variable(87)), variable(86))],
];

for (const [name, input] of normalizations) {
  record('normalization: ' + name, () => {
    const before = JSON.stringify(input);
    const observed = K.sv_observe(input);
    assert.equal(observed.supported, true);
    const expected = K.strong(nil, input);
    assert.equal(K.compare(nil, observed.term, expected, false), true);
    assert.equal(JSON.stringify(input), before, 'input mutation');
  });
}

for (const [name, input] of normalizations) {
  record('quotation metadata modulo binder IDs: ' + name, () => {
    assert.deepEqual(canonical(K.sv_observe(input).term), canonical(K.strong(nil, input)));
  });
}

const equalities = [
  ['alpha', lam(30, variable(30)), lam(31, variable(31)), true],
  ['eta', lam(32, app(ref('f'), variable(32))), ref('f'), true],
  ['nested eta', ctr('Wrap', lam(33, app(ref('f'), variable(33)))), ctr('Wrap', ref('f')), true],
  ['dependent alpha', all(34, type(2), variable(34)), all(35, type(2), variable(35)), true],
  ['dependent alpha with outer', all(36, type(2), all(37, variable(36), variable(37))), all(38, type(2), all(39, variable(38), variable(39))), true],
  ['different constructor', A, B, false],
  ['different opaque reference', ref('f'), ref('g'), false],
  ['different free variable', variable(40), variable(41), false],
  ['different quantity', qua(1), qua(2), false],
  ['different binder quantity', all(42, type(2), A, 0), all(43, type(2), A, 1), false],
  ['different field', ctr('Pair', A, A), ctr('Pair', A, B), false],
  ['different arity', app(ref('f'), A), ref('f'), false],
  ['beta', app(identity, A), A, true],
  ['All neutral args', app(all(44, type(2), variable(44)), A), app(all(45, type(2), variable(45)), B), false],
  ['nested textual shadowing alpha', lam(90, lam(91, ctr('Pair', variable(90), variable(91)))), lam(92, lam(93, ctr('Pair', variable(92), variable(93)))), true],
  ['nested textual shadowing swapped', lam(94, lam(95, ctr('Pair', variable(94), variable(95)))), lam(96, lam(97, ctr('Pair', variable(97), variable(96)))), false],
  ['neutral spine alpha', lam(98, app(app(ref('f'), variable(98)), A)), lam(99, app(app(ref('f'), variable(99)), A)), true],
  ['neutral spine order', app(app(ref('f'), A), B), app(app(ref('f'), B), A), false],
];
for (const [name, a, b, expected] of equalities) {
  record('conversion: ' + name, () => {
    assert.equal(K.sv_supported(a) && K.sv_supported(b), true);
    assert.equal(K.compare(nil, a, b, false), expected, 'old Bend oracle');
    assert.equal(K.sv_equal(a, b), expected, 'semantic value conversion');
  });
}

// These terms intentionally probe evaluation demand, not Bend typing acceptance.
const omega = app(lam(50, app(variable(50), variable(50))), lam(52, app(variable(52), variable(52))));
record('unused divergent argument remains unforced', () => {
  const input = app(lam(51, A), omega);
  const observed = K.sv_observe(input);
  assert.equal(observed.term.name, 'A');
  assert.equal(K.wnf(nil, input).name, 'A');
  assert.ok(observed.steps < 10);
});
record('weak head leaves divergent constructor field unforced', () => {
  const input = ctr('Wrap', omega);
  const observed = K.sv_observe_head(input);
  assert.equal(observed.term.name, 'Wrap');
  assert.equal(K.wnf(nil, input).name, 'Wrap');
  assert.equal(observed.steps, 1);
});

let computation = A;
for (let i = 0; i < 24; i++) computation = app(lam(100 + i, variable(100 + i)), computation);
const sharing = [];
for (const copies of [1, 2, 4, 8, 32, 128]) {
  const input = app(lam(60, ctr('Pack', ...Array(copies).fill(variable(60)))), computation);
  const observed = K.sv_observe(input);
  sharing.push({copies, steps: observed.steps, hits: observed.hits, cells: observed.cells});
  record('shared argument: ' + copies + ' demands', () => {
    assert.equal(K.compare(nil, observed.term, K.strong(nil, input), false), true);
    assert.ok(observed.hits >= copies - 1);
  });
}
record('extra demands do not reevaluate delayed argument', () => {
  const first = sharing[0];
  for (const row of sharing) assert.equal(row.steps - first.steps, row.copies - first.copies);
});

// Fields of a memoized constructor are cells too, so demanding the same shared
// constructor twice does not reevaluate an expensive child.
const nestedSharing = app(lam(61, ctr('Pair', variable(61), variable(61))), ctr('Wrap', computation));
record('shared constructor fields retain memoized computation', () => {
  const observed = K.sv_observe(nestedSharing);
  assert.equal(K.compare(nil, observed.term, K.strong(nil, nestedSharing), false), true);
  assert.ok(observed.steps < 100);
  assert.ok(observed.hits >= 2);
});

const deep = [];
for (const depth of [100, 1000, 5000]) {
  let input = A;
  for (let i = 0; i < depth; i++) input = ctr('Succ', input);
  const old = K.strong(nil, input);
  let oldDepth = 0, cursor = old;
  while (cursor.name === 'Succ') { oldDepth++; cursor = cursor.kids.head; }
  try {
    const observed = K.sv_observe(input);
    let actual = 0; cursor = observed.term;
    while (cursor.name === 'Succ') { actual++; cursor = cursor.kids.head; }
    deep.push({depth, oldDepth, prototypeDepth: actual, pass: actual === oldDepth});
  } catch (error) {
    deep.push({depth, oldDepth, pass: false, error: error.name + ': ' + error.message});
  }
}

const demandWitnesses = [];
for (const [name, expected] of [['early-mismatch', false], ['reflexivity', true], ['wrapped-reflexivity', true], ['nested-reflexivity', true], ['constructor-arity', false], ['neutral-arity', false]]) for (const mode of ['old', 'new']) {
  const args = ['--stack-size=4096', '--max-old-space-size=512', path.join(import.meta.dirname, 'demand-witness.mjs'), process.argv[2], mode, name];
  const child = spawnSync(process.execPath, args, {encoding: 'utf8', timeout: 2000, maxBuffer: 1024 * 1024});
  demandWitnesses.push({name, mode, command: process.execPath, args, exitCode: child.status, signal: child.signal,
    error: child.error?.message || null, stdout: child.stdout, stderr: child.stderr});
  record('conversion demand: ' + name + ' (' + mode + ')', () => {
    assert.equal(child.status, 0, child.error?.message || child.stderr || 'child did not complete');
    assert.equal(JSON.parse(child.stdout).result, expected);
  });
}

const unsupported = [
  ['match', term('Mat', 'A', 0, 0, [A, term('Efq')])],
  ['rewrite', term('Rwt', '', 0, 0, [term('Rfl'), A, A])],
  ['quantity meet', term('Min', '', 0, 0, [qua(1), qua(2)])],
  ['residual datatype', term('ADT', 'D', 0, 0, [], ['A'])],
  ['malformed lambda', term('Lam')],
  ['empty let', term('Let')],
  ['standalone binding', bind(70, A)],
  ['reserved binder identifier', variable(2147483648)],
  ['malformed Ref children', term('Ref', 'f', 0, 0, [A])],
  ['malformed Rfl children', term('Rfl', '', 0, 0, [A])],
  ['malformed Qnt children', term('Qnt', '', 0, 0, [A])],
  ['malformed Qua children', term('Qua', '', 0, 1, [A])],
  ['malformed Typ arity', term('Typ')],
  ['malformed Eql arity', term('Eql', '', 0, 0, [A])],
];
for (const [name, input] of unsupported) {
  record('explicit unsupported boundary: ' + name, () => {
    assert.equal(K.sv_supported(input), false);
    assert.equal(K.sv_observe(input).supported, false);
    assert.equal(K.sv_observe(input).term.tag, 'Error');
  }, {scope: 'rejected by slice, not a conformance pass for this construct'});
}

const report = {
  kind: 'P7-A02 checked component controls', generated: new Date().toISOString(),
  scope: 'Empty book, explicit first-order closures, exact conversion, limited supported grammar',
  notEstablished: ['Whole compiler correctness or speed', 'Definition unfolding', 'Match/rewrite/Min', 'Kind subtyping', 'Stack safety', 'Self-hosting'],
  pass: rows.every(row => row.pass), total: rows.length, passed: rows.filter(row => row.pass).length,
  sharing, demandWitnesses, deepQuotation: {scope: 'exploratory requirement; excluded from slice pass, failures remain explicit', rows: deep}, rows,
};
fs.writeFileSync(process.argv[3], JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify({pass: report.pass, total: report.total, passed: report.passed, sharing}));
for (const row of rows.filter(row => !row.pass)) console.error(row.name + '\n' + row.error);
if (!report.pass) process.exitCode = 1;
