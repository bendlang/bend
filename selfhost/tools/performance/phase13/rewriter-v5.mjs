// Experimental shared structural implementation; frozen maintained scalar guards.
import assert from 'node:assert/strict';
import {transformEquality} from '../../../build/phase12/integrated-03/snapshot/tools/development/equality.mjs';
import {moduleView, guardBindings, sha, runtimeHash} from './rewriter-structure.mjs';

function choiceBody(name) {
  return `function ${name}(_b_0, _yes_0, _no_0) {\n  if (_b_0) {\n    return run_tail(_yes_0, {$: "Unit"});\n  } else {\n    return run_tail(_no_0, {$: "Unit"});\n  }\n}`;
}
export function lowerChoices(source, native = true) {
  const view = moduleView(source), {ts, functions} = view;
  const names = new Set(native ? ['$kc$', '$f_choose$', '$nt_choose$'] : ['$kc$', '$f_choose$']);
  for (const name of names) assert.equal(functions.get(name)?.source, choiceBody(name), 'Unsupported choice body: ' + name);
  guardBindings(view, new Set([...names, 'run_clo', 'run_tail', 'run_loop']));
  const sites = new Map(), skipped = [];
  for (let i = 0; i < view.end; i++) {
    if (!names.has(ts[i].text) || ts[i - 1]?.text === 'function' || ts[i + 1]?.text !== '(') continue;
    const end = ts[i + 1].close, args = view.split(i + 1);
    const yes = args.length === 3 ? view.arrow(args[1], {wrapped: true}) : null;
    const no = args.length === 3 ? view.arrow(args[2], {wrapped: true}) : null;
    if (yes && no) sites.set(i, {end: end + 1, args, yes, no});
    else skipped.push({at: ts[i].start, name: ts[i].text, argumentCount: args.length});
  }
  const program = view.program(sites, (s, render) => 'run_tail((' + render(...s.args[0]) + ') ? (' +
    render(...s.yes.range) + ') : (' + render(...s.no.range) + '), {$: "Unit"})');
  return {source: program, report: {kind: 'literal-choice-tail-derivative', version: 1,
    runtimeSha256: runtimeHash, inputSha256: sha(source), outputSha256: sha(program),
    sites: sites.size, skipped, protectedBodies: [...names].map(name => ({name, sha256: sha(functions.get(name).source)})),
    scope: 'Only saturated structurally verified choices with two literal run_clo arrows; keep original runtime, exports and trampoline boundary.'}};
}
export function lowerLeaves(source) {
  const view = moduleView(source), {ts, functions} = view;
  guardBindings(view, new Set([...functions.keys(), 'run_tail', 'run_loop', 'run_clo', 'run_lib']), {lexical: true});
  const sites = new Map(), skipped = [];
  for (let i = 0; i < view.end; i++) {
    const choice = view.returnedChoice(i);
    if (!choice) continue;
    const yes = view.leafBranch(choice.yes), no = view.leafBranch(choice.no);
    if (!yes || !no) { skipped.push({at: ts[i].start, reason: 'Branch is not one return with call-free terminal arguments'}); continue; }
    sites.set(i, {...choice, yes, no});
  }
  let deferred = 0;
  const branch = (b, render) => {
    const prefix = 'const ' + b.param + ' = {$: "Unit"};\n';
    if (b.direct) {
      deferred++;
      return prefix + 'return {$: "$JMP", f: ' + b.direct.callee + ', x: [' + b.direct.args.map(a => render(...a)).join(', ') + ']};';
    }
    return prefix + render(b.ret, b.end);
  };
  const program = view.program(sites, (s, render) => 'if (' + render(...s.condition) + ') {\n' +
    branch(s.yes, render) + '\n} else {\n' + branch(s.no, render) + '\n}');
  return {source: program, report: {kind: 'return-choice-leaf-derivative', version: 1,
    sites: sites.size, deferredGeneratedCalls: deferred, skipped, runtimeSha256: runtimeHash,
    inputSha256: sha(source), outputSha256: sha(program),
    scope: 'Only returned literal Unit choices with one-return branches, no declarations and no calls except terminal direct generated calls with call-free arguments. Unit bindings and original boundaries around all non-tail call work remain. Runtime/public exports stay exact; private unforced tail-message representation is not an invariant.'}};
}
export function transform(source, options = {version: 5}) {
  assert.deepEqual(Object.keys(options), ['version']);
  assert.ok([1, 2, 3, 4, 5].includes(options.version));
  if (options.version <= 3) return transformEquality(source, options.version);
  const scalar = transformEquality(source, 3), choice = lowerChoices(scalar.source, options.version === 5);
  const stats = {...scalar.stats, version: options.version, choices: choice.report};
  if (options.version === 4) return {source: choice.source, stats};
  const tail = lowerLeaves(choice.source);
  return {source: tail.source, stats: {...stats, tailChoices: tail.report}};
}
