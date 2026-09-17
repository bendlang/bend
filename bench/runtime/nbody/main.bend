import Base
# nbody: chaotic three-body ensemble, f32, Plummer-softened,
# symplectic Euler (dt=0.001), ported 1-to-1 from Bend3's par_nbody.
# 2^(SY+3) independent random systems (prng cube positions,
# disc-rotation velocities, prng masses) each integrate ST steps with
# the full pairwise force math in f32 registers (Newton's third law:
# 3 pair kernels feed 6 accumulations per step, branchless end to
# end). The fork tree runs 2^SY leaves of 8 systems; each leaf digests
# every finished system into a position-hash checksum and a
# bound-energy bucket, accumulating an 8-bucket outcome histogram in
# scalar registers; histograms merge pairwise up the fork. Checksum
# mixes the histogram and the digest sum. Knobs: SY (tree depth,
# coarse), ST (steps, fine). Step and depth counters are Nats (no U32
# match in Bend4); float literals spell as fl(n, d) rationals (no
# float literal syntax in Bend4).
#
# Sizes (SY, ST): small (7n, 300n) expect 2215450620 (verified against
# a Bend3 C run on the cluster; the JS backend agrees), big (17n, 300n)
# expect 3516450380 (from the Bend3 header, verified on the cluster in
# seq, par and metal modes).

type Hs is Data:
  Hl{h0: U32, h1: U32, h2: U32, h3: U32, h4: U32, h5: U32, h6: U32, h7: U32, cs: U32}

type V2 is Data:
  V2{cs: U32, eb: U32}

def V2.cs(v: V2) -> U32:
  match v:
    case V2{c, b}:
      c

def V2.eb(v: V2) -> U32:
  match v:
    case V2{c, b}:
      b

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

def sel.go(x: U32, y: U32, z: Bool) -> U32:
  match z:
    case True{}:
      x
    case False{}:
      y

def sel(t: U32, x: U32, y: U32) -> U32:
  sel.go(x, y, U32.is_zero(t))

# a float literal n/d (one correctly-rounded division of two exact
# u32 conversions -- bit-exact vs the Bend3 C literal)
def fl(n: U32, d: U32) -> F32:
  F32.div(U32.to_f32(n), U32.to_f32(d))

# ST integration steps over one system's 21 f32 state registers; at 0,
# digest: position hash + total energy (kinetic - softened potential)
# bucketed by its bound magnitude
def loop3(s: Nat, +x0: F32, +y0: F32, +z0: F32, +x1: F32, +y1: F32, +z1: F32,
          +x2: F32, +y2: F32, +z2: F32, +vx0: F32, +vy0: F32, +vz0: F32,
          +vx1: F32, +vy1: F32, +vz1: F32, +vx2: F32, +vy2: F32, +vz2: F32,
          +m0: F32, +m1: F32, +m2: F32) -> V2:
  match s:
    case 0n:
      s0 = F32.add(F32.mul(vx0, vx0), F32.add(F32.mul(vy0, vy0), F32.mul(vz0, vz0)))
      s1 = F32.add(F32.mul(vx1, vx1), F32.add(F32.mul(vy1, vy1), F32.mul(vz1, vz1)))
      s2 = F32.add(F32.mul(vx2, vx2), F32.add(F32.mul(vy2, vy2), F32.mul(vz2, vz2)))
      k0 = F32.mul(F32.mul(fl(5, 10), m0), s0)
      k1 = F32.mul(F32.mul(fl(5, 10), m1), s1)
      k2 = F32.mul(F32.mul(fl(5, 10), m2), s2)
      ke = F32.add(k0, F32.add(k1, k2))
      +ax = F32.sub(x1, x0)
      +ay = F32.sub(y1, y0)
      +az = F32.sub(z1, z0)
      da = F32.add(F32.add(F32.mul(ax, ax), F32.add(F32.mul(ay, ay), F32.mul(az, az))), fl(5, 100))
      +bx = F32.sub(x2, x0)
      +by = F32.sub(y2, y0)
      +bz = F32.sub(z2, z0)
      db = F32.add(F32.add(F32.mul(bx, bx), F32.add(F32.mul(by, by), F32.mul(bz, bz))), fl(5, 100))
      +cx = F32.sub(x2, x1)
      +cy = F32.sub(y2, y1)
      +cz = F32.sub(z2, z1)
      dc = F32.add(F32.add(F32.mul(cx, cx), F32.add(F32.mul(cy, cy), F32.mul(cz, cz))), fl(5, 100))
      pa = F32.div(F32.mul(m0, m1), F32.sqrt(da))
      pb = F32.div(F32.mul(m0, m2), F32.sqrt(db))
      pc = F32.div(F32.mul(m1, m2), F32.sqrt(dc))
      pe = F32.add(pa, F32.add(pb, pc))
      e = F32.sub(ke, pe)
      +nb = F32.to_u32(F32.sub(U32.to_f32(0), e))
      eb = sel(b2u(U32.is_gt(nb, 7)), nb, 7)
      w0 = U32.add(U32.mul(F32.to_u32(F32.mul(F32.add(x0, U32.to_f32(8)), U32.to_f32(65536))), 31), F32.to_u32(F32.mul(F32.add(y0, U32.to_f32(8)), U32.to_f32(65536))))
      w1 = U32.add(U32.mul(F32.to_u32(F32.mul(F32.add(x1, U32.to_f32(8)), U32.to_f32(65536))), 31), F32.to_u32(F32.mul(F32.add(y1, U32.to_f32(8)), U32.to_f32(65536))))
      w2 = U32.add(U32.mul(F32.to_u32(F32.mul(F32.add(x2, U32.to_f32(8)), U32.to_f32(65536))), 31), F32.to_u32(F32.mul(F32.add(y2, U32.to_f32(8)), U32.to_f32(65536))))
      w3 = U32.add(U32.mul(F32.to_u32(F32.mul(F32.add(z0, U32.to_f32(8)), U32.to_f32(65536))), 31), F32.to_u32(F32.mul(F32.add(z1, U32.to_f32(8)), U32.to_f32(65536))))
      w4 = U32.add(U32.mul(w0, 2654435761), w1)
      w5 = U32.add(U32.mul(w4, 2654435761), w2)
      w6 = U32.add(U32.mul(w5, 2654435761), w3)
      cs = U32.add(U32.mul(w6, 2654435761), F32.to_u32(F32.mul(F32.add(z2, U32.to_f32(8)), U32.to_f32(65536))))
      V2{cs, eb}
    case 1n+p:
      +ax = F32.sub(x1, x0)
      +ay = F32.sub(y1, y0)
      +az = F32.sub(z1, z0)
      da = F32.add(F32.add(F32.mul(ax, ax), F32.add(F32.mul(ay, ay), F32.mul(az, az))), fl(5, 100))
      +ia = F32.div(U32.to_f32(1), F32.sqrt(da))
      +i3a = F32.mul(F32.mul(ia, ia), ia)
      +qax = F32.mul(ax, i3a)
      +qay = F32.mul(ay, i3a)
      +qaz = F32.mul(az, i3a)
      +bx = F32.sub(x2, x0)
      +by = F32.sub(y2, y0)
      +bz = F32.sub(z2, z0)
      db = F32.add(F32.add(F32.mul(bx, bx), F32.add(F32.mul(by, by), F32.mul(bz, bz))), fl(5, 100))
      +ib = F32.div(U32.to_f32(1), F32.sqrt(db))
      +i3b = F32.mul(F32.mul(ib, ib), ib)
      +qbx = F32.mul(bx, i3b)
      +qby = F32.mul(by, i3b)
      +qbz = F32.mul(bz, i3b)
      +cx = F32.sub(x2, x1)
      +cy = F32.sub(y2, y1)
      +cz = F32.sub(z2, z1)
      dc = F32.add(F32.add(F32.mul(cx, cx), F32.add(F32.mul(cy, cy), F32.mul(cz, cz))), fl(5, 100))
      +ic = F32.div(U32.to_f32(1), F32.sqrt(dc))
      +i3c = F32.mul(F32.mul(ic, ic), ic)
      +qcx = F32.mul(cx, i3c)
      +qcy = F32.mul(cy, i3c)
      +qcz = F32.mul(cz, i3c)
      +nvx0 = F32.add(vx0, F32.mul(F32.add(F32.mul(qax, m1), F32.mul(qbx, m2)), fl(1, 1000)))
      +nvy0 = F32.add(vy0, F32.mul(F32.add(F32.mul(qay, m1), F32.mul(qby, m2)), fl(1, 1000)))
      +nvz0 = F32.add(vz0, F32.mul(F32.add(F32.mul(qaz, m1), F32.mul(qbz, m2)), fl(1, 1000)))
      +nvx1 = F32.add(vx1, F32.mul(F32.sub(F32.mul(qcx, m2), F32.mul(qax, m0)), fl(1, 1000)))
      +nvy1 = F32.add(vy1, F32.mul(F32.sub(F32.mul(qcy, m2), F32.mul(qay, m0)), fl(1, 1000)))
      +nvz1 = F32.add(vz1, F32.mul(F32.sub(F32.mul(qcz, m2), F32.mul(qaz, m0)), fl(1, 1000)))
      +nvx2 = F32.sub(vx2, F32.mul(F32.add(F32.mul(qbx, m0), F32.mul(qcx, m1)), fl(1, 1000)))
      +nvy2 = F32.sub(vy2, F32.mul(F32.add(F32.mul(qby, m0), F32.mul(qcy, m1)), fl(1, 1000)))
      +nvz2 = F32.sub(vz2, F32.mul(F32.add(F32.mul(qbz, m0), F32.mul(qcz, m1)), fl(1, 1000)))
      loop3(p,
            F32.add(x0, F32.mul(nvx0, fl(1, 1000))), F32.add(y0, F32.mul(nvy0, fl(1, 1000))), F32.add(z0, F32.mul(nvz0, fl(1, 1000))),
            F32.add(x1, F32.mul(nvx1, fl(1, 1000))), F32.add(y1, F32.mul(nvy1, fl(1, 1000))), F32.add(z1, F32.mul(nvz1, fl(1, 1000))),
            F32.add(x2, F32.mul(nvx2, fl(1, 1000))), F32.add(y2, F32.mul(nvy2, fl(1, 1000))), F32.add(z2, F32.mul(nvz2, fl(1, 1000))),
            nvx0, nvy0, nvz0, nvx1, nvy1, nvz1, nvx2, nvy2, nvz2, m0, m1, m2)

# one random system: three seeded bodies, ST steps, digest
def sim(+sd: U32, st: Nat) -> V2:
  a1 = prng(U32.mul(U32.inc(U32.mul(sd, 12)), 2654435761))
  a2 = prng(U32.mul(U32.add(U32.mul(sd, 12), 2), 2654435761))
  a3 = prng(U32.mul(U32.add(U32.mul(sd, 12), 3), 2654435761))
  a4 = prng(U32.mul(U32.add(U32.mul(sd, 12), 4), 2654435761))
  b1 = prng(U32.mul(U32.add(U32.mul(sd, 12), 5), 2654435761))
  b2 = prng(U32.mul(U32.add(U32.mul(sd, 12), 6), 2654435761))
  b3 = prng(U32.mul(U32.add(U32.mul(sd, 12), 7), 2654435761))
  b4 = prng(U32.mul(U32.add(U32.mul(sd, 12), 8), 2654435761))
  c1 = prng(U32.mul(U32.add(U32.mul(sd, 12), 9), 2654435761))
  c2 = prng(U32.mul(U32.add(U32.mul(sd, 12), 10), 2654435761))
  c3 = prng(U32.mul(U32.add(U32.mul(sd, 12), 11), 2654435761))
  c4 = prng(U32.mul(U32.add(U32.mul(sd, 12), 12), 2654435761))
  +x0 = F32.sub(F32.div(U32.to_f32(U32.and(a1, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  +y0 = F32.sub(F32.div(U32.to_f32(U32.and(a2, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  z0 = F32.sub(F32.div(U32.to_f32(U32.and(a3, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  m0 = F32.add(F32.div(U32.to_f32(U32.and(a4, 65535)), U32.to_f32(65536)), fl(5, 10))
  +x1 = F32.sub(F32.div(U32.to_f32(U32.and(b1, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  +y1 = F32.sub(F32.div(U32.to_f32(U32.and(b2, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  z1 = F32.sub(F32.div(U32.to_f32(U32.and(b3, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  m1 = F32.add(F32.div(U32.to_f32(U32.and(b4, 65535)), U32.to_f32(65536)), fl(5, 10))
  +x2 = F32.sub(F32.div(U32.to_f32(U32.and(c1, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  +y2 = F32.sub(F32.div(U32.to_f32(U32.and(c2, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  z2 = F32.sub(F32.div(U32.to_f32(U32.and(c3, 65535)), U32.to_f32(32768)), U32.to_f32(1))
  m2 = F32.add(F32.div(U32.to_f32(U32.and(c4, 65535)), U32.to_f32(65536)), fl(5, 10))
  vx0 = F32.mul(y0, fl(1, 10))
  vy0 = F32.sub(U32.to_f32(0), F32.mul(x0, fl(1, 10)))
  vx1 = F32.mul(y1, fl(1, 10))
  vy1 = F32.sub(U32.to_f32(0), F32.mul(x1, fl(1, 10)))
  vx2 = F32.mul(y2, fl(1, 10))
  vy2 = F32.sub(U32.to_f32(0), F32.mul(x2, fl(1, 10)))
  loop3(st, x0, y0, z0, x1, y1, z1, x2, y2, z2,
        vx0, vy0, U32.to_f32(0), vx1, vy1, U32.to_f32(0), vx2, vy2, U32.to_f32(0), m0, m1, m2)

# fork leaf: 8 systems; outcome histogram in 8 scalar counters plus a
# position-weighted digest accumulator
def chunk(+j: Nat, +i: U32, +st: Nat, h0: U32, h1: U32, h2: U32, h3: U32,
          h4: U32, h5: U32, h6: U32, h7: U32, cs: U32) -> Hs:
  match j:
    case 0n:
      Hl{h0, h1, h2, h3, h4, h5, h6, h7, cs}
    case 1n+p:
      +sy = U32.add(i, U32.from_nat(p))
      +w = sim(sy, st)
      +bb = V2.eb(w)
      m0 = b2u(U32.is_eq(bb, 0))
      m1 = b2u(U32.is_eq(bb, 1))
      m2 = b2u(U32.is_eq(bb, 2))
      m3 = b2u(U32.is_eq(bb, 3))
      m4 = b2u(U32.is_eq(bb, 4))
      m5 = b2u(U32.is_eq(bb, 5))
      m6 = b2u(U32.is_eq(bb, 6))
      m7 = b2u(U32.is_eq(bb, 7))
      chunk(p, i, st,
            U32.add(h0, m0), U32.add(h1, m1), U32.add(h2, m2), U32.add(h3, m3),
            U32.add(h4, m4), U32.add(h5, m5), U32.add(h6, m6), U32.add(h7, m7),
            U32.add(cs, U32.mul(V2.cs(w), U32.inc(U32.mul(sy, 2654435761)))))

def hzip(a: Hs, b: Hs) -> Hs:
  match a b:
    case Hl{a0, a1, a2, a3, a4, a5, a6, a7, ac} Hl{b0, b1, b2, b3, b4, b5, b6, b7, bc}:
      Hl{U32.add(a0, b0), U32.add(a1, b1), U32.add(a2, b2), U32.add(a3, b3), U32.add(a4, b4), U32.add(a5, b5), U32.add(a6, b6), U32.add(a7, b7), U32.add(ac, bc)}

def batch(+d: Nat, +i: U32, +st: Nat) -> Hs:
  match d:
    case 0n:
      chunk(8n, i, st, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    case 1n+p:
      a b = batch(p, i, st) batch(p, U32.add(i, U32.shln(8, p)), st)
      hzip(a, b)

def run.fin(t: Hs) -> U32:
  match t:
    case Hl{h0, h1, h2, h3, h4, h5, h6, h7, cs}:
      g1 = U32.add(U32.mul(h0, 2654435761), h1)
      g2 = U32.add(U32.mul(g1, 2654435761), h2)
      g3 = U32.add(U32.mul(g2, 2654435761), h3)
      g4 = U32.add(U32.mul(g3, 2654435761), h4)
      g5 = U32.add(U32.mul(g4, 2654435761), h5)
      g6 = U32.add(U32.mul(g5, 2654435761), h6)
      g7 = U32.add(U32.mul(g6, 2654435761), h7)
      U32.add(U32.mul(g7, 2654435761), cs)

def run(d: Nat, ts: Nat) -> U32:
  run.fin(batch(d, 0, ts))

def sy() -> Nat:
  17n

def st() -> Nat:
  300n

# small: run!(7n, st()) expect 2215450620; big run!(sy(), st()) expect 3516450380
def main() -> IO(Unit):
  IO.print(U32.show(run!(sy(), st())))
