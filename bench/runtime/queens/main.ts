// Single-threaded TypeScript twin of main.bend. Same
// algorithm, same shape: 4-row prefix decode + bitmask legality, then
// the bitmask backtracker over the remaining rows threading per-branch
// Stats{sols, nodes}; the Bend fork tree's smerge reduction is a plain
// sum over the prefix index space. Same recursive backtracker as the
// Bend bench. Checksum = (sols * 2654435761) ^ nodes.
// Expected at SIZE=17, LIMIT=11730: 2063750025 (SIZE=8, LIMIT=512:
// 2027808349).
const SIZE = 17,
  LIMIT = 11730,
  DEPTH = 17;

class Stats {
  sols: number;
  nodes: number;
  constructor(sols: number, nodes: number) {
    this.sols = sols;
    this.nodes = nodes;
  }
}

function board_solve(
  cand: number,
  cols: number,
  ldiag: number,
  rdiag: number,
  full: number,
  sols: number,
  nodes: number,
): Stats {
  cand >>>= 0;
  while (cand !== 0) {
    const bit = (cand & -cand) >>> 0,
      nextCols = (cols | bit) >>> 0;
    if (nextCols === full) {
      sols = (sols + 1) >>> 0;
      nodes = (nodes + 1) >>> 0;
    } else {
      const nextLeft = ((ldiag | bit) << 1) >>> 0,
        nextRight = (rdiag | bit) >>> 1;
      const w = board_solve(
        (full & ~(nextCols | nextLeft | nextRight)) >>> 0,
        nextCols,
        nextLeft,
        nextRight,
        full,
        sols,
        (nodes + 1) >>> 0,
      );
      sols = w.sols;
      nodes = w.nodes;
    }
    cand = (cand - bit) >>> 0;
  }
  return new Stats(sols, nodes);
}

// one 4-row prefix: decode the column quad, filter illegal placements,
// solve the remaining rows
function prefix_solve(
  j: number,
  nn: number,
  full: number,
  bound: number,
): Stats {
  // fork-order permutation (bijection on the 2^17 space)
  const i = (Math.imul(j, 2654435761) & 131071) >>> 0;
  if (!(i < bound)) {
    return new Stats(0, 0);
  }
  const nn2 = nn * nn;
  const b0 = (1 << Math.trunc(i / (nn2 * nn))) >>> 0,
    b1 = (1 << Math.trunc(i / nn2) % nn) >>> 0;
  if ((b1 & (b0 | (b0 << 1) | (b0 >>> 1))) !== 0) {
    return new Stats(0, 0);
  }
  const b2 = (1 << Math.trunc(i / nn) % nn) >>> 0,
    c2 = (b0 | b1) >>> 0;
  const l2 = (((b0 << 1) | b1) << 1) >>> 0,
    r2 = ((b0 >>> 1) | b1) >>> 1;
  if ((b2 & (c2 | l2 | r2)) !== 0) {
    return new Stats(0, 0);
  }
  const b3 = (1 << i % nn) >>> 0,
    c3 = (c2 | b2) >>> 0;
  const l3 = ((l2 | b2) << 1) >>> 0,
    r3 = (r2 | b2) >>> 1;
  if ((b3 & (c3 | l3 | r3)) !== 0) {
    return new Stats(0, 0);
  }
  const c4 = (c3 | b3) >>> 0,
    l4 = ((l3 | b3) << 1) >>> 0,
    r4 = (r3 | b3) >>> 1;
  return board_solve((full & ~(c4 | l4 | r4)) >>> 0, c4, l4, r4, full, 0, 0);
}

function benchmark_run(): number {
  const nn = SIZE,
    full = ((1 << nn) - 1) >>> 0,
    nn2 = nn * nn,
    nnnn = nn2 * nn2;
  const bound = LIMIT < nnnn ? LIMIT : nnnn;
  let sols = 0,
    nodes = 0;
  for (let i = 0; i < 1 << DEPTH; ++i) {
    const s = prefix_solve(i, nn, full, bound);
    sols = (sols + s.sols) >>> 0;
    nodes = (nodes + s.nodes) >>> 0;
  }
  return (Math.imul(sols, 2654435761) ^ nodes) >>> 0;
}
console.log(benchmark_run());
