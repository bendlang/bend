# gates/test.ts checks C -> C, C -> JS -> C and normalization between
# emissions on this checked book, against fresh C/JS bytes and values.
# Its retained probe count must not grow across compilations.
import Base

law double:
  for n: Nat
  Nat

def double(n):
  match n:
    case Zero{}:
      0n
    case Succ{k}:
      Succ{Succ{double(k)}}

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(double(3n)))

#|6
