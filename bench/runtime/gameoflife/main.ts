// Native TypeScript twin of main.bend: Conway soup census. Same
// bit-packed 4x4-torus step, SWAR popcount, two-probe classification,
// 64-soup chunks and census merge, wrapping-u32 numerics (imul + >>>0).
const word_wrap = (value: number): number => value >>> 0;

type Census = { pop: number; still: number; osc: number; mix: number };

function cell_get(board: number, r: number, c: number): number {
  return (board >>> (((r & 3) * 4 + (c & 3)) & 31)) & 1;
}

function neighbor_count(board: number, r: number, c: number): number {
  return (
    cell_get(board, r - 1, c - 1) +
    cell_get(board, r - 1, c) +
    cell_get(board, r - 1, c + 1) +
    cell_get(board, r, c - 1) +
    cell_get(board, r, c + 1) +
    cell_get(board, r + 1, c - 1) +
    cell_get(board, r + 1, c) +
    cell_get(board, r + 1, c + 1)
  );
}

function to_bool(k: number): number {
  return k === 0 ? 0 : 1;
}

function next_dead(n: number): number {
  return to_bool(n === 3 ? 1 : 0);
}

function next_alive(n: number): number {
  return to_bool((n === 2 ? 1 : 0) | (n === 3 ? 1 : 0));
}

function next_cell(a: number, n: number): number {
  return a === 0 ? next_dead(n) : next_alive(n);
}

function step_cell(board: number, pos: number): number {
  const r = pos >>> 2;
  const c = pos & 3;
  const alive = cell_get(board, r, c);
  const neighbors = neighbor_count(board, r, c);
  return next_cell(alive, neighbors) << (pos & 31);
}

function board_step(b: number): number {
  let next = 0;
  for (let pos = 0; pos < 16; pos++) {
    next |= step_cell(b, pos);
  }
  return next >>> 0;
}

function board_run(n: number, board: number): number {
  while (n !== 0) {
    board = board_step(board);
    n--;
  }
  return board;
}

// 16-bit SWAR population count
function board_popcount(b: number): number {
  const a = word_wrap(b - ((b >>> 1) & 21845));
  const c = (a & 13107) + ((a >>> 2) & 13107);
  const d = (c + (c >>> 4)) & 3855;
  return ((d * 257) >>> 8) & 31;
}

// classify the settled board by two probe steps: 0 still, 1 osc, 2 chaos
function board_classify(b: number): number {
  const n1 = board_step(b);
  if (n1 === b) {
    return 0;
  }
  const n2 = board_step(n1);
  return n2 === b ? 1 : 2;
}

// one soup: hash the soup index into a 16-bit board, run GENS steps
function soup_sim(ix: number, g: number): number {
  return board_run(g, word_wrap(Math.imul(ix, 2654435761)) & 65535);
}

// leaf chunk: 64 soups folded into scalar accumulators
function chunk_run(j: number, i: number, g: number): Census {
  let pa = 0;
  let sa = 0;
  let oa = 0;
  let mx = 0;
  while (j !== 0) {
    const bd = soup_sim(word_wrap(i + j - 1), g);
    const p = board_popcount(bd);
    const c = board_classify(bd);
    mx = word_wrap(Math.imul(mx, 2654435761) ^ bd);
    pa = word_wrap(pa + p);
    sa = word_wrap(sa + (c === 0 ? 1 : 0));
    oa = word_wrap(oa + (c === 1 ? 1 : 0));
    j--;
  }
  return { pop: pa, still: sa, osc: oa, mix: mx };
}

function census_zip(a: Census, b: Census): Census {
  return {
    pop: word_wrap(a.pop + b.pop),
    still: word_wrap(a.still + b.still),
    osc: word_wrap(a.osc + b.osc),
    mix: word_wrap(Math.imul(a.mix, 2654435761) + b.mix),
  };
}

function batch_run(d: number, i: number, g: number): Census {
  if (d === 0) {
    return chunk_run(64, i, g);
  }
  const a = batch_run(d - 1, i, g);
  const b = batch_run(d - 1, word_wrap(i + (64 << (d - 1))), g);
  return census_zip(a, b);
}

// final checksum: mix the census fields
function census_fin(c: Census): number {
  return word_wrap(
    Math.imul(
      word_wrap(
        Math.imul(word_wrap(Math.imul(c.pop, 2654435761) + c.still), 2654435761) + c.osc,
      ),
      2654435761,
    ) + c.mix,
  );
}

console.log(census_fin(batch_run(18, 0, 32)));
