# A wide def on a lane's stack (#1393): tall's fork holds six 40-word records
# across its first call and hands one to each later call, so it has 443 words
# on the stack. A return into an exit frame gives back whole defs, so a spill
# under tall comes back with all 443, and the next frame must still fit.
import Base

type Q is Data:
  Q{a: U32, b: U32, c: U32, d: U32, e: U32}

def leaf(+k: U32) -> Q:
  Q{k, (k * 3 : U32), (k * 5 : U32), (k * 7 : U32), (k + 9 : U32)}

def sum(q: Q) -> U32:
  match q:
    case Q{a, b, c, d, e}:
      (((((a + b : U32) * 3 : U32) + c : U32)
        + ((d + e : U32) * 5 : U32) : U32) * 7 : U32)

type P is Data:
  P{a: Q, b: Q, c: Q, d: Q, e: Q, f: Q, g: Q, h: Q}

def wide(+k: U32) -> P:
  P{leaf(k), leaf((k + 1 : U32)), leaf((k + 2 : U32)), leaf((k + 3 : U32)),
    leaf((k + 4 : U32)), leaf((k + 5 : U32)), leaf((k + 6 : U32)),
    leaf((k + 7 : U32))}

def flip(p: P, +k: U32) -> P:
  match p:
    case P{a, b, c, d, e, f, g, h}:
      P{h, g, f, e, d, c, b, leaf((sum(a) + k : U32))}

def fold(p: P) -> U32:
  match p:
    case P{a, b, c, d, e, f, g, h}:
      (((sum(a) + sum(b) : U32) + (sum(c) + sum(d) : U32) : U32)
        + ((sum(e) + sum(f) : U32) + (sum(g) + sum(h) : U32) : U32) : U32)

def tall(n: Nat, +k: U32) -> U32:
  match n:
    case 0n:
      k
    case 1n+p:
      u = wide(k)
      v = wide((k + 1 : U32))
      w = wide((k + 2 : U32))
      x = wide((k + 3 : U32))
      y = wide((k + 4 : U32))
      z = wide((k + 5 : U32))
      a b c d e f g = tall(p, (k + 1 : U32))
        flip(u, k) flip(v, k) flip(w, k) flip(x, k) flip(y, k) flip(z, k)
      ((a * 31 : U32) + ((fold(b) + fold(c) : U32)
        + ((fold(d) + fold(e) : U32) + (fold(f) + fold(g) : U32) : U32) : U32)
        : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(tall!(40n, 0)))
    IO.print(U32.show(tall!(40n, 1)))

#|2730820976
#|2131216241
