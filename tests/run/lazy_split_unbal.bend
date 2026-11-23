# lazy splits: a very unbalanced fork tree. Item i of 16 is a balanced tree
# of 2^(16 - i) leaves, so item 0 holds half the work; every leaf sums an
# LCG over 64 steps. The result is the same at every thread count.
import Base

def work(+k: Nat, +x: U32) -> U32:
  match k:
    case 0n:
      x
    case 1n+p:
      work(p, (x * 1664525 + 1013904223 : U32))

def tree(+d: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      work(64n, i)
    case 1n+p:
      a b = tree(p, (i * 2 : U32)) tree(p, (i * 2 + 1 : U32))
      U32.xor(a, b)

@unsafe
def items(+lo: U32, +hi: U32) -> U32:
  items.go(U32.is_eq((hi - lo : U32), 1), lo, hi)

@unsafe
def items.go(one: Bool, +lo: U32, +hi: U32) -> U32:
  match one:
    case True{}:
      tree(U32.to_nat((16 - lo : U32)), lo)
    case False{}:
      +mid = (lo + (hi - lo) / 2 : U32)
      a b = items(lo, mid) items(mid, hi)
      (a + b : U32)

@unsafe
def main() -> U32:
  items(0, 16)

#|322923265
