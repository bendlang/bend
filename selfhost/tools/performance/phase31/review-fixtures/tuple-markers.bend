import Base

# No Array native occurs: the canonical Sigma representation alone requires
# Array-prototype marker refusal before bypassing the helper lookup.
def tweak(+x: U32) -> U32:
  U32.inc(x)

def add_pair(+bias: U32, r: U32 & U32) -> U32:
  (x, y) = r
  U32.add(bias, tweak(U32.add(x, y)))

def walk(+n: Nat, +acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+q:
      walk(q, add_pair(0, (acc, 1)))

def bench(+n: U32, +seed: U32) -> U32:
  walk(U32.to_nat(n), seed)

def main() -> IO(Unit):
  IO.print(U32.show(bench(3, 5)))

#| 11
