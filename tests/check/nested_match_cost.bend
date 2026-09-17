# bend3's gen_matches miniature: deep nested dispatch with guarded
# arms. The counter is gone (no --stats); the dispatch tree carries
# whole -- the inner match folds into nested ctor patterns (binder
# order law), equality guards become U32.is_eq Bools dispatched by
# Bool-matching worker defs (the if sugar is gone with the
# lambda-match application ban), and the W arm's countdown rides
# U32.sub behind an is_eq(k, 0) guard
import Base

type T7 is Data:
  L7{v: U32}
  B7{a: T7, b: T7}
  W7{n: U32, t: T7}

law m0.sel:
  for v  : U32
  for f0 : Bool
  for f1 : Bool
  U32

def m0.sel(v, f0, f1):
  match f0:
    case True{}:
      (v + 0 : U32)
    case False{}:
      match f1:
        case True{}:
          (v * 2 : U32)
        case False{}:
          v

law m0.w:
  for n: U32
  for r: U32
  for z: Bool
  U32

def m0.w(n, r, z):
  match z:
    case True{}:
      n
    case False{}:
      r

law m0:
  for  t: T7
  for +k: U32
  U32

def m0(t, k):
  match t:
    case L7{v}:
      m0.sel(v, U32.is_eq(k, 0), U32.is_eq(k, 1))
    case B7{L7{v}, b}:
      (v + m0(b, k) : U32)
    case B7{B7{c, d}, b2}:
      (m0(c, k) + m0(d, k) : U32)
    case B7{W7{n, t2}, b3}:
      (n + m0(t2, k) : U32)
    case W7{n, t2}:
      m0.w(n, m0(t2, U32.sub(k, 1)), U32.is_eq(k, 0))

law main.out:
  Nat

def main.out():
  U32.to_nat(m0(B7{L7{3}, W7{2, L7{5}}}, 1))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|8n
