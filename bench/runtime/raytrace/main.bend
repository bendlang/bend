import Base
# Raytrace: parallel recursive sphere raytracer, all f32, ported
# 1-to-1 from Bend3's par_raytrace. Fixed scene of 9 spheres (one
# 10000-radius floor sphere, six scene balls, two mirrored back-row
# balls) + one point light at (-3,8,1), camera at the origin looking
# +z. Per pixel: 2x2 supersampling -- four primary rays through the
# pixel corners at (0.25,0.75) offsets; each ray runs trace in
# accumulator form (acc, w): per mirror bounce acc' = acc +
# ((w*lum)*(1-kr)), w' = w*kr, final level adds acc + (w*lum). The
# nearest-hit search is the recursive min-fold nearest: isect
# (quadratic solve + sqrt, near root only) over spheres 8 down to 0
# with strict <. The pixel quantizes the averaged luminance to
# f2u(255*clamp01(avg)). rowf forks the 2^ROWS image rows as a
# balanced tree and colf forks 2^14 columns under each row, one
# per-pixel leaf (columns past width contribute 0). Checksum = u32
# wrapping sum over all pixels. Sphere indices and depth counters are
# Nats (no U32 match in Bend4); float literals spell as fl(n, d), one
# correctly rounded conversion, bit-exact vs the C literal; nearest is
# ONE self-tail def: the sphere table rides four small pure-word
# selectors (sx sy sz sr) and the quadratic rides isect5, so tocl
# splices them all and the whole nine-sphere fold compiles to a single
# machine segment -- no Sph ctor, no isect call, no nearest.go hop.
# trace is ONE def and its recursion is structural: it matches its
# depth Nat first (a match on a binder cannot follow a +local), so no
# def cycle remains; see the note above trace for the loop's shape
# and the fake zeroth bounce that feeds it the primary ray.
# Knobs: rows = 12 (2^12 = 4096 image rows, coarse), width (fine,
# <= 2^14).
#
# Sizes (rows, width): small (6, 80) expect 402971 (verified against
# a Bend3 C run on the cluster), big (12, 6000) expect 1924309504
# (from the Bend3 header).

type Sph is Data:
  Sph{x: F32, y: F32, z: F32, r: F32, kr: F32}

type Hit is Data:
  Hit{ms: Bool, t: F32, i: U32}

def Hit.t(h: Hit) -> F32:
  match h:
    case Hit{m, t, i}:
      t

# float literal n/d (Bend4 has no float literal syntax)
def fl(n: U32, d: U32) -> F32:
  F32.div(U32.to_f32(n), U32.to_f32(d))

def sphere(i: Nat) -> Sph:
  match i:
    case 0n:
      Sph{U32.to_f32(0), F32.sub(U32.to_f32(0), U32.to_f32(10001)), U32.to_f32(5), U32.to_f32(10000), fl(3, 10)}
    case 1n:
      Sph{U32.to_f32(0), U32.to_f32(0), U32.to_f32(5), U32.to_f32(1), fl(7, 10)}
    case 2n:
      Sph{U32.to_f32(2), fl(5, 10), U32.to_f32(6), U32.to_f32(1), fl(4, 10)}
    case 3n:
      Sph{F32.sub(U32.to_f32(0), U32.to_f32(2)), fl(5, 10), U32.to_f32(6), U32.to_f32(1), fl(4, 10)}
    case 4n:
      Sph{U32.to_f32(1), F32.sub(U32.to_f32(0), fl(6, 10)), fl(35, 10), fl(4, 10), fl(9, 10)}
    case 5n:
      Sph{F32.sub(U32.to_f32(0), U32.to_f32(1)), F32.sub(U32.to_f32(0), fl(6, 10)), fl(35, 10), fl(4, 10), fl(9, 10)}
    case 6n:
      Sph{U32.to_f32(0), fl(16, 10), U32.to_f32(7), fl(12, 10), fl(1, 10)}
    case 7n:
      Sph{fl(35, 10), fl(2, 10), U32.to_f32(8), U32.to_f32(1), fl(6, 10)}
    case 8n+k:
      Sph{F32.sub(U32.to_f32(0), fl(35, 10)), fl(2, 10), U32.to_f32(8), U32.to_f32(1), fl(6, 10)}

def isect.t2(t: F32, z: Bool) -> F32:
  match z:
    case True{}:
      U32.to_f32(1000000000)
    case False{}:
      t

def isect.t(+t: F32) -> F32:
  isect.t2(t, F32.is_lt(t, fl(1, 1000)))

def isect.go2(b: F32, disc: F32, z: Bool) -> F32:
  match z:
    case True{}:
      U32.to_f32(1000000000)
    case False{}:
      isect.t(F32.sub(F32.sub(U32.to_f32(0), b), F32.sqrt(disc)))

def isect.go(b: F32, +disc: F32) -> F32:
  isect.go2(b, disc, F32.is_lt(disc, U32.to_f32(0)))

# ray-sphere: t of the near root, or 1e9 for a miss (disc < 0 or t < eps)
def isect5(cx: F32, cy: F32, cz: F32, +r: F32, ox: F32, oy: F32,
           oz: F32, dx: F32, dy: F32, dz: F32) -> F32:
  +px = F32.sub(ox, cx)
  +py = F32.sub(oy, cy)
  +pz = F32.sub(oz, cz)
  +b = F32.add(F32.add(F32.mul(px, dx), F32.mul(py, dy)), F32.mul(pz, dz))
  isect.go(b, F32.sub(F32.mul(b, b), F32.sub(F32.add(F32.add(F32.mul(px, px), F32.mul(py, py)), F32.mul(pz, pz)), F32.mul(r, r))))

def sx(i: Nat) -> F32:
  match i:
    case 0n: U32.to_f32(0)
    case 1n: U32.to_f32(0)
    case 2n: U32.to_f32(2)
    case 3n: F32.sub(U32.to_f32(0), U32.to_f32(2))
    case 4n: U32.to_f32(1)
    case 5n: F32.sub(U32.to_f32(0), U32.to_f32(1))
    case 6n: U32.to_f32(0)
    case 7n: fl(35, 10)
    case 8n+k: F32.sub(U32.to_f32(0), fl(35, 10))

def sy(i: Nat) -> F32:
  match i:
    case 0n: F32.sub(U32.to_f32(0), U32.to_f32(10001))
    case 1n: U32.to_f32(0)
    case 2n: fl(5, 10)
    case 3n: fl(5, 10)
    case 4n: F32.sub(U32.to_f32(0), fl(6, 10))
    case 5n: F32.sub(U32.to_f32(0), fl(6, 10))
    case 6n: fl(16, 10)
    case 7n: fl(2, 10)
    case 8n+k: fl(2, 10)

def sz(i: Nat) -> F32:
  match i:
    case 0n: U32.to_f32(5)
    case 1n: U32.to_f32(5)
    case 2n: U32.to_f32(6)
    case 3n: U32.to_f32(6)
    case 4n: fl(35, 10)
    case 5n: fl(35, 10)
    case 6n: U32.to_f32(7)
    case 7n: U32.to_f32(8)
    case 8n+k: U32.to_f32(8)

def sr(i: Nat) -> F32:
  match i:
    case 0n: U32.to_f32(10000)
    case 1n: U32.to_f32(1)
    case 2n: U32.to_f32(1)
    case 3n: U32.to_f32(1)
    case 4n: fl(4, 10)
    case 5n: fl(4, 10)
    case 6n: fl(12, 10)
    case 7n: U32.to_f32(1)
    case 8n+k: U32.to_f32(1)

def skr(i: Nat) -> F32:
  match i:
    case 0n: fl(3, 10)
    case 1n: fl(7, 10)
    case 2n: fl(4, 10)
    case 3n: fl(4, 10)
    case 4n: fl(9, 10)
    case 5n: fl(9, 10)
    case 6n: fl(1, 10)
    case 7n: fl(6, 10)
    case 8n+k: fl(6, 10)

# nearest hit: recursive min-fold over the spheres, testing 8 down to
# 0 with strict <. the previous iteration's compare rides in as the
# lt column (guard shift): pt/pk hold the pending candidate, and each
# arm first applies the pending verdict, then tests its own sphere
def nearest(+i: Nat, +ox: F32, +oy: F32, +oz: F32, +dx: F32, +dy: F32,
            +dz: F32, +pt: F32, +pk: U32, +bt: F32, +bi: U32,
            lt: Bool) -> Hit:
  match i lt:
    case 0n False{}:
      Hit{U32.is_eq(bi, 9), bt, bi}
    case 0n True{}:
      Hit{U32.is_eq(pk, 9), pt, pk}
    case 1n++k False{}:
      +t = isect5(sx(k), sy(k), sz(k), sr(k), ox, oy, oz, dx, dy, dz)
      nearest(k, ox, oy, oz, dx, dy, dz, t, U32.from_nat(k), bt, bi, F32.is_lt(t, bt))
    case 1n++k True{}:
      +t = isect5(sx(k), sy(k), sz(k), sr(k), ox, oy, oz, dx, dy, dz)
      nearest(k, ox, oy, oz, dx, dy, dz, t, U32.from_nat(k), pt, pk, F32.is_lt(t, pt))

def fmax0.go(x: F32, z: Bool) -> F32:
  match z:
    case True{}:
      U32.to_f32(0)
    case False{}:
      x

def fmax0(+x: F32) -> F32:
  fmax0.go(x, F32.is_lt(x, U32.to_f32(0)))

# diffuse term, zeroed when the shadow ray hits something before the light
def shade(st: F32, ll: F32, df: F32) -> F32:
  fmax0.go(df, F32.is_lt(st, ll))

def clamp01.hi.go(x: F32, z: Bool) -> F32:
  match z:
    case True{}:
      U32.to_f32(1)
    case False{}:
      x

def clamp01.hi(+x: F32) -> F32:
  clamp01.hi.go(x, F32.is_lt(U32.to_f32(1), x))

def clamp01.go(x: F32, z: Bool) -> F32:
  match z:
    case True{}:
      U32.to_f32(0)
    case False{}:
      clamp01.hi(x)

def clamp01(+x: F32) -> F32:
  clamp01.go(x, F32.is_lt(x, U32.to_f32(0)))

# t-only nearest for the shadow probe: same fold, answers the bare
# min distance (a machine word, so the whole probe fuses into the
# caller's segment with no Hit node and no continuation)
def nearest.t(+i: Nat, +ox: F32, +oy: F32, +oz: F32, +dx: F32, +dy: F32,
              +dz: F32, +pt: F32, +bt: F32, lt: Bool) -> F32:
  match i lt:
    case 0n False{}:
      bt
    case 0n True{}:
      pt
    case 1n++k False{}:
      +t = isect5(sx(k), sy(k), sz(k), sr(k), ox, oy, oz, dx, dy, dz)
      nearest.t(k, ox, oy, oz, dx, dy, dz, t, bt, F32.is_lt(t, bt))
    case 1n++k True{}:
      +t = isect5(sx(k), sy(k), sz(k), sr(k), ox, oy, oz, dx, dy, dz)
      nearest.t(k, ox, oy, oz, dx, dy, dz, t, pt, F32.is_lt(t, pt))

# the bounce loop, ONE self-recursive def and one level per turn,
# PIPELINED across the nearest call: each turn receives the hit of
# its own ray as the ht column (nearest answers Hit{ms, t, i}, the
# miss flag computed structurally in its base case), so the miss
# early-out is a plain column match -- the original control flow,
# no computed scrutinee. a turn shades its hit, reflects, folds the
# shading into (acc, w), issues the NEXT ray's nearest and re-enters
# on the depth's pred with that Hit riding as an argument. subray
# issues the primary ray's nearest itself (the fake zeroth bounce's
# algebra is exact: acc 0, w 1), so entry depth is 4n for 5 bounces.
def trace(dep: Nat, ht: Hit, +sox: F32, +soy: F32, +soz: F32, +rdx: F32,
          +rdy: F32, +rdz: F32, acc: F32, +w: F32) -> F32:
  match dep ht:
    case d2 Hit{True{}, mt, mi}:
      acc
    case 0n Hit{False{}, +t, i}:
      +si = U32.to_nat(i)
      +rr = sr(si)
      +hx = F32.add(sox, F32.mul(t, rdx))
      +hy = F32.add(soy, F32.mul(t, rdy))
      +hz = F32.add(soz, F32.mul(t, rdz))
      +nx2 = F32.div(F32.sub(hx, sx(si)), rr)
      +ny2 = F32.div(F32.sub(hy, sy(si)), rr)
      +nz2 = F32.div(F32.sub(hz, sz(si)), rr)
      +lvx = F32.sub(F32.sub(U32.to_f32(0), U32.to_f32(3)), hx)
      +lvy = F32.sub(U32.to_f32(8), hy)
      +lvz = F32.sub(U32.to_f32(1), hz)
      +ll = F32.sqrt(F32.add(F32.add(F32.mul(lvx, lvx), F32.mul(lvy, lvy)), F32.mul(lvz, lvz)))
      +lx = F32.div(lvx, ll)
      +ly = F32.div(lvy, ll)
      +lz = F32.div(lvz, ll)
      df = fmax0(F32.add(F32.add(F32.mul(nx2, lx), F32.mul(ny2, ly)), F32.mul(nz2, lz)))
      sox2 = F32.add(hx, F32.mul(fl(1, 1000), nx2))
      soy2 = F32.add(hy, F32.mul(fl(1, 1000), ny2))
      soz2 = F32.add(hz, F32.mul(fl(1, 1000), nz2))
      st = nearest.t(9n, sox2, soy2, soz2, lx, ly, lz, U32.to_f32(1000000000), U32.to_f32(1000000000), False{})
      F32.add(acc, F32.mul(w, F32.add(fl(1, 10), F32.mul(fl(85, 100), shade(st, ll, df)))))
    case 1n+k Hit{False{}, +t, i}:
      +si = U32.to_nat(i)
      +rr = sr(si)
      +hx = F32.add(sox, F32.mul(t, rdx))
      +hy = F32.add(soy, F32.mul(t, rdy))
      +hz = F32.add(soz, F32.mul(t, rdz))
      +nx2 = F32.div(F32.sub(hx, sx(si)), rr)
      +ny2 = F32.div(F32.sub(hy, sy(si)), rr)
      +nz2 = F32.div(F32.sub(hz, sz(si)), rr)
      +lvx = F32.sub(F32.sub(U32.to_f32(0), U32.to_f32(3)), hx)
      +lvy = F32.sub(U32.to_f32(8), hy)
      +lvz = F32.sub(U32.to_f32(1), hz)
      +ll = F32.sqrt(F32.add(F32.add(F32.mul(lvx, lvx), F32.mul(lvy, lvy)), F32.mul(lvz, lvz)))
      +lx = F32.div(lvx, ll)
      +ly = F32.div(lvy, ll)
      +lz = F32.div(lvz, ll)
      df = fmax0(F32.add(F32.add(F32.mul(nx2, lx), F32.mul(ny2, ly)), F32.mul(nz2, lz)))
      +sox2 = F32.add(hx, F32.mul(fl(1, 1000), nx2))
      +soy2 = F32.add(hy, F32.mul(fl(1, 1000), ny2))
      +soz2 = F32.add(hz, F32.mul(fl(1, 1000), nz2))
      st = nearest.t(9n, sox2, soy2, soz2, lx, ly, lz, U32.to_f32(1000000000), U32.to_f32(1000000000), False{})
      +lum2 = F32.add(fl(1, 10), F32.mul(fl(85, 100), shade(st, ll, df)))
      +kr2 = skr(si)
      +k2 = F32.mul(U32.to_f32(2), F32.add(F32.add(F32.mul(rdx, nx2), F32.mul(rdy, ny2)), F32.mul(rdz, nz2)))
      +rd2x = F32.sub(rdx, F32.mul(k2, nx2))
      +rd2y = F32.sub(rdy, F32.mul(k2, ny2))
      +rd2z = F32.sub(rdz, F32.mul(k2, nz2))
      php = nearest(9n, sox2, soy2, soz2, rd2x, rd2y, rd2z, U32.to_f32(1000000000), 9, U32.to_f32(1000000000), 9, False{})
      trace(k, php, sox2, soy2, soz2, rd2x, rd2y, rd2z,
        F32.add(acc, F32.mul(F32.mul(w, lum2), F32.sub(U32.to_f32(1), kr2))), F32.mul(w, kr2))

def subray(+fx: F32, +fy: F32) -> F32:
  +dl = F32.sqrt(F32.add(F32.add(F32.mul(fx, fx), F32.mul(fy, fy)), U32.to_f32(1)))
  +dx = F32.div(fx, dl)
  +dy = F32.div(fy, dl)
  +dz = F32.div(U32.to_f32(1), dl)
  php = nearest(9n, U32.to_f32(0), U32.to_f32(0), U32.to_f32(0), dx, dy, dz, U32.to_f32(1000000000), 9, U32.to_f32(1000000000), 9, False{})
  trace(4n, php, U32.to_f32(0), U32.to_f32(0), U32.to_f32(0), dx, dy, dz, U32.to_f32(0), U32.to_f32(1))

def pixel(x: U32, y: U32, +hw: F32, +hh: F32) -> U32:
  +xf = U32.to_f32(x)
  +yf = U32.to_f32(y)
  l1 = subray(F32.div(F32.sub(F32.add(xf, fl(1, 4)), hw), hw), F32.div(F32.sub(hh, F32.add(yf, fl(1, 4))), hw))
  l2 = subray(F32.div(F32.sub(F32.add(xf, fl(3, 4)), hw), hw), F32.div(F32.sub(hh, F32.add(yf, fl(1, 4))), hw))
  l3 = subray(F32.div(F32.sub(F32.add(xf, fl(1, 4)), hw), hw), F32.div(F32.sub(hh, F32.add(yf, fl(3, 4))), hw))
  l4 = subray(F32.div(F32.sub(F32.add(xf, fl(3, 4)), hw), hw), F32.div(F32.sub(hh, F32.add(yf, fl(3, 4))), hw))
  F32.to_u32(F32.mul(U32.to_f32(255), clamp01(F32.mul(F32.add(F32.add(l1, l2), F32.add(l3, l4)), fl(1, 4)))))

def colf.px.go(t: Bool, xx: U32, y: U32, hw: F32, hh: F32) -> U32:
  match t:
    case False{}:
      0
    case True{}:
      pixel(xx, y, hw, hh)

def colf.px(+xx: U32, y: U32, w: U32, hw: F32, hh: F32) -> U32:
  colf.px.go(U32.is_lt(xx, w), xx, y, hw, hh)

def colf(+d: Nat, +x: U32, +y: U32, +w: U32, +hw: F32, +hh: F32) -> U32:
  match d:
    case 0n:
      colf.px(U32.and(U32.mul(x, 2654435761), 16383), y, w, hw, hh)
    case 1n+p:
      a b = colf(p, x, y, w, hw, hh) colf(p, U32.add(x, U32.shln(1, p)), y, w, hw, hh)
      U32.add(a, b)

def rowf(+d: Nat, +y: U32, +m: U32, +w: U32, +hw: F32, +hh: F32) -> U32:
  match d:
    case 0n:
      colf(14n, 0, U32.and(U32.mul(y, 1588635697), m), w, hw, hh)
    case 1n+p:
      a b = rowf(p, y, m, w, hw, hh) rowf(p, U32.add(y, U32.shln(1, p)), m, w, hw, hh)
      U32.add(a, b)

def rows() -> Nat:
  12n

def width() -> U32:
  6000

# small: rows 6n width 80 expect 402971; big expect 1924309504
def main() -> IO(Unit):
  +rr = rows()
  +w = width()
  hw = U32.to_f32(U32.div(w, 2))
  hh = U32.to_f32(U32.div(U32.shln(1, rr), 2))
  hm = U32.sub(U32.shln(1, rr), 1)
  IO.print(U32.show(rowf!(rr, 0, hm, w, hw, hh)))
