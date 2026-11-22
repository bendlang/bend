# Nat.div and Nat.mod on operands scaled by the command line's length (1 in
# the harness), which no compiler sees, so no lane folds a row: b = 0 (div
# answers 0, mod the dividend), a < b, a = b, the largest Nat on either
# side, both names as function values and partly applied, and
# a = b * (a / b) + a % b over a countdown.
import Base

def big() -> Nat:
  Nat.add(Nat.mul(16777215n, 16777216n), 16777215n)

def row(+a: Nat, +b: Nat) -> String:
  Nat.show(Nat.div(a, b)) ++ " " ++ Nat.show(Nat.mod(a, b))

def ap(f: Nat -> Nat -> Nat, a: Nat, b: Nat) -> Nat:
  f(a, b)

def ap1(f: Nat -> Nat, b: Nat) -> Nat:
  f(b)

# the sum over a = n..1 of a / b + a % b, and of how far a is from
# b * (a / b) + a % b (0 when the law holds)
def laws(+a: Nat, +b: Nat, sum: Nat, off: Nat) -> Nat & Nat:
  match a:
    case 0n:
      (sum, off)
    case 1n+p:
      laws(p, b, Nat.add(sum, Nat.add(Nat.div(a, b), Nat.mod(a, b))),
        Nat.add(off, Nat.sub(a, Nat.add(Nat.mul(b, Nat.div(a, b)), Nat.mod(a, b)))))

def pair(p: Nat & Nat) -> String:
  (s, o) = p
  Nat.show(s) ++ " " ++ Nat.show(o)

def rows(+one: Nat) -> String:
  String.join([
    row(Nat.mul(0n, one), Nat.mul(0n, one)),
    row(Nat.mul(7n, one), Nat.mul(0n, one)),
    row(Nat.mul(0n, one), Nat.mul(7n, one)),
    row(Nat.mul(7n, one), Nat.mul(7n, one)),
    row(Nat.mul(7n, one), Nat.mul(2n, one)),
    row(Nat.mul(2n, one), Nat.mul(7n, one)),
    row(Nat.mul(1000000007n, one), Nat.mul(97n, one)),
    row(Nat.mul(big(), one), one),
    row(Nat.mul(big(), one), Nat.mul(big(), one)),
    row(Nat.mul(big(), one), Nat.mul(4294967295n, one)),
    row(one, Nat.mul(big(), one)),
    row(Nat.mul(big(), one), Nat.mul(0n, one)),
    Nat.show(ap(Nat.div, Nat.mul(100n, one), Nat.mul(7n, one))) ++ " "
      ++ Nat.show(ap(Nat.mod, Nat.mul(100n, one), Nat.mul(7n, one))),
    Nat.show(ap1(Nat.div(Nat.mul(100n, one)), Nat.mul(9n, one))) ++ " "
      ++ Nat.show(ap1(Nat.mod(Nat.mul(100n, one)), Nat.mul(9n, one))),
    pair(laws(Nat.mul(1000n, one), Nat.mul(7n, one), 0n, 0n)),
    pair(laws(Nat.mul(1000n, one), Nat.mul(0n, one), 0n, 0n))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(rows(List.length(&1, String, xs)))

#|0 0
#|0 7
#|0 0
#|1 0
#|3 1
#|0 2
#|10309278 41
#|281474976710655 0
#|1 0
#|65536 65535
#|0 1
#|0 281474976710655
#|14 2
#|11 1
#|74074 0
#|500500 0
