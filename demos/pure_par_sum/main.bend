# Parallel sum: the 2^d numbers from i as a fork/join tree; sum! runs it on
# the GPU or every core. Prints 2147450880.
#   bend demos/pure_par_sum/main.bend -o sum && ./sum
import Base
import ./SPEC.bend as Spec

def sum(d: Nat, +i: Nat) -> Nat:
  match d:
    case 0n:
      i
    case 1n++p:
      a b = sum(p, i) sum(p, Nat.add(Spec.pow2(p), i))
      Nat.add(a, b)

def main() -> IO(Unit):
  IO.print(Nat.show(sum!(16n, 0n)))
