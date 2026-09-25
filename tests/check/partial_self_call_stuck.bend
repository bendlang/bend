# a partial self-call whose supplied columns stay EQ has not descended:
# the closure could be applied to anything, so it is refused as any
# non-decreasing call is.
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
      g = part(a)
      g(p)

law main:
  Nat

def main(): part(2n, 1n)

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : part
#|Context:
#|- p : Nat
#|- b : Nat
#|Location: part
#|15 |     case 1n+p:
#|16>|       g = part(a)
#|   |           ^^^^
#|17 |       g(p)
#|exit 1
