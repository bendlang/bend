import Base

# The delayed write is the FIRST Tuple field; the accumulator is second.
def fold.step(+i: U32, +acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, v) = r
  +next = U32.add(acc, v)
  (a[i] <- U32.xor(next, i), next)

def fold.cell(+i: U32, st: Array<U32> & U32) -> Array<U32> & U32:
  (a, acc) = st
  fold.step(i, acc, Array.get(U32, a, i))

def fold.loop(+n: Nat, +i: U32, st: Array<U32> & U32) -> Array<U32> & U32:
  match n:
    case 0n:
      st
    case 1n+q:
      fold.loop(q, U32.inc(i), fold.cell(i, st))

def fold.finish(r: Array<U32> & U32) -> U32:
  (a, acc) = r
  acc

def bench(+n: U32, seed: U32) -> U32:
  fold.finish(fold.loop(U32.to_nat(n), 0, ([seed : U32*128n], 0)))

def main() -> IO(Unit):
  IO.print(U32.show(bench(32, 17)))
