# Monte Carlo pi in F64, 2^20 samples over a balanced split with two
# independent LCG streams; the ! puts the same tree on the GPU where the
# build has one -- all lanes must print the same count
import Base

def lcg(s: U32) -> U32:
  U32.add(U32.mul(s, 1664525), 1013904223)

def lcg2(s: U32) -> U32:
  U32.add(U32.mul(s, 1103515245), 12345)

def hb(inside: Bool) -> U32:
  match inside:
    case True{}:
      1
    case False{}:
      0

def hit(+seed: U32) -> U32:
  s1 = lcg(lcg(seed))
  s2 = lcg2(lcg2(seed))
  x = F64.div(U32.to_f64(s1), 4294967296.0d)
  y = F64.div(U32.to_f64(s2), 4294967296.0d)
  +dx = F64.sub(x, 0.5d)
  +dy = F64.sub(y, 0.5d)
  d2 = F64.add(F64.mul(dx, dx), F64.mul(dy, dy))
  hb(F64.is_lt(d2, 0.25d))

def mc(+d: Nat, +seed: U32, +jump: U32) -> U32:
  match d:
    case 0n:
      hit(seed)
    case 1n+p:
      +j2 = U32.div(jump, 2)
      a b = mc(p, seed, j2) mc(p, U32.add(seed, jump), j2)
      U32.add(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    +hits : U32 = mc!(20n, 1, 524288)
    IO.print(F64.show(F64.mul(4.0d, F64.div(U32.to_f64(hits), 1048576.0d))))
    IO.print(U32.show(hits))

#|3.141498565673828
#|823525
