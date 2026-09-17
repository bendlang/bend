// Native TypeScript twin of main.bend: recursive block matrix multiply
// over quad-trees with a Freivalds verification pass. Same datatypes,
// algorithms and wrapping-u32 numerics (imul + >>>0).
const word_wrap = (value: number): number => value >>> 0;

type Mat = { v: number; k: Mat[] | null };
type Vec = Mat;

function node_leaf(v: number): Mat {
  return { v, k: null };
}

function mat_quad(a: Mat, b: Mat, c: Mat, d: Mat): Mat {
  return { v: 0, k: [a, b, c, d] };
}

function vec_branch(l: Vec, r: Vec): Vec {
  return { v: 0, k: [l, r] };
}

function mat_gen(d: number, s: number): Mat {
  if (d === 0) {
    return node_leaf(s % 100);
  }
  const a = mat_gen(d - 1, word_wrap(Math.imul(s, 1664525) + 1));
  const b = mat_gen(d - 1, word_wrap(Math.imul(s, 214013) + 3));
  const c = mat_gen(d - 1, word_wrap(Math.imul(s, 16843009) + 5));
  const e = mat_gen(d - 1, word_wrap(Math.imul(s, 48271) + 7));
  return mat_quad(a, b, c, e);
}

function vec_gen(d: number, s: number): Vec {
  if (d === 0) {
    return node_leaf((word_wrap(Math.imul(s, 2654435761)) % 100) + 1);
  }
  const l = vec_gen(d - 1, word_wrap(Math.imul(s, 1664525) + 1));
  const r = vec_gen(d - 1, word_wrap(Math.imul(s, 214013) + 3));
  return vec_branch(l, r);
}

function mat_add(a: Mat, b: Mat): Mat {
  if (a.k === null) {
    return node_leaf(word_wrap(a.v + (b.k === null ? b.v : 0)));
  }
  if (b.k === null) {
    return node_leaf(0);
  }
  const r0 = mat_add(a.k[0], b.k[0]);
  const r1 = mat_add(a.k[1], b.k[1]);
  const r2 = mat_add(a.k[2], b.k[2]);
  const r3 = mat_add(a.k[3], b.k[3]);
  return mat_quad(r0, r1, r2, r3);
}

// join of one mul burst: C_ij = P_ij + Q_ij
function mat_add4(
  p0: Mat, q0: Mat, p1: Mat, q1: Mat,
  p2: Mat, q2: Mat, p3: Mat, q3: Mat,
): Mat {
  return mat_quad(mat_add(p0, q0), mat_add(p1, q1), mat_add(p2, q2), mat_add(p3, q3));
}

// each node spawns its whole 8-product burst, joined through mat_add4
function mat_mul(a: Mat, b: Mat): Mat {
  if (a.k === null) {
    return node_leaf(b.k === null ? word_wrap(Math.imul(a.v, b.v)) : 0);
  }
  if (b.k === null) {
    return node_leaf(0);
  }
  const p0 = mat_mul(a.k[0], b.k[0]);
  const q0 = mat_mul(a.k[1], b.k[2]);
  const p1 = mat_mul(a.k[0], b.k[1]);
  const q1 = mat_mul(a.k[1], b.k[3]);
  const p2 = mat_mul(a.k[2], b.k[0]);
  const q2 = mat_mul(a.k[3], b.k[2]);
  const p3 = mat_mul(a.k[2], b.k[1]);
  const q3 = mat_mul(a.k[3], b.k[3]);
  return mat_add4(p0, q0, p1, q1, p2, q2, p3, q3);
}

function vec_add(x: Vec, y: Vec): Vec {
  if (x.k === null) {
    return node_leaf(y.k === null ? word_wrap(x.v + y.v) : 0);
  }
  if (y.k === null) {
    return node_leaf(0);
  }
  return vec_branch(vec_add(x.k[0], y.k[0]), vec_add(x.k[1], y.k[1]));
}

// join of one mvm burst
function vec_add2(t0: Vec, t1: Vec, t2: Vec, t3: Vec): Vec {
  return vec_branch(vec_add(t0, t1), vec_add(t2, t3));
}

// [[a,b],[c,d]] * (l,h) = (a*l + b*h, c*l + d*h)
function mat_vec_mul(m: Mat, v: Vec): Vec {
  if (m.k === null) {
    return node_leaf(v.k === null ? word_wrap(Math.imul(m.v, v.v)) : 0);
  }
  if (v.k === null) {
    return node_leaf(0);
  }
  const t0 = mat_vec_mul(m.k[0], v.k[0]);
  const t1 = mat_vec_mul(m.k[1], v.k[1]);
  const t2 = mat_vec_mul(m.k[2], v.k[0]);
  const t3 = mat_vec_mul(m.k[3], v.k[1]);
  return vec_add2(t0, t1, t2, t3);
}

function mat_cksum(m: Mat): number {
  if (m.k === null) {
    return m.v;
  }
  return word_wrap(
    mat_cksum(m.k[0]) + mat_cksum(m.k[1]) + mat_cksum(m.k[2]) + mat_cksum(m.k[3]),
  );
}

// or-fold of elementwise xor: 0 iff the vectors are identical
function vec_dif(x: Vec, y: Vec): number {
  if (x.k === null || y.k === null) {
    return x.k === null && y.k === null ? word_wrap(x.v ^ y.v) : 1;
  }
  return word_wrap(vec_dif(x.k[0], y.k[0]) | vec_dif(x.k[1], y.k[1]));
}

// one round: generate A, B, r; C = A*B; Freivalds-verify C*r == A*(B*r)
function round_run(d: number, s: number): number {
  const a = mat_gen(d, word_wrap(s + 1));
  const b = mat_gen(d, word_wrap(s + 2));
  const r = vec_gen(d, word_wrap(s + 3));
  const c = mat_mul(a, b);
  const k = mat_cksum(c);
  const t1 = mat_vec_mul(c, r);
  const u = mat_vec_mul(b, r);
  const t2 = mat_vec_mul(a, u);
  const v = vec_dif(t1, t2);
  return word_wrap(word_wrap(k ^ word_wrap(Math.imul(s, 2654435761))) + (v === 0 ? 1 : 0));
}

// batch over the round index space: round i runs on seed = hashed index
// (u32 addition commutes, so the flat loop equals the Bend fork tree)
function batch_run(nchain: number, d: number): number {
  let acc = 0;
  for (let i = 0; i < nchain; i++) {
    acc = word_wrap(acc + round_run(d, word_wrap(Math.imul(i, 2654435761))));
  }
  return acc;
}

console.log(batch_run(384, 7));
