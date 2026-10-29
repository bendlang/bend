# A spin that has run past the poll's period answers the error word: one
# leaf spins past 4096 steps while another posts a fault, and the program
# fail-stops with the fault instead of running the spins out. spin_poll
# covers the shape; this one covers the exit the poll takes (#1820's
# review: nothing raised the error word inside a spin). The faulting
# leaf's value is read, so its Nat must materialize and the fault must
# fire on every lane.
import Base

def loop(n: Nat, +i: U32, acc: U32) -> U32:
  match n:
    case 0n: acc
    case 1n+q: loop(q, i, U32.add(acc, 1))

def tree(d: Nat, +n: Nat, +i: U32) -> U32:
  match d:
    case 0n: loop(n, i, 0)
    case 1n++q:
      a b = tree(q, n, i) tree(q, n, i)
      U32.add(a, b)

def dbl(k: Nat, +n: Nat) -> Nat:
  match k:
    case 0n: n
    case 1n+q: dbl(q, Nat.mul(n, 2n))

def main() -> IO(Unit):
  x y = tree!(4n, 100000n, 0) dbl!(60n, 1n)
  IO.print(String.append(U32.show(x), Nat.show(Nat.mod(y, 2n))))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
