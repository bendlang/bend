import {pathToFileURL} from 'node:url';
const {default: K} = await import(pathToFileURL(process.argv[2]));
const nil = {$: 'Nil'};
const list = xs => xs.reduceRight((tail, head) => ({$: 'Con', head, tail}), nil);
const t = (tag, name = '', id = 0, kids = []) => ({$: 'KTerm', tag, name, id,
  quant: ['Lam', 'All'].includes(tag) ? 1 : 0, kids: list(kids), removed: nil});
const v = id => t('Var', 'x', id), app = (f, x) => t('App', '', 0, [f, x]);
const omega = app(t('Lam', 'x', 1, [app(v(1), v(1))]), t('Lam', 'y', 2, [app(v(2), v(2))]));
const A = t('Ctr', 'A'), B = t('Ctr', 'B');
const name = process.argv[4];
const a = name === 'all-domain' ? t('All', 'x', 100, [omega, A]) : t('All', 'x', 100, [A, omega]);
const b = name === 'all-domain' ? t('All', 'y', 101, [omega, B]) : t('All', 'y', 101, [A, omega]);
for (const root of [a, b]) {
  const seen = new Set(), pending = [root];
  while (pending.length) {
    const node = pending.pop();
    if (['Lam', 'All', 'Bind'].includes(node.tag)) {
      if (seen.has(node.id)) throw Error('Duplicate binder ID: ' + node.id);
      seen.add(node.id);
    }
    for (let kids = node.kids; kids.$ === 'Con'; kids = kids.tail) pending.push(kids.head);
  }
}
const supported = K.sv_supported(a) && K.sv_supported(b);
console.log(JSON.stringify({name, mode: process.argv[3], supported, distinctBinderIds: true, phase: 'before conversion'}));
const result = process.argv[3] === 'old' ? K.compare(nil, a, b, false) : K.sv_equal(a, b);
console.log(JSON.stringify({name, mode: process.argv[3], result}));
