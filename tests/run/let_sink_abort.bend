# a let that aborts (a Nat past 2^48) before a call that never returns (it
# recurses until the stack runs out): the abort must come first, so the let
# must not move below the call
import Base

def boom(+n: Nat) -> U32:
  U32.from_nat(Nat.mul(Nat.mul(65536n, 65536n), Nat.add(n, 65536n)))

@unsafe
def spin(+n: U32) -> U32:
  U32.add(spin(U32.inc(n)), 1)

def f(+a: U32) -> U32:
  +x = U32.add(boom(5n), a)
  U32.add(spin(a), U32.add(x, a))

def main() -> IO(Unit):
  IO.print(U32.show(f(3)))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
