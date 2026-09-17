# Map (string-keyed patricia tree): set/get/has/del/size/union --
# bend3's base_map_ops in bend's dialect: Map.get takes a Data V
# (U32) and a default, sizes are Nat, and
# every op takes the map first. The seven checks and their sum are
# the original's.
import Base

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case False{}:
      0
    case True{}:
      1

law m3:
  Map<&2, U32>

def m3():
  Map.set(&2, U32, Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32), "a", 1), "b", 2), "a", 5)

law chk_reads.c:
  for x: U32
  for y: U32
  for r: Map<&2, U32> & Bool
  U32

def chk_reads.c(x, y, r):
  (m4, h) = r
  b0 = b2u(U32.is_eq(x, 5))
  b1 = b2u(U32.is_eq(y, 0))
  b2 = b2u(h)
  b3 = b2u(Nat.is_eq(Map.size(&2, U32, m4), 2n))
  U32.add(U32.add(b0, b1), U32.add(b2, b3))

law chk_reads.b:
  for x: U32
  for r: Map<&2, U32> & U32
  U32

def chk_reads.b(x, r):
  (m2, y) = r
  chk_reads.c(x, y, Map.has(&2, U32, m2, "b"))

law chk_reads.a:
  for r: Map<&2, U32> & U32
  U32

def chk_reads.a(r):
  (m1, x) = r
  chk_reads.b(x, Map.get(U32, 0, m1, "zz"))

law chk_reads:
  U32

def chk_reads():
  chk_reads.a(Map.get(U32, 0, m3(), "a"))

law chk_del:
  U32

def chk_del():
  b2u(Nat.is_eq(Map.size(&2, U32, Map.del(&2, U32, m3(), "a")), 1n))

law chk_union.a:
  for r: Map<&2, U32> & U32
  U32

def chk_union.a(r):
  (u1, z) = r
  b5 = b2u(Nat.is_eq(Map.size(&2, U32, u1), 2n))
  b6 = b2u(U32.is_eq(z, 9))
  U32.add(b5, b6)

law chk_union:
  U32

def chk_union():
  chk_union.a(Map.get(U32, 0, Map.union(&2, U32, Map.del(&2, U32, m3(), "a"), Map.set(&2, U32, Map.new(&2, U32), "c", 9)), "c"))

law main.out:
  U32

def main.out():
  U32.add(chk_reads(), U32.add(chk_del(), chk_union()))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|7
