# Tail jumps transfer all arguments together, across arities and entry points.
import Base

@unsafe
def first(n: Nat, a: U32, b: U32) -> U32:
  match n:
    case 0n:
      U32.add(U32.mul(a, 10), b)
    case 1n+p:
      second(p, b, a, "unused")

@unsafe
def second(n: Nat, a: U32, b: U32, s: String) -> U32:
  third(s, n, b, a)

@unsafe
def third(s: String, n: Nat, a: U32, b: U32) -> U32:
  first(n, b, a)

# A non-tail call into the same group must return before the addition.
@unsafe
def count(n: Nat, b: Bool) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      match b:
        case False{}:
          Nat.add(1n, back(p, True{}))
        case True{}:
          back(p, False{})

@unsafe
def back(n: Nat, b: Bool) -> Nat:
  count(n, b)

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    IO.print(U32.show(first(Nat.add(1000001n, Nat.mod(t, 1n)), 1, 2)))
    IO.print(U32.show(second(1n, 1, 2, "entry")))
    IO.print(U32.show(third("entry", 1n, 1, 2)))
    IO.print(Nat.show(count(10n, False{})))

#|21
#|21
#|12
#|5
