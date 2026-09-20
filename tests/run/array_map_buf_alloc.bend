# A packed numeric destination is a BUF block: its physical class is one
# below the logical class in the term. Allocating it in the logical class
# frees it into the wrong size list, so repeated maps cannot reuse the block
# and resident memory grows with every turn. This spins 20,000 maps of a
# 4096 element U32 array through unchanged Array.map calls.
import Base

def rd(r: Array<U32> & U32) -> U32:
  (a, x) = r
  x

def spin(n: Nat, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      b = Array.map(~U32, ~U32, ~(x => U32.add(x, 1)), a)
      spin(p, b)

def main() -> IO(Unit):
  a = spin(20000n, [0 : U32*4096n])
  IO.print(U32.show(rd(Array.get(U32, a, 0))))

#|20000
