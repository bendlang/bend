# bend3 rejected a do line shallower than its head (the line-depth
# page); bend blocks are layout-free by design, so the same shallow
# line parses, binds, and the value proves it
import Base

law f:
  Result<&2, &2, U32, U32>

def f():
  do Result<&2, &2, U32, U32>:
  x : U32 <- Done{1}
    return x

law unwrap:
  for r: Result<&2, &2, U32, U32>
  U32

def unwrap(r):
  match r:
    case Done{v}:
      v
    case Fail{x}:
      x

law main.out:
  Nat

def main.out():
  U32.to_nat(unwrap(f()))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|1n
