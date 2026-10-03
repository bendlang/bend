# a nested match on a row's own binder stays a match when a later row
# splits that column: the [p, q] row splits W and the 0n row splits n,
# and the first row's inner match picks its case from the split (#1125)
import Base

def g(n: Nat, xs: List<&2, U32>) -> U32:
  match n, xs:
    case 0n, Con{h, W}:
      match W:
        case Nil{}:
          h
        case Con{a, b}:
          a
    case k, [p, q]:
      p
    case k, _:
      0

def h(n: Nat, b: Bool) -> U32:
  match n, b:
    case 0n, True{}:
      1
    case k, _:
      match k:
        case 0n:
          10
        case Succ{j}:
          20

def main() -> U32 & U32 & U32 & U32 & U32:
  (g(0n, [1, 2]), g(0n, [3]), g(1n, [4, 5]), h(0n, False{}), h(2n, True{}))

#|(2, 3, 4, 10, 20)
