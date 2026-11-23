# a fork-free task whose continuation chain reaches a forking continuation:
# each round's two fork-free halves end in a fork-free join, whose caller
# then forks the next round. On the host that caller runs in turns (its
# forks dealt), not on in the finished task's sequence; the result is the
# same at every thread count.
import Base

def work(+k: Nat, +x: U32) -> U32:
  match k:
    case 0n:
      x
    case 1n+p:
      work(p, (x * 1664525 + 1013904223 : U32))

def half(+x: U32) -> U32:
  work(300n, x)

def pair(+x: U32) -> U32:
  a b = half(x) half((x + 1 : U32))
  (a + b : U32)

def tree(+d: Nat, +x: U32) -> U32:
  match d:
    case 0n:
      pair(x)
    case 1n+p:
      a b = tree(p, (x * 2 : U32)) tree(p, (x * 2 + 1 : U32))
      (a + b : U32)

def rounds(+r: Nat, +acc: U32) -> U32:
  match r:
    case 0n:
      acc
    case 1n+p:
      rounds(p, (acc + tree(5n, pair(acc)) : U32))

def main() -> U32:
  rounds(60n, 1)

#|2368164865
