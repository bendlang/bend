// P13-006: permit unchanged single local constants; preserve selector/body boundaries.
import assert from 'node:assert/strict';
import {moduleView, guardBindings, sha, runtimeHash} from './rewriter-structure.mjs';
import {transform as version5} from './rewriter-v5.mjs';

export function lowerSelectors(source, options) {
  assert.deepEqual(Object.keys(options), ['families']);
  assert.ok(Array.isArray(options.families) && options.families.length);
  assert.equal(new Set(options.families).size, options.families.length);
  const view = moduleView(source), {ts, functions} = view;
  // v5 already guarded the original generated bindings. Its leaf packets now
  // legitimately contain bare function references; guard this pass's dependencies.
  guardBindings(view, new Set(['$tg$', '$String$eq$', 'run_tail', 'run_loop', 'run_clo', 'run_lib']), {lexical: true});
  const tg = 'function $tg$(_t_0) {\n  const _tag_0 = _t_0["tag"];\n  return _tag_0;\n}';
  const eq = 'function $String$eq$(_a_0, _b_0) {\n  if (typeof _a_0 === "string" && typeof _b_0 === "string") return _a_0 === _b_0;\n  return $String$eq$fin$(($String$cmp$(_a_0, _b_0)));\n}';
  assert.equal(functions.get('$tg$')?.source, tg, 'Unsupported tag accessor');
  assert.equal(functions.get('$String$eq$')?.source, eq, 'Unsupported string equality');
  const tagTest = (range, parameters) => {
    const c = view.call(range);
    if (!c || c.callee !== '$String$eq$' || c.args.length !== 2) return false;
    const tag = view.call(c.args[0]), literal = view.strip(c.args[1]);
    if (!tag || tag.callee !== '$tg$' || tag.args.length !== 1) return false;
    const value = view.strip(tag.args[0]);
    return value[1] === value[0] + 1 && parameters.has(ts[value[0]].text) &&
      literal[1] === literal[0] + 1 && /^"[A-Za-z][A-Za-z0-9_]*"$/.test(ts[literal[0]].text);
  };
  const sites = new Map(), skipped = [], constants = [];
  for (const name of options.families) {
    const owner = functions.get(name);
    assert.ok(owner, 'Unknown selected owner: ' + name);
    const parameters = new Set(view.split(owner.params).map(([lo, hi]) => {
      assert.ok(hi === lo + 1 && /^[A-Za-z_$][\w$]*$/.test(ts[lo].text), 'Unsupported owner parameter');
      return ts[lo].text;
    }));
    // Constants stay in their original block; only their own initializer equals
    // token is exempt. The loop still visits every initializer token.
    const initializers = new Set();
    for (let i = owner.body + 1; i < owner.end; i++) {
      const t = ts[i].text, prev = ts[i - 1]?.text, next = ts[i + 1]?.text;
      if (t === 'const') {
        assert.ok(/^[A-Za-z_$][\w$]*$/.test(next ?? '') && ts[i + 2]?.text === '=', 'Only single simple initialized const is admitted');
        assert.ok(!parameters.has(next), 'Const shadows owner parameter');
        const end = view.semicolon(i + 3, owner.end);
        assert.ok(end > i + 3, 'Const initializer or semicolon is missing');
        for (let j = i + 3; j < end; j++) {
          if (ts[j].close !== undefined) { j = ts[j].close; continue; }
          assert.notEqual(ts[j].text, ',', 'Multiple const declarators are unsupported');
        }
        initializers.add(i + 2);
        constants.push({owner: name, name: next, at: ts[i].start, initializerAt: ts[i + 2].start, end: ts[end].end});
      }
      if (t === '=' && next === '>') assert.equal(prev, ')', 'Unparenthesized arrow in selected owner');
      if (t === '(' && ts[ts[i].close + 1]?.text === '=' && ts[ts[i].close + 2]?.text === '>') {
        const body = ts[i].close + 3, arrow = view.arrow([i, ts[body]?.close + 1]);
        assert.ok(arrow && !parameters.has(arrow.param), 'Unsupported or shadowing arrow parameter');
      }
      assert.ok(!['let', 'var', 'function', 'class', 'delete', 'for', 'while', 'do', 'switch', 'catch'].includes(t), 'Unsupported selected-owner scope');
      const equality = prev === '=' || next === '=' || prev === '!';
      const comparison = ['<', '>'].includes(prev) && ts[i - 2]?.text !== prev;
      const arrow = prev === ')' && next === '>';
      assert.ok(t !== '=' || initializers.has(i) || equality || comparison || arrow, 'Write in selected owner');
      assert.ok(!(['+', '-'].includes(t) && next === t), 'Increment/decrement in selected owner');
    }
    for (let i = owner.body + 1; i < owner.end; i++) {
      const parent = view.returnedChoice(i);
      if (!parent) continue;
      const yes = view.arrow(parent.yes, {unwrap: true}), no = view.arrow(parent.no, {unwrap: true});
      assert.ok(yes && no, 'Returned choice lacks literal branches');
      const child = view.returnedChoice(no.body + 1);
      let reason;
      if (!child || child.end !== no.end) reason = 'False branch is not exactly one returned choice';
      else if (ts.slice(no.body + 1, no.end).some(t => t.text === no.param)) reason = 'Discarded Unit binding occurs in the branch';
      else if (!tagTest(child.condition, parameters)) reason = 'Nested condition is not the admitted parameter tag test';
      else if (!view.arrow(child.yes, {unwrap: true}) || !view.arrow(child.no, {unwrap: true})) reason = 'Nested choice lacks literal branches';
      if (reason) { skipped.push({owner: name, at: ts[i].start, reason}); continue; }
      sites.set(i, {...parent, owner: name, child, discardedUnit: no.param});
    }
  }
  assert.ok(sites.size, 'No eligible intermediate selectors');
  const chain = (choice, render) => {
    const site = sites.get(choice.first);
    const yes = render(...choice.yes);
    const no = site ? chain(site.child, render) : render(...choice.no);
    return '(' + render(...choice.condition) + ') ? (' + yes + ') : (' + no + ')';
  };
  const program = view.program(sites, (site, render) =>
    'return run_tail(' + chain(site, render) + ', {$: "Unit"});');
  const outputView = moduleView(program);
  assert.equal(program.slice(0, outputView.start), source.slice(0, view.start));
  assert.equal(program.slice(outputView.ts[outputView.end].start), source.slice(ts[view.end].start), 'Public export bytes changed');
  for (const [name, original] of functions) if (!options.families.includes(name))
    assert.equal(outputView.functions.get(name)?.source, original.source, 'Unselected owner changed: ' + name);
  return {source: program, report: {kind: 'phase13-constant-scope-tag-selector-fusion', version: 1,
    inputSha256: sha(source), outputSha256: sha(program), runtimeSha256: runtimeHash, options,
    removedIntermediateSelectors: sites.size,
    sites: [...sites.values()].map(s => ({owner: s.owner, at: ts[s.first].start, childAt: ts[s.child.first].start, discardedUnit: s.discardedUnit})),
    constants, skipped, protectedBodies: ['$tg$', '$String$eq$'].map(name => ({name, sha256: sha(functions.get(name).source)})),
    scope: 'Fuse only unused-Unit false arrows containing one returned literal choice with a nested tag test; permit unchanged single simple const declarations without owner-parameter shadowing. Preserve order, selected body arrows, runtime and public exports. No generic stack-equivalence claim.'}};
}

export function transform(source, options) {
  const baseline = version5(source, {version: 5});
  const result = lowerSelectors(baseline.source, options);
  return {source: result.source, report: {...result.report,
    checkedInputSha256: sha(source), baselineStats: baseline.stats}};
}
