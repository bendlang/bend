// Single-threaded TypeScript twin of main.bend.
// Same scene of 9 spheres + one point light at (-3,8,1), same 2x2
// supersampled pixels, nearest-hit + Lambertian shadow shading +
// mirror bounce on a countdown depth (4). ray_trace is in the bench's
// accumulator form: per bounce acc' = acc + ((w*lum)*(1-kr)), w' =
// w*kr, final level adds acc + (w*lum); nearest folds spheres 8 down
// to 0 with strict <. Math.fround at every primitive operation
// preserves Bend's one-operation f32 semantics; the Bend row-fork
// reduction is a plain row loop (u32 wrapping sum).
// Expected at ROWS=12, WIDTH=6000: 1924309504 (ROWS=6, WIDTH=80:
// 402971).
const ROWS = 12,
  WIDTH = 6000,
  NS = 9,
  DEPTH = 4;
type Sphere = readonly [number, number, number, number, number];
const SPHERES: readonly Sphere[] = [
  [0, -10001, 5, 10000, 0.3],
  [0, 0, 5, 1, 0.7],
  [2, 0.5, 6, 1, 0.4],
  [-2, 0.5, 6, 1, 0.4],
  [1, -0.6, 3.5, 0.4, 0.9],
  [-1, -0.6, 3.5, 0.4, 0.9],
  [0, 1.6, 7, 1.2, 0.1],
  [3.5, 0.2, 8, 1, 0.6],
  [-3.5, 0.2, 8, 1, 0.6],
].map((s) => s.map(Math.fround) as unknown as Sphere);
const fadd = (a: number, b: number) =>
  Math.fround(Math.fround(a) + Math.fround(b));
const fsub = (a: number, b: number) =>
  Math.fround(Math.fround(a) - Math.fround(b));
const fmul = (a: number, b: number) =>
  Math.fround(Math.fround(a) * Math.fround(b));
const fdiv = (a: number, b: number) =>
  Math.fround(Math.fround(a) / Math.fround(b));
const fsqrt = (a: number) => Math.fround(Math.sqrt(a));

function sphere_isect(
  i: number,
  ox: number,
  oy: number,
  oz: number,
  dx: number,
  dy: number,
  dz: number,
): number {
  const s = SPHERES[i],
    px = fsub(ox, s[0]),
    py = fsub(oy, s[1]),
    pz = fsub(oz, s[2]);
  const b = fadd(fadd(fmul(px, dx), fmul(py, dy)), fmul(pz, dz));
  const c = fsub(
    fadd(fadd(fmul(px, px), fmul(py, py)), fmul(pz, pz)),
    fmul(s[3], s[3]),
  );
  const disc = fsub(fmul(b, b), c);
  if (disc < 0) {
    return 1e9;
  }
  const t = fsub(fsub(0, b), fsqrt(disc));
  return t < 0.001 ? 1e9 : t;
}
function scene_nearest(
  ox: number,
  oy: number,
  oz: number,
  dx: number,
  dy: number,
  dz: number,
): [number, number] {
  let best = 1e9,
    id = NS;
  for (let i = NS; i > 0; --i) {
    const t = sphere_isect(i - 1, ox, oy, oz, dx, dy, dz);
    if (t < best) {
      best = t;
      id = i - 1;
    }
  }
  return [best, id];
}
function ray_trace(
  dep: number,
  ox: number,
  oy: number,
  oz: number,
  dx: number,
  dy: number,
  dz: number,
  acc: number,
  w: number,
): number {
  const [t, id] = scene_nearest(ox, oy, oz, dx, dy, dz);
  if (id === NS) {
    return acc;
  }
  const s = SPHERES[id],
    hx = fadd(ox, fmul(t, dx)),
    hy = fadd(oy, fmul(t, dy)),
    hz = fadd(oz, fmul(t, dz));
  const nx = fdiv(fsub(hx, s[0]), s[3]),
    ny = fdiv(fsub(hy, s[1]), s[3]),
    nz = fdiv(fsub(hz, s[2]), s[3]);
  const lvx = fsub(-3, hx),
    lvy = fsub(8, hy),
    lvz = fsub(1, hz);
  const ll = fsqrt(fadd(fadd(fmul(lvx, lvx), fmul(lvy, lvy)), fmul(lvz, lvz)));
  const lx = fdiv(lvx, ll),
    ly = fdiv(lvy, ll),
    lz = fdiv(lvz, ll);
  const dot = fadd(fadd(fmul(nx, lx), fmul(ny, ly)), fmul(nz, lz)),
    df = dot < 0 ? 0 : dot;
  const sox = fadd(hx, fmul(0.001, nx)),
    soy = fadd(hy, fmul(0.001, ny)),
    soz = fadd(hz, fmul(0.001, nz));
  const [shadow] = scene_nearest(sox, soy, soz, lx, ly, lz),
    shade = shadow < ll ? 0 : df;
  const lum = fadd(0.1, fmul(0.85, shade));
  if (dep === 0) {
    return fadd(acc, fmul(w, lum));
  }
  const k2 = fmul(2, fadd(fadd(fmul(dx, nx), fmul(dy, ny)), fmul(dz, nz)));
  return ray_trace(
    dep - 1,
    sox,
    soy,
    soz,
    fsub(dx, fmul(k2, nx)),
    fsub(dy, fmul(k2, ny)),
    fsub(dz, fmul(k2, nz)),
    fadd(acc, fmul(fmul(w, lum), fsub(1, s[4]))),
    fmul(w, s[4]),
  );
}
function ray_sub(fx: number, fy: number): number {
  const dl = fsqrt(fadd(fadd(fmul(fx, fx), fmul(fy, fy)), 1));
  return ray_trace(
    DEPTH,
    0,
    0,
    0,
    fdiv(fx, dl),
    fdiv(fy, dl),
    fdiv(1, dl),
    0,
    1,
  );
}
// 2x2 supersampled pixel
function pixel_render(x: number, y: number, hw: number, hh: number): number {
  const xf = Math.fround(x),
    yf = Math.fround(y);
  const l1 = ray_sub(
    fdiv(fsub(fadd(xf, 0.25), hw), hw),
    fdiv(fsub(hh, fadd(yf, 0.25)), hw),
  );
  const l2 = ray_sub(
    fdiv(fsub(fadd(xf, 0.75), hw), hw),
    fdiv(fsub(hh, fadd(yf, 0.25)), hw),
  );
  const l3 = ray_sub(
    fdiv(fsub(fadd(xf, 0.25), hw), hw),
    fdiv(fsub(hh, fadd(yf, 0.75)), hw),
  );
  const l4 = ray_sub(
    fdiv(fsub(fadd(xf, 0.75), hw), hw),
    fdiv(fsub(hh, fadd(yf, 0.75)), hw),
  );
  const avg = fmul(fadd(fadd(l1, l2), fadd(l3, l4)), 0.25);
  return Math.trunc(fmul(255, avg < 0 ? 0 : avg > 1 ? 1 : avg)) >>> 0;
}
function benchmark_run(): number {
  const h = 1 << ROWS,
    hw = Math.fround(Math.trunc(WIDTH / 2)),
    hh = Math.fround(Math.trunc(h / 2));
  let acc = 0;
  // the Bend fork tree permutes row/column indices by odd multipliers
  // (bijections: same pixel set, same u32 sum); mirrored here
  for (let yj = 0; yj < h; ++yj) {
    const y = (Math.imul(yj, 1588635697) & (h - 1)) >>> 0;
    for (let xj = 0; xj < 16384; ++xj) {
      const x = (Math.imul(xj, 2654435761) & 16383) >>> 0;
      if (x < WIDTH) {
        acc = (acc + pixel_render(x, y, hw, hh)) >>> 0;
      }
    }
  }
  return acc;
}
console.log(benchmark_run());
