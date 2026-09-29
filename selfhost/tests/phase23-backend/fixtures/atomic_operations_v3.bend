import Base

def shown(r: Array<U32> & U32) -> IO(Array<U32>):
  (a, x) = r
  do IO<Array<U32>>:
    Unit <- IO.print(U32.show(x))
    return a

def shown_f(r: Array<F32> & F32) -> IO(Array<F32>):
  (a, x) = r
  do IO<Array<F32>>:
    Unit <- IO.print(F32.show(x))
    return a

def main() -> IO(Unit):
  do IO<Unit>:
    a0 : Array<U32> <- IO.pure(Array<U32>, [4294967295 : U32*2n])
    a1 : Array<U32> <- shown(Array.atomic.add(a0, 3, 2))
    a2 : Array<U32> <- shown(Array.atomic.min(a1, 1, 9))
    a3 : Array<U32> <- shown(Array.atomic.max(a2, 1, 20))
    a4 : Array<U32> <- shown(Array.atomic.and(a3, 1, 15))
    a5 : Array<U32> <- shown(Array.atomic.or(a4, 1, 8))
    a6 : Array<U32> <- shown(Array.atomic.xor(a5, 1, 3))
    a7 : Array<U32> <- shown(Array.atomic.exch(a6, 1, 4294967295))
    a8 : Array<U32> <- shown(Array.atomic.cas(a7, 1, 123, 5))
    a9 : Array<U32> <- shown(Array.atomic.cas(a8, 1, 4294967295, 7))
    a10 : Array<U32> <- shown(Array.get(U32, a9, 3))
    a11 : Array<U32> <- shown(Array.get(U32, a10, 0))
    f0 : Array<F32> <- IO.pure(Array<F32>, [16777216.0 : F32*1n])
    f1 : Array<F32> <- shown_f(Array.atomic.fadd(f0, 4294967295, 1.0))
    f2 : Array<F32> <- shown_f(Array.atomic.fadd(f1, 0, F32.neg(16777216.0)))
    f3 : Array<F32> <- shown_f(Array.atomic.fadd(f2, 0, 0.5))
    f4 : Array<F32> <- shown_f(Array.get(F32, f3, 0))
    return Unit{}

#|4294967295
#|1
#|1
#|20
#|4
#|12
#|15
#|4294967295
#|4294967295
#|7
#|4294967295
#|16777216
#|16777216
#|0
#|0.5
