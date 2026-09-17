# Parallel sum: the 2^d numbers from i as a fork/join tree; sum! runs it on
# the GPU or every core. Prints 2147450880.
#   bend demos/pure_par_sum/main.bend -o sum && ./sum
import Base

def pow2(d: Nat) -> Nat:
  match d:
    case 0n:
      1n
    case 1n+p:
      +h = pow2(p)
      Nat.add(h, h)

def sum(d: Nat, +i: Nat) -> Nat:
  match d:
    case 0n:
      i
    case 1n++p:
      a b = sum(p, i) sum(p, Nat.add(pow2(p), i))
      Nat.add(a, b)

# spec for LAWS.bend only
def seq(n: Nat, +i: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n++m:
      Nat.add(seq(m, i), Nat.add(m, i))

def main() -> IO(Unit):
  IO.print(Nat.show(sum!(16n, 0n)))
