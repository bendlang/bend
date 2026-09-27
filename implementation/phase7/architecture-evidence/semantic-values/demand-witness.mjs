import {pathToFileURL} from 'node:url';
const {default: K} = await import(pathToFileURL(process.argv[2]));
const nil = {$: 'Nil'};
const list = xs => xs.reduceRight((tail, head) => ({$: 'Con', head, tail}), nil);
const t = (tag, name = '', id = 0, kids = []) => ({$: 'KTerm', tag, name, id, quant: tag === 'Lam' ? 1 : 0, kids: list(kids), removed: nil});
const v = id => t('Var', 'x', id);
const app = (f, x) => t('App', '', 0, [f, x]);
const leftLoop = t('Lam', 'x', 1, [app(v(1), v(1))]);
const rightLoop = t('Lam', 'y', 2, [app(v(2), v(2))]);
const omega = app(leftLoop, rightLoop);
const A = t('Ctr', 'A'), B = t('Ctr', 'B');
const identity = t('Lam', 'x', 3, [v(3)]);
const cases = {
  'early-mismatch': [app(app(t('Ref', 'f'), A), omega), app(app(t('Ref', 'f'), B), omega)],
  'reflexivity': [omega, omega],
  'wrapped-reflexivity': [t('Ctr', 'Wrap', 0, [omega]), t('Ctr', 'Wrap', 0, [omega])],
  'nested-reflexivity': [t('Ctr', 'Pair', 0, [A, omega]), t('Ctr', 'Pair', 0, [app(identity, A), omega])],
  'constructor-arity': [t('Ctr', 'Pack', 0, [omega]), t('Ctr', 'Pack', 0, [omega, A])],
  'neutral-arity': [app(t('Ref', 'f'), omega), app(app(t('Ref', 'f'), omega), A)],
};
const name = process.argv[4] || 'early-mismatch';
const [a, b] = cases[name];
const assertDistinctBinders = root => {
  const seen = new Set(), pending = [root];
  while (pending.length) {
    const node = pending.pop();
    if (['Lam', 'All', 'Bind'].includes(node.tag)) {
      if (seen.has(node.id)) throw Error('Duplicate binder ID in witness: ' + node.id);
      seen.add(node.id);
    }
    for (let xs = node.kids; xs.$ === 'Con'; xs = xs.tail) pending.push(xs.head);
  }
};
assertDistinctBinders(a); assertDistinctBinders(b);
const result = process.argv[3] === 'old' ? K.compare(nil, a, b, false) : K.sv_equal(a, b);
console.log(JSON.stringify({mode: process.argv[3], name, distinctBinderIds: true, result}));
