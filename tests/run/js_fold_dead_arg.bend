# A known arm may drop work that would hit the Nat limit at runtime.
import Base

def square_twice(+k: Nat) -> Nat:
  Nat.mul(Nat.mul(k, k), Nat.mul(k, k))

def pick(x: Nat, which: Nat, other: Nat) -> Nat:
  match which:
    case 0n:
      other
    case 1n+p:
      x

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +n : Nat = List.length(&1, String, args)
    +big : Nat = Nat.add(100000n, n)
    u : Unit <- IO.print(Nat.show(pick(square_twice(big), 0n, 100n)))
    IO.print(Nat.show(pick(square_twice(Nat.add(2n, n)), 1n, 102n)))

#|100
#|81
