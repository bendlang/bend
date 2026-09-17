# the new base text surface at runtime: Nat.show/Nat.read round trips
# and rejections, String.cmp's code-point order (a shorter prefix
# sorts first), eq/length edges, and split/join round trips
import Base

law Char.eq.go:
  for r: (Char & Char) & Cmp
  (Char & Char) & Bool

def Char.eq.go(r):
  ((a2, b2), c) = r
  ((a2, b2), Cmp.is_eq(c))

law Char.eq:
  for a: Char
  for b: Char
  (Char & Char) & Bool

def Char.eq(a, b):
  Char.eq.go(Char.cmp(a, b))

law bu:
  for b: Bool
  U32

def bu(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law rdn.go:
  for w: Nat
  for m: Maybe<&2, Nat>
  Bool

def rdn.go(w, m):
  match m:
    case None{}:
      False{}
    case Some{v}:
      Nat.is_eq(v, w)

law rdn:
  for s: String
  for w: Nat
  Bool

def rdn(s, w):
  rdn.go(w, Nat.read(s))

law rdn_none.go:
  for m: Maybe<&2, Nat>
  Bool

def rdn_none.go(m):
  match m:
    case None{}:
      True{}
    case Some{v}:
      False{}

law rdn_none:
  for s: String
  Bool

def rdn_none(s):
  rdn_none.go(Nat.read(s))

law scmp.go:
  for r: (String & String) & Cmp
  Cmp

def scmp.go(r):
  ((a2, b2), c) = r
  c

law scmp:
  for a: String
  for b: String
  Cmp

def scmp(a, b):
  scmp.go(String.cmp(a, b))

law llen:
  for xs: List<&2, String>
  Nat

def llen(xs):
  List.length(&2, String, xs)

law main.out:
  U32

def main.out():
  b0 = bu(String.eq(Nat.show(0n), "0"))
  b1 = bu(String.eq(Nat.show(105n), "105"))
  b2 = bu(rdn("678", 678n))
  b3 = bu(rdn(Nat.show(731n), 731n))
  b4 = bu(rdn_none("12x"))
  b5 = bu(rdn_none(""))
  b6 = bu(Cmp.is_lt(scmp("app", "apple")))
  b7 = bu(Cmp.is_gt(scmp("b", "apple")))
  b8 = bu(Cmp.is_eq(scmp("", "")))
  b9 = bu(Bool.not(String.eq("a", "b")))
  b10 = bu(Nat.is_eq(String.length(""), 0n))
  b11 = bu(Nat.is_eq(llen(String.split("", ',')), 1n))
  b12 = bu(Nat.is_eq(llen(String.split(",", ',')), 2n))
  b13 = bu(String.eq(String.join(String.split("x", ','), ","), "x"))
  s0 = U32.add(U32.add(U32.add(b0, b1), U32.add(b2, b3)), U32.add(U32.add(b4, b5), U32.add(b6, b7)))
  U32.add(s0, U32.add(U32.add(U32.add(b8, b9), U32.add(b10, b11)), U32.add(b12, b13)))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|14
