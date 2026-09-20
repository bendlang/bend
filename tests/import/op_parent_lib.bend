# Recursion inside typed arithmetic keeps the imported module namespace.
import Base

def sum(xs: List<&2, Nat>) -> Nat:
  match xs:
    case Nil{}: 0n
    case x <> tail: (x + sum(tail) : Nat)

def id_u(x: U32) -> U32: x

def main() -> IO(Unit):
  IO.print(Nat.show(sum([1n, 2n, 3n])))

#|6
