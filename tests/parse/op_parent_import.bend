# A parent-relative reference is not an unresolved operator namespace.
import Base
import ../import/op_parent_lib.bend as M

def main() -> IO(Unit):
  IO.print(Nat.show((M.sum([1n, 2n, 3n]) + 1n : Nat)))

#|7
