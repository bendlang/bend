# Every saved closure keeps its iteration's parameter, not a loop carrier.
import Base

def sum(fs: List<&1, Nat -> Nat>) -> Nat:
  match fs:
    case Nil{}:
      0n
    case Con{f, rest}:
      Nat.add(f(0n), sum(rest))

def capture(+n: Nat, fs: List<&1, Nat -> Nat>) -> Nat:
  match n:
    case 0n:
      sum(fs)
    case 1n+p:
      capture(p, Con{x => Nat.add(x, n), fs})

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    IO.print(Nat.show(capture(Nat.add(10n, Nat.mod(t, 1n)), Nil{})))

#|55
