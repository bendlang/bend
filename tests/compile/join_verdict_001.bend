# compile_join_verdict_000's agreement law from the other walk order
# (the widest aux visited first, the 15-param failure band); bend's
# tocl has no verdict machinery, so the threaded-f32-state loop itself
# carries -- a float guard folded into each Nat countdown arm (the
# binder-order law moves the dispatch),
# 15 F32 params, answering bend3's 7 on the compiled lanes
import Base

law g9.go:
  for n   : Nat
  for f   : Bool
  for +x1 : F32
  for +x2 : F32
  for x3  : F32
  for x4  : F32
  for x5  : F32
  for x6  : F32
  for x7  : F32
  for x8  : F32
  for x9  : F32
  for x10 : F32
  for x11 : F32
  for x12 : F32
  for x13 : F32
  for x14 : F32
  for x15 : F32
  F32

def g9.go(n, f, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15):
  match n:
    case Zero{}:
      match f:
        case True{}:
          0.0
        case False{}:
          x1
    case Succ{k}:
      match f:
        case True{}:
          0.0
        case False{}:
          +y1 = (x1 + x2 : F32);
          g9.go(k, F32.is_lt(y1, 0.0), y1, (x2 * 1.0 : F32), (x3 * 1.0 : F32), (x4 * 1.0 : F32), (x5 * 1.0 : F32), (x6 * 1.0 : F32), (x7 * 1.0 : F32), (x8 * 1.0 : F32), (x9 * 1.0 : F32), (x10 * 1.0 : F32), (x11 * 1.0 : F32), (x12 * 1.0 : F32), (x13 * 1.0 : F32), (x14 * 1.0 : F32), (x15 * 1.0 : F32))

law g9:
  for n   : Nat
  for +x1 : F32
  for +x2 : F32
  for x3  : F32
  for x4  : F32
  for x5  : F32
  for x6  : F32
  for x7  : F32
  for x8  : F32
  for x9  : F32
  for x10 : F32
  for x11 : F32
  for x12 : F32
  for x13 : F32
  for x14 : F32
  for x15 : F32
  F32

def g9(n, x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15):
  g9.go(n, F32.is_lt(x1, 0.0), x1, x2, x3, x4, x5, x6, x7, x8, x9, x10, x11, x12, x13, x14, x15)

law main.out:
  U32

def main.out():
  F32.to_u32(g9(3n, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 15.0))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|7
