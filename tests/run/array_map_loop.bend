# Array.map is a get/set loop into a fresh array of the same size, so T
# and U may differ: 2^10 cells of 3i mapped U32 -> Bool (above 1000),
# then Bool -> U32 and summed; a one-cell array maps too
import Base

def fill(+n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      fill(p, U32.inc(i), Array.set(U32, a, i, U32.mul(i, 3)))

def big(a: Array<U32>) -> Array<Bool>:
  Array.map(~U32, ~Bool, ~(x => U32.is_lt(1000, x)), a)

def ones(b: Array<Bool>) -> Array<U32>:
  Array.map(~Bool, ~U32, ~(z => Bool.to_u32(z)), b)

def sum(a: Array<U32>) -> U32:
  List.foldl(~&1, ~U32, ~U32, ~(s => x => U32.add(s, x)), Array.to_list(~U32, a), 0)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(sum(ones(big(fill(1024n, 0, [0 : U32*1024n]))))))
    IO.print(U32.show(sum(ones(big(ALeaf{3000})))))

#|690
#|1
