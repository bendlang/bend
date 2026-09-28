// First pilot: immutable parameter captures in selected generated owners.
import assert from 'node:assert/strict';
import {moduleView, sha, runtimeHash} from './rewriter-structure.mjs';
import {transform as version5} from './rewriter-v5.mjs';

const identifier = text => /^[A-Za-z_$][\w$]*$/.test(text ?? '');
const keywords = new Set(['return', 'if', 'else', 'true', 'false', 'null', 'undefined', 'typeof', 'void']);
const runtimeNames = new Set(['run_tail', 'run_loop', 'run_clo', 'run_lib']);

export function analyzeOwner(view, name) {
  const {ts, functions} = view, owner = functions.get(name);
  assert.ok(owner, 'Unknown selected owner: ' + name);
  const params = view.split(owner.params).map(([lo, hi]) => {
    assert.ok(hi === lo + 1 && identifier(ts[lo].text), 'Unsupported owner parameter');
    return {name: ts[lo].text, token: lo};
  });
  assert.equal(new Set(params.map(p => p.name)).size, params.length, 'Duplicate owner parameter');
  const root = {start: owner.body, end: owner.end, parent: null, bindings: new Map()};
  for (const p of params) root.bindings.set(p.name, {...p, scope: root});
  const scopes = [root], arrows = new Map();
  for (let i = owner.body + 1; i < owner.end; i++) {
    const t = ts[i].text, prev = ts[i - 1]?.text, next = ts[i + 1]?.text;
    assert.ok(!['const', 'let', 'var', 'function'].includes(t), 'Initial owner domain excludes declarations');
    assert.ok(!(t === '=' && !['=', '!', '<', '>'].includes(prev) && !['=', '>'].includes(next)), 'Binding or member write');
    assert.ok(!(['+', '-'].includes(t) && next === t), 'Increment/decrement write');
    if (t !== '(' || ts[ts[i].close + 1]?.text !== '=' || ts[ts[i].close + 2]?.text !== '>') continue;
    const body = ts[i].close + 3;
    assert.equal(ts[body]?.text, '{', 'Only block arrow bodies are admitted');
    const arrow = view.arrow([i, ts[body].close + 1]);
    assert.ok(arrow, 'Only one simple arrow parameter is admitted');
    const parent = scopes.filter(s => s.start < i && s.end > arrow.end).at(-1);
    assert.ok(parent, 'Arrow outside lexical owner');
    const scope = {start: arrow.body, end: arrow.end, parent, bindings: new Map(), arrow};
    scope.bindings.set(arrow.param, {name: arrow.param, token: arrow.paramToken, scope});
    scopes.push(scope); arrows.set(arrow.body, scope);
  }
  const containing = index => scopes.filter(s => s.start < index && index < s.end).at(-1);
  const resolve = (name, scope) => {
    for (let s = scope; s; s = s.parent) if (s.bindings.has(name)) return s.bindings.get(name);
    return null;
  };
  const bindingTokens = new Set(scopes.flatMap(s => [...s.bindings.values()].map(b => b.token)));
  const references = [];
  for (let i = owner.body + 1; i < owner.end; i++) {
    const t = ts[i].text;
    if (!identifier(t) || bindingTokens.has(i) || keywords.has(t)) continue;
    if (ts[i - 1]?.text === '.') continue;
    if (t === '$' && ts[i + 1]?.text === ':' && ['{', ','].includes(ts[i - 1]?.text)) continue;
    if (functions.has(t) || runtimeNames.has(t)) continue;
    const binding = resolve(t, containing(i));
    assert.ok(binding, 'Unresolved/unsupported identifier: ' + t);
    references.push({token: i, binding});
  }
  const sites = [];
  for (let i = owner.body + 1; i < owner.end; i++) {
    const site = view.returnedChoice(i);
    if (!site) continue;
    const branches = ['yes', 'no'].map(which => {
      const arrow = view.arrow(site[which], {unwrap: true});
      assert.ok(arrow, 'Selected choice lacks literal branch');
      const scope = arrows.get(arrow.body);
      assert.ok(scope, 'Missing branch scope');
      const captures = new Map();
      for (const r of references) {
        if (r.token <= scope.start || r.token >= scope.end) continue;
        // A reference bound in this branch or its descendants stays local.
        if (r.binding.scope.start >= scope.start && r.binding.scope.end <= scope.end) continue;
        captures.set(r.binding.token, r.binding);
      }
      const captured = [...captures.values()];
      assert.equal(new Set(captured.map(c => c.name)).size, captured.length, 'Ambiguous capture spelling');
      assert.ok(!captured.some(c => c.name === arrow.param), 'Capture shadows Unit binding');
      return {...arrow, captures: captured.map(c => ({name: c.name, declarationToken: c.token}))};
    });
    sites.push({...site, owner: name, yes: branches[0], no: branches[1]});
  }
  return {owner, scopes: scopes.length, sites};
}

export function transform(source, options) {
  assert.deepEqual(Object.keys(options), ['families']);
  assert.ok(Array.isArray(options.families) && options.families.length > 0);
  assert.equal(new Set(options.families).size, options.families.length);
  const baseline = version5(source, {version: 5});
  const view = moduleView(baseline.source), {ts} = view;
  const analyzed = options.families.map(name => analyzeOwner(view, name));
  const sites = new Map(), workers = [], allSpellings = new Set(ts.filter(t => identifier(t.text)).map(t => t.text));
  for (const owner of analyzed) for (const site of owner.sites) {
    for (const which of ['yes', 'no']) {
      const branch = site[which], name = '$p13_worker_' + workers.length + '$';
      assert.ok(!allSpellings.has(name), 'Worker name collision: ' + name);
      allSpellings.add(name); branch.worker = name;
      workers.push({name, owner: site.owner, branch, siteAt: ts[site.first].start});
    }
    sites.set(site.first, site);
  }
  assert.ok(sites.size > 0, 'No eligible branch choices');
  const packet = b => '{$: "$JMP", f: ' + b.worker + ', x: [{$: "Unit"}' +
    b.captures.map(c => ', ' + c.name).join('') + ']}';
  const replacement = (site, render) => 'return (' + render(...site.condition) + ') ? ' + packet(site.yes) + ' : ' + packet(site.no) + ';';
  const workerBody = b => baseline.source.slice(ts[b.body].end, ts[b.body + 1].start) +
    view.render(b.body + 1, b.end, sites, replacement) + baseline.source.slice(ts[b.end - 1].end, ts[b.end].start);
  const definitions = workers.map(w => 'function ' + w.name + '(' +
    [w.branch.param, ...w.branch.captures.map(c => c.name)].join(', ') + ') {' + workerBody(w.branch) + '}').join('\n\n') + '\n\n';
  // Replace the export keyword token with definitions followed by that exact token.
  sites.set(view.end, {end: view.end + 1, insertion: true});
  const program = view.program(sites, (site, render) => site.insertion ? definitions + 'export' : replacement(site, render));
  assert.equal(program.slice(0, view.start), baseline.source.slice(0, view.start));
  const outputView = moduleView(program);
  assert.equal(program.slice(outputView.ts[outputView.end].start), baseline.source.slice(ts[view.end].start), 'Public export bytes changed');
  return {source: program, report: {kind: 'phase13-literal-branch-workers', version: 1,
    inputSha256: sha(source), baselineSha256: sha(baseline.source), outputSha256: sha(program), runtimeSha256: runtimeHash,
    options, baselineStats: baseline.stats, sites: sites.size - 1, workers: workers.map(w => ({name: w.name, owner: w.owner,
      siteAt: w.siteAt, unit: w.branch.param, captures: w.branch.captures})),
    staticCaptureElements: workers.reduce((n, w) => n + w.branch.captures.length, 0),
    scope: 'Only selected immutable-parameter owners without declarations or writes; named workers retain original branch bodies and existing multiargJMP execution boundary. No bootstrap or stack-safety claim.'}};
}
