# a live self-call may be partial: descent is lexicographic, so a spine
# whose supplied columns already shrink is a closure that already
# descended, whatever it is applied to later. part(p) shrinks column
# one; the closure takes b afterwards.
import Base

law part:
  for a: Nat
  for b: Nat
  Nat

def part(a, b):
  match a:
    case 0n:
      b
    case 1n+p:
      g = part(p)
      g(b)

law main:
  Nat

def main(): part(2n, 1n)

#|1n
