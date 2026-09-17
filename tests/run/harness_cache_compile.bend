# bend3's harness-cache adversary, compile side: compile and eval
# blocks shared one cached checked book and stayed pure. bend's
# runner shares one in-process book across a file's blocks the same
# way (no --compile flag; --show is the compile-side page): the value
# and the rendered page must repeat byte-identically
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
