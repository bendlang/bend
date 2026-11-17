# A def whose tail is Nat.add, or successors, of one call to itself runs as
# a loop on the C lane: the other operand joins a sum the loop carries, and
# whatever the def answers last is added to it, so the recursion holds no
# frame. Every count comes from the command line's length (1 in the
# harness), which no compiler sees. The shapes: the call on either side of
# Nat.add, under successors, beside a plain tail call and a tail call to
# another def, an operand that consumes a list while the call takes its
# tail, a sum that lands on 2^48-1, twenty thousand steps (the JS lanes
# hold about thirty thousand frames), and the same def under a fork. Two
# calls under one Nat.add (both) and a call bound by a let first (bound)
# loop too: sum_loop_calls and sum_loop_shapes hold the rest.
import Base

def digits(+k: Nat, +n: Nat) -> Nat:
  match k:
    case 0n:
      n
    case 1n+p:
      Nat.add(Nat.mod(n, 10n), digits(p, Nat.div(n, 10n)))

def left(+n: Nat) -> Nat:
  match n:
    case 0n:
      7n
    case 1n+p:
      Nat.add(left(p), n)

def succ(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      3n+succ(p)

def other(+n: Nat) -> Nat:
  Nat.mul(n, 1000n)

def mixed(+n: Nat, +m: Nat) -> Nat:
  match n:
    case 0n:
      other(m)
    case 1n+p:
      match m:
        case 0n:
          mixed(p, 5n)
        case 1n+q:
          Nat.add(Nat.mul(n, m), mixed(p, q))

def lens(xss: List<&2, List<&2, Nat>>) -> Nat:
  match xss:
    case Nil{}:
      0n
    case Con{h, t}:
      Nat.add(List.length(&2, Nat, h), lens(t))

def rows(+n: Nat, acc: List<&2, List<&2, Nat>>) -> List<&2, List<&2, Nat>>:
  match n:
    case 0n:
      acc
    case 1n+p:
      rows(p, Con{List.range(n), acc})

def big() -> Nat:
  Nat.add(Nat.mul(16777215n, 16777216n), 16777215n)

def edge(+n: Nat, +x: Nat) -> Nat:
  match n:
    case 0n:
      x
    case 1n+p:
      Nat.add(x, edge(p, x))

def both(+n: Nat) -> Nat:
  match n:
    case 0n:
      1n
    case 1n+p:
      Nat.add(both(p), both(p))

def bound(+n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      r = bound(p)
      Nat.add(n, r)

def fork(+d: Nat, +n: Nat) -> Nat:
  match d:
    case 0n:
      left(n)
    case 1n+p:
      a b = fork(p, n) left(Nat.add(n, d))
      Nat.add(a, b)

def show(+one: Nat) -> String:
  String.join([
    Nat.show(digits(Nat.mul(9n, one), Nat.mul(987654321n, one))),
    Nat.show(left(Nat.mul(100n, one))),
    Nat.show(succ(Nat.mul(100n, one))),
    Nat.show(mixed(Nat.mul(40n, one), Nat.mul(9n, one))),
    Nat.show(lens(rows(Nat.mul(50n, one), Nil{}))),
    Nat.show(edge(Nat.mul(254n, one), Nat.div(big(), Nat.mul(255n, one)))),
    Nat.show(left(Nat.mul(20000n, one))),
    Nat.show(both(Nat.mul(12n, one))),
    Nat.show(bound(Nat.mul(1000n, one))),
    Nat.show(fork(Nat.mul(6n, one), Nat.mul(1000n, one)))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|45
#|5057
#|300
#|7930
#|1275
#|281474976710655
#|200010007
#|4096
#|500500
#|3524605
