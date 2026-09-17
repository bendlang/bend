# Map + Set: the crit-bit map behaves -- from_list, get with default,
# has, del, pop, right-biased union, code-point-ordered to_list, and
# Set as the Map<&2, Unit> alias (add/has/del/to_list). bend3's
# map_set_ops in bend's dialect: Map.get wants a Data value (U32),
# and the order check rides Map.keys joined plus Map.values
# folded to digits, since re-matching a match arm's field binder
# (bend3's entry-by-entry destructure) is walled here. Five checks,
# one digit each, the original's golden.
import Base

law Str.join.go:
  for xs : List<&2, String>
  for h  : String
  String

def Str.join.go(xs, h):
  match xs:
    case Nil{}:
      h
    case h2 <> t2:
      String.append(h, String.append(",", Str.join.go(t2, h2)))

law Str.join:
  for xs: List<&2, String>
  String

def Str.join(xs):
  match xs:
    case Nil{}:
      SNil{}
    case h <> t:
      Str.join.go(t, h)

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law got:
  for x: Maybe<&2, U32>
  for w: U32
  U32

def got(x, w):
  match x:
    case None{}:
      0
    case Some{v}:
      b2u(U32.is_eq(v, w))

law is_none:
  for x: Maybe<&2, U32>
  U32

def is_none(x):
  match x:
    case None{}:
      1
    case Some{v}:
      0

law digits:
  for vs  : List<&2, U32>
  for acc : U32
  U32

def digits(vs, acc):
  match vs:
    case Nil{}:
      acc
    case h <> t:
      digits(t, U32.add(U32.mul(acc, 10), h))

law m3:
  Map<&2, U32>

def m3():
  Map.from_list(&2, U32, [("apple", 1), ("app", 2), ("banana", 3)])

law chk_get:
  U32

law chk_get.s4:
  for a: U32
  for b: U32
  for c: U32
  for r: Map<&2, U32> & Bool
  U32

def chk_get.s4(a, b, c, r):
  (m4, hb) = r
  U32.mul(U32.mul(b2u(U32.is_eq(a, 1)), b2u(U32.is_eq(b, 2))), U32.mul(b2u(U32.is_eq(c, 99)), b2u(hb)))

law chk_get.s3:
  for a: U32
  for b: U32
  for r: Map<&2, U32> & U32
  U32

def chk_get.s3(a, b, r):
  (m3b, c) = r
  chk_get.s4(a, b, c, Map.has(&2, U32, m3b, "banana"))

law chk_get.s2:
  for a: U32
  for r: Map<&2, U32> & U32
  U32

def chk_get.s2(a, r):
  (m2, b) = r
  chk_get.s3(a, b, Map.get(U32, 99, m2, "nope"))

law chk_get.s1:
  for r: Map<&2, U32> & U32
  U32

def chk_get.s1(r):
  (m1, a) = r
  chk_get.s2(a, Map.get(U32, 0, m1, "app"))

def chk_get():
  chk_get.s1(Map.get(U32, 0, m3(), "apple"))

law chk_del:
  U32

law chk_del.s4:
  for h  : Bool
  for a  : U32
  for pv : Maybe<&2, U32>
  for r  : Map<&2, U32> & Maybe<&2, U32>
  U32

def chk_del.s4(h, a, pv, r):
  (m4, pv2) = r
  U32.mul(U32.mul(b2u(Bool.not(h)), b2u(U32.is_eq(a, 1))), U32.mul(got(pv, 3), is_none(pv2)))

law chk_del.s3:
  for h: Bool
  for a: U32
  for r: Map<&2, U32> & Maybe<&2, U32>
  U32

def chk_del.s3(h, a, r):
  (m3c, pv) = r
  chk_del.s4(h, a, pv, Map.pop(&2, U32, m3c, "banana"))

law chk_del.s2:
  for h: Bool
  for r: Map<&2, U32> & U32
  U32

def chk_del.s2(h, r):
  (m2, a) = r
  chk_del.s3(h, a, Map.pop(&2, U32, m2, "banana"))

law chk_del.s1:
  for r: Map<&2, U32> & Bool
  U32

def chk_del.s1(r):
  (m1, h) = r
  chk_del.s2(h, Map.get(U32, 0, m1, "apple"))

def chk_del():
  chk_del.s1(Map.has(&2, U32, Map.del(&2, U32, m3(), "app"), "app"))

law chk_union:
  U32

law chk_union.s3:
  for x: U32
  for y: U32
  for r: Map<&2, U32> & U32
  U32

def chk_union.s3(x, y, r):
  (u3, z) = r
  U32.mul(U32.mul(b2u(U32.is_eq(x, 1)), b2u(U32.is_eq(y, 20))), b2u(U32.is_eq(z, 30)))

law chk_union.s2:
  for x: U32
  for r: Map<&2, U32> & U32
  U32

def chk_union.s2(x, r):
  (u2, y) = r
  chk_union.s3(x, y, Map.get(U32, 0, u2, "c"))

law chk_union.s1:
  for r: Map<&2, U32> & U32
  U32

def chk_union.s1(r):
  (u1, x) = r
  chk_union.s2(x, Map.get(U32, 0, u1, "b"))

def chk_union():
  chk_union.s1(Map.get(U32, 0, Map.union(&2, U32, Map.from_list(&2, U32, [("a", 1), ("b", 2)]), Map.from_list(&2, U32, [("b", 20), ("c", 30)])), "a"))

law chk_order:
  U32

def chk_order():
  ks = Str.join(Map.keys(&2, U32, m3()))
  b2u(Bool.and(String.eq(ks, "app,apple,banana"), U32.is_eq(digits(Map.values(&2, U32, m3()), 0), 213)))

law chk_set:
  U32

law chk_set.s4:
  for hx : Bool
  for hz : Bool
  for hy : Bool
  for ks : String
  for r  : Map<&2, Unit> & Bool
  U32

def chk_set.s4(hx, hz, hy, ks, r):
  (t2, hx2) = r
  U32.mul(U32.mul(b2u(hx), b2u(Bool.not(hz))), U32.mul(b2u(String.eq(ks, "x,y")), U32.mul(b2u(Bool.not(hy)), b2u(hx2))))

law chk_set.s3:
  for hx : Bool
  for hz : Bool
  for ks : String
  for r  : Map<&2, Unit> & Bool
  U32

def chk_set.s3(hx, hz, ks, r):
  (t1, hy) = r
  chk_set.s4(hx, hz, hy, ks, Set.has(t1, "x"))

law chk_set.s2:
  for hx : Bool
  for r  : Map<&2, Unit> & Bool
  U32

def chk_set.s2(hx, r):
  (s2, hz) = r
  ks = Str.join(Set.to_list(s2))
  chk_set.s3(hx, hz, ks, Set.has(Set.del(Set.add(Set.add(Set.new(), "x"), "y"), "y"), "y"))

law chk_set.s1:
  for r: Map<&2, Unit> & Bool
  U32

def chk_set.s1(r):
  (s1, hx) = r
  chk_set.s2(hx, Set.has(s1, "z"))

def chk_set():
  chk_set.s1(Set.has(Set.add(Set.add(Set.add(Set.new(), "x"), "y"), "x"), "x"))

law main.out:
  U32

def main.out():
  U32.add(U32.add(U32.mul(chk_get(), 10000), U32.mul(chk_del(), 1000)), U32.add(U32.add(U32.mul(chk_union(), 100), U32.mul(chk_order(), 10)), chk_set()))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|11111
