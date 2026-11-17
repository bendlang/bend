# An arm of a summing def that answers a literal 0 adds nothing: the sum
# goes on as it stands (C lane), with no add and no test against the Nat
# limit. One call and two calls under the add, an arm that answers another
# literal, an arm whose 0 is computed, U32.add, and a sum that lands on
# 2^48-1 before the arm that answers 0. Every count comes from the command
# line's length (1 in the harness), which no compiler sees.
import Base

def up(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      Nat.add(n, up(p))

def fibz(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      match p:
        case 0n:
          1n
        case 1n+q:
          Nat.add(fibz(p), fibz(q))

def five(+n: Nat) -> Nat:
  match n:
    case 0n:
      5n
    case 1n+p:
      Nat.add(n, five(p))

def calc(+n: Nat, +k: Nat) -> Nat:
  match n:
    case 0n:
      Nat.sub(k, k)
    case 1n+p:
      Nat.add(k, calc(p, k))

def wrap(+n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      0
    case 1n+p:
      U32.add(x, wrap(p, x))

def edge(+n: Nat, +big: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      Nat.add(big, edge(p, big))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +k : Nat = List.length(&1, String, args)
    IO.print(Nat.show(up(Nat.mul(k, 1000n))))
    IO.print(Nat.show(fibz(Nat.add(k, 19n))))
    IO.print(Nat.show(five(Nat.mul(k, 10n))))
    IO.print(Nat.show(calc(Nat.mul(k, 7n), 6n)))
    IO.print(U32.show(wrap(Nat.mul(k, 3n), 4000000000)))
    # three times a third of 2^48-1, which is 5592405 * 16777217
    IO.print(Nat.show(edge(Nat.mul(k, 3n), Nat.mul(Nat.mul(k, 5592405n), 16777217n))))

#|500500
#|6765
#|60
#|42
#|3410065408
#|281474976710655
