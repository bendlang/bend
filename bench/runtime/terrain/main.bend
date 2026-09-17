import Base
# terrain: procedural terrain tile pipeline, ported 1-to-1 from Bend3's
# par_terrain -- the suite's array write/read stress case. 2^SIZE
# independent 64x64 tiles fork as a balanced tree; each tile fills its
# own 4096-slot heightmap with bilinear value noise (8.8 fixed-point
# lattice hashes, one array write per cell), runs EPASS in-place
# thermal-relaxation sweeps (each cell reads itself and its 4 clamped
# neighbours, Gauss-Seidel scan order, plus a pass-salted 1-bit
# roughening so the field never converges), then buckets every cell
# into a 64-bin height histogram (read + bump) and folds map and
# histogram into a position-weighted scalar; tile scalars sum up the
# fork tree. Knobs: SIZE (2^SIZE tiles, 2x per notch), EPASS
# (relaxation sweeps per tile, the fine linear knob).
#
# NO TUNING: this file is the elegant spelling. A register-threading
# rewrite of the erode sweep (carrying prev/cur across the recursion
# to cut 2 array reads) was reverted: it tuned the bench, not the
# compiler. The sweep's memory-bound GPU profile is the honest result.
#
# Port deviations from the Bend3 source (semantics preserved exactly):
# - `h[i]` reads become Array.get(U32, h, i), `h[i] <- v` writes become
#   Array.swap(U32, h, i, v); both hand the array back.
# - Bend3's flat literal `![4095:0, _:0; 4096]` becomes
#   [0 : U32*4096n] (the C backend lays it flat in one block).
# - Cell, sweep and depth counters are Nats (no U32 match in Bend4);
#   the pass salt `1+p` reads back as U32.inc(U32.from_nat(p)).
# - `(xc > 0)` as a 0/1 word becomes b2u(U32.is_gt(xc, 0)).
# - Words used twice ride `+` binders (Bend3 auto-copied them). A
#   tuple pattern cannot bind `+`, so hist hands the height it read
#   twice on to a continuation def (hist_go).
#
# Sizes (SIZE, EPASS): small (4n, 5n) expect 4236200168 (verified
# against a Bend3 C run on the cluster), big (16n, 5n) expect
# 2572468224 (the Bend3 header's number, re-verified on the cluster).

def b2u(b: Bool) -> U32:
  match b:
    case False{}:
      0
    case True{}:
      1

def prng(+x: U32) -> U32:
  +b = U32.xor(x, U32.shln(x, 13n))
  +d = U32.xor(b, U32.shrn(b, 17n))
  U32.xor(d, U32.shln(d, 5n))

# lattice corner hash -> 0..255
def hsh(gx: U32, gz: U32) -> U32:
  U32.and(prng(U32.xor(U32.mul(gx, 2654435761), U32.mul(gz, 340573321))), 255)

# value noise at 8.8 fixed-point (x, z): bilinear lerp of 4 corner
# hashes
def ground(+x: U32, +z: U32) -> U32:
  +gx = U32.and(U32.shrn(x, 8n), 63)
  +gz = U32.and(U32.shrn(z, 8n), 63)
  +fx = U32.and(x, 255)
  +fz = U32.and(z, 255)
  +gx1 = U32.and(U32.inc(gx), 63)
  +gz1 = U32.and(U32.inc(gz), 63)
  h00 = hsh(gx, gz)
  h10 = hsh(gx1, gz)
  h01 = hsh(gx, gz1)
  h11 = hsh(gx1, gz1)
  t0 = U32.shrn(U32.add(U32.mul(h00, U32.sub(256, fx)), U32.mul(h10, fx)), 8n)
  t1 = U32.shrn(U32.add(U32.mul(h01, U32.sub(256, fx)), U32.mul(h11, fx)), 8n)
  U32.shrn(U32.add(U32.mul(t0, U32.sub(256, fz)), U32.mul(t1, fz)), 8n)

# noise-fill one tile: one write per cell, sampled at 64 sub-lattice
# units per cell from the tile's world offset
def fill(+j: Nat, +ox: U32, +oz: U32, r: Array<U32> & U32) -> Array<U32>:
  match j:
    case 0n:
      (h, z) = r
      h
    case 1n+q:
      (h, z) = r
      +i = U32.sub(4096, U32.inc(U32.from_nat(q)))
      +g = ground(U32.shln(U32.add(ox, U32.and(i, 63)), 6n), U32.shln(U32.add(oz, U32.shrn(i, 6n)), 6n))
      fill(q, ox, oz, Array.swap(U32, h, i, g))

# one relaxation cell: 5 reads + 1 write; neighbours clamp at the tile
# edge; the pass-salted bit keeps the field from ever converging.
# four cells unroll per erode turn: every Array op rides inline in
# the next stage def's argument, so the whole 24-op chain fuses into
# one machine segment; only the last write's pair crosses back into
# the erode spin, destructured as the r column of the next turn
def erode.f5(+i: U32, +p: U32, hc: U32, hl: U32, hr: U32, hu: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h5, hd) = r
  +rough = U32.and(prng(U32.xor(i, U32.mul(p, 2654435761))), 1)
  +nv = U32.add(U32.shrn(U32.add(U32.add(U32.add(U32.add(U32.mul(hc, 4), hl), hr), hu), hd), 3n), rough)
  Array.swap(U32, h5, i, nv)

def erode.f4(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, hr: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h4, hu) = r
  erode.f5(i, p, hc, hl, hr, hu, Array.get(U32, h4, U32.add(i, U32.shln(b2u(U32.is_lt(zc, 63)), 6n))))

def erode.f3(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h3, hr) = r
  erode.f4(i, p, zc, hc, hl, hr, Array.get(U32, h3, U32.sub(i, U32.shln(b2u(U32.is_gt(zc, 0)), 6n))))

def erode.f2(+i: U32, +p: U32, +xc: U32, +zc: U32, hc: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h2, hl) = r
  erode.f3(i, p, zc, hc, hl, Array.get(U32, h2, U32.add(i, b2u(U32.is_lt(xc, 63)))))

def erode.f1(+i: U32, +p: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (h1, hc) = r
  +xc = U32.and(i, 63)
  +zc = U32.shrn(i, 6n)
  erode.f2(i, p, xc, zc, hc, Array.get(U32, h1, U32.sub(i, b2u(U32.is_gt(xc, 0)))))

def erode.f0(+i: U32, +p: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (h0, old) = r
  erode.f1(i, p, Array.get(U32, h0, i))

def erode.d5(+i: U32, +p: U32, hc: U32, hl: U32, hr: U32, hu: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h5, hd) = r
  +rough = U32.and(prng(U32.xor(i, U32.mul(p, 2654435761))), 1)
  +nv = U32.add(U32.shrn(U32.add(U32.add(U32.add(U32.add(U32.mul(hc, 4), hl), hr), hu), hd), 3n), rough)
  erode.f0(U32.inc(i), p, Array.swap(U32, h5, i, nv))

def erode.d4(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, hr: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h4, hu) = r
  erode.d5(i, p, hc, hl, hr, hu, Array.get(U32, h4, U32.add(i, U32.shln(b2u(U32.is_lt(zc, 63)), 6n))))

def erode.d3(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h3, hr) = r
  erode.d4(i, p, zc, hc, hl, hr, Array.get(U32, h3, U32.sub(i, U32.shln(b2u(U32.is_gt(zc, 0)), 6n))))

def erode.d2(+i: U32, +p: U32, +xc: U32, +zc: U32, hc: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h2, hl) = r
  erode.d3(i, p, zc, hc, hl, Array.get(U32, h2, U32.add(i, b2u(U32.is_lt(xc, 63)))))

def erode.d1(+i: U32, +p: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (h1, hc) = r
  +xc = U32.and(i, 63)
  +zc = U32.shrn(i, 6n)
  erode.d2(i, p, xc, zc, hc, Array.get(U32, h1, U32.sub(i, b2u(U32.is_gt(xc, 0)))))

def erode.d0(+i: U32, +p: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (h0, old) = r
  erode.d1(i, p, Array.get(U32, h0, i))

def erode.b5(+i: U32, +p: U32, hc: U32, hl: U32, hr: U32, hu: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h5, hd) = r
  +rough = U32.and(prng(U32.xor(i, U32.mul(p, 2654435761))), 1)
  +nv = U32.add(U32.shrn(U32.add(U32.add(U32.add(U32.add(U32.mul(hc, 4), hl), hr), hu), hd), 3n), rough)
  erode.d0(U32.inc(i), p, Array.swap(U32, h5, i, nv))

def erode.b4(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, hr: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h4, hu) = r
  erode.b5(i, p, hc, hl, hr, hu, Array.get(U32, h4, U32.add(i, U32.shln(b2u(U32.is_lt(zc, 63)), 6n))))

def erode.b3(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h3, hr) = r
  erode.b4(i, p, zc, hc, hl, hr, Array.get(U32, h3, U32.sub(i, U32.shln(b2u(U32.is_gt(zc, 0)), 6n))))

def erode.b2(+i: U32, +p: U32, +xc: U32, +zc: U32, hc: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h2, hl) = r
  erode.b3(i, p, zc, hc, hl, Array.get(U32, h2, U32.add(i, b2u(U32.is_lt(xc, 63)))))

def erode.b1(+i: U32, +p: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (h1, hc) = r
  +xc = U32.and(i, 63)
  +zc = U32.shrn(i, 6n)
  erode.b2(i, p, xc, zc, hc, Array.get(U32, h1, U32.sub(i, b2u(U32.is_gt(xc, 0)))))

def erode.b0(+i: U32, +p: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (h0, old) = r
  erode.b1(i, p, Array.get(U32, h0, i))

def erode.a5(+i: U32, +p: U32, hc: U32, hl: U32, hr: U32, hu: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h5, hd) = r
  +rough = U32.and(prng(U32.xor(i, U32.mul(p, 2654435761))), 1)
  +nv = U32.add(U32.shrn(U32.add(U32.add(U32.add(U32.add(U32.mul(hc, 4), hl), hr), hu), hd), 3n), rough)
  erode.b0(U32.inc(i), p, Array.swap(U32, h5, i, nv))

def erode.a4(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, hr: U32,
             r: Array<U32> & U32) -> Array<U32> & U32:
  (h4, hu) = r
  erode.a5(i, p, hc, hl, hr, hu, Array.get(U32, h4, U32.add(i, U32.shln(b2u(U32.is_lt(zc, 63)), 6n))))

def erode.a3(+i: U32, +p: U32, +zc: U32, hc: U32, hl: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h3, hr) = r
  erode.a4(i, p, zc, hc, hl, hr, Array.get(U32, h3, U32.sub(i, U32.shln(b2u(U32.is_gt(zc, 0)), 6n))))

def erode.a2(+i: U32, +p: U32, +xc: U32, +zc: U32, hc: U32, r: Array<U32> & U32
             ) -> Array<U32> & U32:
  (h2, hl) = r
  erode.a3(i, p, zc, hc, hl, Array.get(U32, h2, U32.add(i, b2u(U32.is_lt(xc, 63)))))

def erode.a1(+i: U32, +p: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (h1, hc) = r
  +xc = U32.and(i, 63)
  +zc = U32.shrn(i, 6n)
  erode.a2(i, p, xc, zc, hc, Array.get(U32, h1, U32.sub(i, b2u(U32.is_gt(xc, 0)))))

def erode.go(+i: U32, +p: U32, h: Array<U32>) -> Array<U32> & U32:
  erode.a1(i, p, Array.get(U32, h, i))

# one Gauss-Seidel sweep over the tile, ascending scan order, four
# cells per turn (j counts quads); the quad's final write pair rides
# into the next turn as the r column
def erode(+j: Nat, +p: U32, r: Array<U32> & U32) -> Array<U32>:
  match j:
    case 0n:
      (h, z) = r
      h
    case 1n+q:
      (h, z) = r
      +i = U32.sub(4096, U32.shln(U32.inc(U32.from_nat(q)), 2n))
      erode(q, p, erode.go(i, p, h))

def smooth(+p: Nat, h: Array<U32>) -> Array<U32>:
  match p:
    case 0n:
      h
    case 1n+q:
      h2 = erode(1024n, U32.inc(U32.from_nat(q)), (h, 0))
      smooth(q, h2)

# histogram fold: mix every bucket count, position-weighted; the
# current read rides in as the (array, count) pair r, and each step
# issues the next read (the final step issues one masked dead read)
def gfold(+j: Nat, r: Array<U32> & U32, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+q:
      (g2, c) = r
      +i = U32.sub(63, U32.from_nat(q))
      gfold(q, Array.get(U32, g2, U32.inc(i)), U32.xor(U32.mul(acc, 2654435761), U32.mul(c, U32.add(i, 3))))

# bucket increment: the (array, count) read pair arrives as a
# parameter and the bumped bucket's write pair is handed back
def hist.bump(+b: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (g2, c) = r
  Array.swap(U32, g2, b, U32.inc(c))

# per cell: read the height, bump its histogram bucket, mix the height
# into the running position-weighted checksum; the current height read
# rides in as the pair r (the final step issues one masked dead read)
def hist(+j: Nat, r: Array<U32> & U32, rg: Array<U32> & U32, acc: U32) -> U32:
  match j:
    case 0n:
      (g, z) = rg
      gfold(64n, Array.get(U32, g, 0), acc)
    case 1n+q:
      (h2, +v) = r
      (g, z) = rg
      +i = U32.sub(4095, U32.from_nat(q))
      +b = U32.and(U32.shrn(v, 2n), 63)
      hist(q, Array.get(U32, h2, U32.inc(i)), hist.bump(b, Array.get(U32, g, b)),
        U32.add(U32.mul(acc, 2654435761), U32.mul(v, U32.inc(i))))

# one tile: fill, EPASS relaxation sweeps, histogram + fold
def tile(+t: U32, e: Nat) -> U32:
  a = [0 : U32*4096n]
  h0 = fill(4096n, U32.shln(U32.and(t, 255), 6n), U32.shln(U32.shrn(t, 8n), 6n), (a, 0))
  h1 = smooth(e, h0)
  b = [0 : U32*64n]
  hist(4096n, Array.get(U32, h1, 0), (b, 0), U32.inc(t))

def batch(+d: Nat, +t: U32, +e: Nat) -> U32:
  match d:
    case 0n:
      tile(t, e)
    case 1n+q:
      a b = batch(q, t, e) batch(q, U32.add(t, U32.shln(1, q)), e)
      U32.add(a, b)

def size() -> Nat:
  16n

def epass() -> Nat:
  5n

# small: batch!(4n, 0, epass()) expect 4236200168; big batch!(size(), 0,
# epass()) expect 2572468224
def main() -> IO(Unit):
  IO.print(U32.show(batch!(size(), 0, epass())))
