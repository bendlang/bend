// Native TS translation of main.bend: chaotic three-body ensemble,
// f32 (Math.fround per op), Plummer-softened, symplectic Euler.
const SY = 17,
  ST = 300;
const f = Math.fround;

function word_prng(x: number): number {
  x = (x ^ (x << 13)) >>> 0;
  x = (x ^ (x >>> 17)) >>> 0;
  return (x ^ (x << 5)) >>> 0;
}

// f32_to_u32: truncate toward zero; NaN, negative, or >= 2^32 -> 0
function float_word(v: number): number {
  if (Number.isNaN(v) || v < 1 || v >= 4294967296) return 0;
  return Math.floor(v) >>> 0;
}

function seed_hash(sd: number, k: number): number {
  return word_prng(Math.imul((sd * 12 + k) >>> 0, 2654435761) >>> 0);
}

function seed_unit(sd: number, k: number): number {
  return f(f((seed_hash(sd, k) & 65535) / 32768) - 1);
}

function seed_mass(sd: number, k: number): number {
  return f(f((seed_hash(sd, k) & 65535) / 65536) + 0.5);
}

// one random system: three seeded bodies, ST steps, digest [cs, eb]
function system_run(sd: number, st: number): [number, number] {
  let x0 = seed_unit(sd, 1),
    y0 = seed_unit(sd, 2),
    z0 = seed_unit(sd, 3);
  const m0 = seed_mass(sd, 4);
  let x1 = seed_unit(sd, 5),
    y1 = seed_unit(sd, 6),
    z1 = seed_unit(sd, 7);
  const m1 = seed_mass(sd, 8);
  let x2 = seed_unit(sd, 9),
    y2 = seed_unit(sd, 10),
    z2 = seed_unit(sd, 11);
  const m2 = seed_mass(sd, 12);
  let vx0 = f(y0 * f(0.1)),
    vy0 = f(0 - f(x0 * f(0.1))),
    vz0 = 0;
  let vx1 = f(y1 * f(0.1)),
    vy1 = f(0 - f(x1 * f(0.1))),
    vz1 = 0;
  let vx2 = f(y2 * f(0.1)),
    vy2 = f(0 - f(x2 * f(0.1))),
    vz2 = 0;
  const dt = f(0.001),
    eps = f(0.05);
  for (let s = st; s; s--) {
    const ax = f(x1 - x0),
      ay = f(y1 - y0),
      az = f(z1 - z0);
    const da = f(f(f(ax * ax) + f(f(ay * ay) + f(az * az))) + eps);
    const ia = f(1 / f(Math.sqrt(da)));
    const i3a = f(f(ia * ia) * ia);
    const qax = f(ax * i3a),
      qay = f(ay * i3a),
      qaz = f(az * i3a);
    const bx = f(x2 - x0),
      by = f(y2 - y0),
      bz = f(z2 - z0);
    const db = f(f(f(bx * bx) + f(f(by * by) + f(bz * bz))) + eps);
    const ib = f(1 / f(Math.sqrt(db)));
    const i3b = f(f(ib * ib) * ib);
    const qbx = f(bx * i3b),
      qby = f(by * i3b),
      qbz = f(bz * i3b);
    const cx = f(x2 - x1),
      cy = f(y2 - y1),
      cz = f(z2 - z1);
    const dc = f(f(f(cx * cx) + f(f(cy * cy) + f(cz * cz))) + eps);
    const ic = f(1 / f(Math.sqrt(dc)));
    const i3c = f(f(ic * ic) * ic);
    const qcx = f(cx * i3c),
      qcy = f(cy * i3c),
      qcz = f(cz * i3c);
    vx0 = f(vx0 + f(f(f(qax * m1) + f(qbx * m2)) * dt));
    vy0 = f(vy0 + f(f(f(qay * m1) + f(qby * m2)) * dt));
    vz0 = f(vz0 + f(f(f(qaz * m1) + f(qbz * m2)) * dt));
    vx1 = f(vx1 + f(f(f(qcx * m2) - f(qax * m0)) * dt));
    vy1 = f(vy1 + f(f(f(qcy * m2) - f(qay * m0)) * dt));
    vz1 = f(vz1 + f(f(f(qcz * m2) - f(qaz * m0)) * dt));
    vx2 = f(vx2 - f(f(f(qbx * m0) + f(qcx * m1)) * dt));
    vy2 = f(vy2 - f(f(f(qby * m0) + f(qcy * m1)) * dt));
    vz2 = f(vz2 - f(f(f(qbz * m0) + f(qcz * m1)) * dt));
    x0 = f(x0 + f(vx0 * dt));
    y0 = f(y0 + f(vy0 * dt));
    z0 = f(z0 + f(vz0 * dt));
    x1 = f(x1 + f(vx1 * dt));
    y1 = f(y1 + f(vy1 * dt));
    z1 = f(z1 + f(vz1 * dt));
    x2 = f(x2 + f(vx2 * dt));
    y2 = f(y2 + f(vy2 * dt));
    z2 = f(z2 + f(vz2 * dt));
  }
  const s0 = f(f(vx0 * vx0) + f(f(vy0 * vy0) + f(vz0 * vz0)));
  const s1 = f(f(vx1 * vx1) + f(f(vy1 * vy1) + f(vz1 * vz1)));
  const s2 = f(f(vx2 * vx2) + f(f(vy2 * vy2) + f(vz2 * vz2)));
  const k0 = f(f(f(0.5) * m0) * s0);
  const k1 = f(f(f(0.5) * m1) * s1);
  const k2 = f(f(f(0.5) * m2) * s2);
  const ke = f(k0 + f(k1 + k2));
  const ax = f(x1 - x0),
    ay = f(y1 - y0),
    az = f(z1 - z0);
  const da = f(f(f(ax * ax) + f(f(ay * ay) + f(az * az))) + eps);
  const bx = f(x2 - x0),
    by = f(y2 - y0),
    bz = f(z2 - z0);
  const db = f(f(f(bx * bx) + f(f(by * by) + f(bz * bz))) + eps);
  const cx = f(x2 - x1),
    cy = f(y2 - y1),
    cz = f(z2 - z1);
  const dc = f(f(f(cx * cx) + f(f(cy * cy) + f(cz * cz))) + eps);
  const pa = f(f(m0 * m1) / f(Math.sqrt(da)));
  const pb = f(f(m0 * m2) / f(Math.sqrt(db)));
  const pc = f(f(m1 * m2) / f(Math.sqrt(dc)));
  const pe = f(pa + f(pb + pc));
  const e = f(ke - pe);
  const nb = float_word(f(0 - e));
  const eb = nb > 7 ? 7 : nb;
  const w0 = (Math.imul(float_word(f(f(x0 + 8) * 65536)), 31) + float_word(f(f(y0 + 8) * 65536))) >>> 0;
  const w1 = (Math.imul(float_word(f(f(x1 + 8) * 65536)), 31) + float_word(f(f(y1 + 8) * 65536))) >>> 0;
  const w2 = (Math.imul(float_word(f(f(x2 + 8) * 65536)), 31) + float_word(f(f(y2 + 8) * 65536))) >>> 0;
  const w3 = (Math.imul(float_word(f(f(z0 + 8) * 65536)), 31) + float_word(f(f(z1 + 8) * 65536))) >>> 0;
  const w4 = (Math.imul(w0, 2654435761) + w1) >>> 0;
  const w5 = (Math.imul(w4, 2654435761) + w2) >>> 0;
  const w6 = (Math.imul(w5, 2654435761) + w3) >>> 0;
  const cs = (Math.imul(w6, 2654435761) + float_word(f(f(z2 + 8) * 65536))) >>> 0;
  return [cs, eb];
}

const count = 8 << SY;
const h = new Uint32Array(8);
let sum = 0;
for (let sd = 0; sd < count; sd++) {
  const [cs, eb] = system_run(sd, ST);
  h[eb]++;
  sum = (sum + Math.imul(cs, (Math.imul(sd, 2654435761) + 1) >>> 0)) >>> 0;
}
let g = h[0];
for (let k = 1; k < 8; k++) g = (Math.imul(g, 2654435761) + h[k]) >>> 0;
console.log((Math.imul(g, 2654435761) + sum) >>> 0);
