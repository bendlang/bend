# A closure is a separate JS function: its tail call must not continue
# the enclosing def's loop. This terminating recursion needs no @unsafe.
import Base

def apply(f: Nat -> Nat, x: Nat) -> Nat:
  f(x)

def bounce(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      apply(x => bounce(p), 0n)

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    IO.print(Nat.show(bounce(Nat.add(1000000n, Nat.mod(t, 1n)))))

#|0
