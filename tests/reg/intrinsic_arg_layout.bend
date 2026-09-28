# regression witness: a generic pick returns a boxed Bool that native
# Bool.or/Bool.xor once read raw instead of converting to a flat tag.
import Base

def pick(-A: Data, c: Bool, a: A, b: A) -> A:
  match c:
    case True{}:
      a
    case False{}:
      b

def or_left(+n: Nat, x: Bool) -> Bool:
  Bool.or(pick(Bool, Nat.is_lt(0n, n), False{}, Nat.is_eq(n, 0n)), x)

def or_right(+n: Nat, x: Bool) -> Bool:
  Bool.or(x, pick(Bool, Nat.is_lt(0n, n), False{}, Nat.is_eq(n, 0n)))

def xor_left(+n: Nat, x: Bool) -> Bool:
  Bool.xor(pick(Bool, Nat.is_lt(0n, n), False{}, Nat.is_eq(n, 0n)), x)

def xor_right(+n: Nat, x: Bool) -> Bool:
  Bool.xor(x, pick(Bool, Nat.is_lt(0n, n), False{}, Nat.is_eq(n, 0n)))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Bool.show(or_left(0n, False{})))
    IO.print(Bool.show(or_left(1n, False{})))
    IO.print(Bool.show(or_right(0n, False{})))
    IO.print(Bool.show(or_right(1n, False{})))
    IO.print(Bool.show(xor_left(0n, True{})))
    IO.print(Bool.show(xor_left(1n, True{})))
    IO.print(Bool.show(xor_right(0n, True{})))
    IO.print(Bool.show(xor_right(1n, True{})))

#|True
#|False
#|True
#|False
#|False
#|True
#|False
#|True
