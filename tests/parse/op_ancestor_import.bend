# The same boundary holds for imports with multiple parent segments.
import Base
import ../../tests/import/op_parent_lib.bend as M

def main() -> IO(Unit):
  IO.print(Nat.show((M.sum([1n, 2n, 3n]) + 1n : Nat)))

#|7
