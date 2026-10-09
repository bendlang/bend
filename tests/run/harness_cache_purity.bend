# gates/test.ts interleaves this independently checked program with a
# different book (A -> B -> A). Both programs' C/JS bytes and values must
# match fresh baselines, without retaining previous compilations' probes.
import Base

law grow:
  for n: Nat
  Nat

def grow(n):
  match n:
    case Zero{}:
      1n
    case Succ{k}:
      Succ{Succ{grow(k)}}

law shrink:
  for n: Nat
  Nat

def shrink(n):
  match n:
    case Zero{}:
      0n
    case Succ{k}:
      k

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(shrink(grow(5n))))

#|10
