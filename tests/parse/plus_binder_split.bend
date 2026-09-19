# a + field binder whose column a later row splits (issue #810): the +
# is a mark on the binder, so the split's fields inherit it and no let
# rebinds a constructor
import Base

def f(ys: List<&2, U32>) -> Nat:
  match ys:
    case Con{h, +z}:
      (List.length(&2, U32, z) + List.length(&2, U32, z) : Nat)
    case [c, d]:
      1n
    case _:
      0n

def main() -> IO(Unit):
  IO.print(Nat.show(f([3, 4])))

#|2
