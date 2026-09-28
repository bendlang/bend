// Source-range views for the reviewed generated grammar, not a JavaScript parser.
import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
export const sha = bytes => createHash('sha256').update(bytes).digest('hex');
export const marker = '// Program\n// =======\n';
export const runtimeHash = '241696c207b257ba28e159699e08e749c1625542a92d901a663ac3f04dfd20fd';

export function tokens(source, start) {
  const out = [];
  for (let i = start; i < source.length;) {
    if (/\s/.test(source[i])) { i++; continue; }
    const at = i, c = source[i];
    if (c === '"' || c === "'") {
      let closed = false;
      for (i++; i < source.length; i++) {
        if (source[i] === '\\') { i++; continue; }
        assert.ok(source[i] !== '\n' && source[i] !== '\r', 'Unsupported multiline string');
        if (source[i] === c) { i++; closed = true; break; }
      }
      assert.ok(closed, 'Unclosed string');
    } else if (/[A-Za-z_$]/.test(c)) {
      while (i < source.length && /[\w$]/.test(source[i])) i++;
    } else {
      assert.ok(c !== '`' && !source.startsWith('//', i) && !source.startsWith('/*', i), 'Unsupported generated syntax');
      i++;
    }
    out.push({text: source.slice(at, i), start: at, end: i});
  }
  const stack = [];
  for (let i = 0; i < out.length; i++) {
    const t = out[i].text;
    if (['(', '[', '{'].includes(t)) stack.push(i);
    else if ([')', ']', '}'].includes(t)) {
      const k = stack.pop();
      assert.ok(k !== undefined && '([{'.indexOf(out[k].text) === ')]}'.indexOf(t), 'Unbalanced generated module');
      out[k].close = i;
    }
  }
  assert.equal(stack.length, 0);
  return out;
}

export function moduleView(source) {
  const markerAt = source.indexOf(marker);
  assert.ok(markerAt >= 0, 'Missing runtime boundary');
  const start = markerAt + marker.length;
  assert.equal(sha(source.slice(0, start)), runtimeHash, 'Unsupported runtime');
  const ts = tokens(source, start), functions = new Map();
  let end = 0;
  while (ts[end]?.text === 'function') {
    const first = end, name = ts[first + 1]?.text;
    assert.match(name, /^\$[\w$]+\$$/);
    assert.ok(!functions.has(name), 'Duplicate generated binding');
    assert.equal(ts[first + 2]?.text, '(');
    const body = ts[first + 2].close + 1, last = ts[body]?.close;
    assert.equal(ts[body]?.text, '{');
    functions.set(name, {name, first, params: first + 2, body, end: last,
      source: source.slice(ts[first].start, ts[last].end)});
    end = last + 1;
  }
  assert.equal(ts[end]?.text, 'export');
  assert.equal(ts[end + 1]?.text, 'default');
  assert.equal(ts[end + 2]?.text, '{');
  assert.equal(ts[end + 2].close, ts.length - 2);
  assert.equal(ts.at(-1).text, ';');

  const split = open => {
    const ranges = []; let lo = open + 1;
    for (let i = lo; i < ts[open].close; i++) {
      if (ts[i].close !== undefined) { i = ts[i].close; continue; }
      if (ts[i].text === ',') { ranges.push([lo, i]); lo = i + 1; }
    }
    if (lo < ts[open].close) ranges.push([lo, ts[open].close]);
    return ranges;
  };
  const strip = ([lo, hi]) => {
    while (ts[lo]?.text === '(' && ts[lo].close === hi - 1) { lo++; hi--; }
    return [lo, hi];
  };
  const call = (range, unwrap = true) => {
    const [lo, hi] = unwrap ? strip(range) : range;
    return ts[lo + 1]?.text === '(' && ts[lo + 1].close === hi - 1
      ? {lo, hi, callee: ts[lo].text, open: lo + 1, args: split(lo + 1)} : null;
  };
  const arrow = (range, {wrapped = false, unwrap = false} = {}) => {
    let [lo, hi] = unwrap ? strip(range) : range;
    if (wrapped) {
      const wrapper = call([lo, hi], false);
      if (!wrapper || wrapper.callee !== 'run_clo') return null;
      lo += 2; hi--;
    }
    if (ts[lo]?.text !== '(' || ts[lo].close !== lo + 2 ||
        !/^[A-Za-z_$][\w$]*$/.test(ts[lo + 1]?.text ?? '') ||
        ts[lo + 3]?.text !== '=' || ts[lo + 4]?.text !== '>' ||
        ts[lo + 5]?.text !== '{' || ts[lo + 5].close !== hi - 1) return null;
    return {range: [lo, hi], param: ts[lo + 1].text, paramToken: lo + 1,
      body: lo + 5, end: hi - 1};
  };
  const semicolon = (lo, hi) => {
    for (let i = lo; i < hi; i++) {
      if (ts[i].close !== undefined) { i = ts[i].close; continue; }
      if (ts[i].text === ';') return i;
    }
    return -1;
  };
  const returnedChoice = i => {
    if (ts[i]?.text !== 'return' || ts[i + 1]?.text !== 'run_tail' ||
        ts[i + 2]?.text !== '(' || ts[ts[i + 2].close + 1]?.text !== ';') return null;
    const args = split(i + 2);
    if (args.length !== 2) return null;
    const [lo, hi] = args[0], q = ts[lo]?.close + 1;
    if (ts[lo]?.text !== '(' || ts[q]?.text !== '?') return null;
    const yesStart = q + 1, colon = ts[yesStart]?.close + 1, noStart = colon + 1;
    if (ts[yesStart]?.text !== '(' || ts[colon]?.text !== ':' ||
        ts[noStart]?.text !== '(' || ts[noStart].close !== hi - 1) return null;
    if (ts.slice(...args[1]).map(x => x.text).join('') !== '{$:"Unit"}') return null;
    return {first: i, end: ts[i + 2].close + 2, condition: [lo, q],
      yes: [yesStart, colon], no: [noStart, hi]};
  };
  const leafBranch = range => {
    const b = arrow(range, {unwrap: true});
    if (!b) return null;
    const ret = b.body + 1;
    if (ts[ret]?.text !== 'return' || semicolon(ret + 1, b.end) !== b.end - 1) return null;
    const expr = [ret + 1, b.end - 1], c = call(expr), direct = c && functions.has(c.callee);
    for (let j = expr[0]; j < expr[1]; j++) {
      const prev = ts[j - 1]?.text;
      const looksLikeCall = /^[A-Za-z_$][\w$]*$/.test(prev ?? '') && !['return', 'typeof', 'void'].includes(prev) || [')', ']', '.'].includes(prev);
      if (ts[j].text === '(' && looksLikeCall && !(direct && j === c.open)) return null;
    }
    return {...b, ret, expr, direct: direct ? c : null};
  };
  const render = (lo, hi, sites, replacement) => {
    if (lo === hi) return '';
    let text = '', cursor = ts[lo].start;
    const recurse = (a, b) => render(a, b, sites, replacement);
    for (let i = lo; i < hi; i++) {
      const site = sites.get(i);
      if (!site || site.end > hi) continue;
      text += source.slice(cursor, ts[i].start) + replacement(site, recurse);
      cursor = ts[site.end - 1].end; i = site.end - 1;
    }
    return text + source.slice(cursor, ts[hi - 1].end);
  };
  const program = (sites, replacement) => source.slice(0, start) + source.slice(start, ts[0].start) +
    render(0, ts.length, sites, replacement) + source.slice(ts.at(-1).end);
  return {source, start, ts, functions, end, split, strip, call, arrow,
    semicolon, returnedChoice, leafBranch, render, program};
}

export function guardBindings(view, names, {lexical = false} = {}) {
  const {ts, functions} = view;
  for (let i = 0; i < ts.length; i++) {
    const t = ts[i].text, prev = ts[i - 1]?.text, next = ts[i + 1]?.text;
    if (lexical) {
      assert.ok(!['this', 'arguments', 'super', 'new', 'eval', 'function*', 'yield', 'await', 'try', 'finally'].includes(t), 'Unsupported lexical/control dependency');
      if (t === 'function') assert.equal(functions.get(next)?.first, i, 'Nested function');
    }
    let params;
    if (t === 'function') params = i + 2;
    else if (t === '(' && ts[ts[i].close + 1]?.text === '=' && ts[ts[i].close + 2]?.text === '>') params = i;
    if (params !== undefined) {
      assert.equal(ts[params]?.text, '(');
      assert.ok(!ts.slice(params + 1, ts[params].close).some(x => names.has(x.text)), 'Protected parameter');
    }
    if (!names.has(t)) continue;
    assert.ok(!['let', 'const', 'var'].includes(prev) && next !== '=' &&
      !(['+', '-', '*', '/', '&', '|', '^', '?'].includes(next) && ['=', next].includes(ts[i + 2]?.text)), 'Rebound protected name');
    if (prev === 'function') assert.equal(functions.get(t)?.first, i - 1, 'Nested protected declaration');
    else assert.ok(next === '(' && !['.', 'new'].includes(prev), 'Unsupported protected reference');
  }
}
