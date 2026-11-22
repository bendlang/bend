# a flat def lent a string reads a bit of it: the operation names its operand twice
import Base

def len(s: String, +acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{c, t}:
      len(t, U32.inc(acc))

def bit.go(b: Bool, n: U32) -> U32:
  match b:
    case True{}:
      U32.add(n, 100)
    case False{}:
      n

def bit(p: String & Bool) -> U32:
  (s, b) = p
  bit.go(b, len(s, 0))

def peek(z: Bool, s: String, +i: Nat) -> U32:
  match z:
    case True{}:
      bit(Map.bit(s, i))
    case False{}:
      7

def run(+n: Nat, +s: String, acc: U32) -> U32:
  match n:
    case 0n:
      U32.add(acc, peek(True{}, s, 3n))
    case 1n+p:
      run(p, s, U32.add(acc, peek(U32.is_eq(U32.mod(U32.from_nat(n), 2), 0), s, n)))

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    Unit <- IO.print(U32.show(run(1000n, String.append("ab", String.append("cd", Nat.show(List.length(&1, String, args)))), 0)))
    IO.print(U32.show(run(40n, "static", 7)))

#|7105
#|573
