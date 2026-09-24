# Mutual recursion through laws predates implicit unsafe forward calls.
import Base

law even:
  for n: Nat
  Bool

law odd:
  for n: Nat
  Bool

@unsafe
def even(n):
  match n:
    case 0n:
      True{}
    case 1n+p:
      odd(p)

@unsafe
def odd(n):
  match n:
    case 0n:
      False{}
    case 1n+p:
      even(p)

def main() -> IO(Unit):
  do IO<Unit>:
    t : Nat <- IO.now()
    IO.print(Bool.show(even(Nat.add(1000000n, Nat.mul(Nat.mod(t, 1n), 1n)))))

#|True
