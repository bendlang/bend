# a field bound by a case or a destructure is matchable later, in
# binder order: a variable column is a substitution, not a decision,
# so binding h and t leaves both open and the match on h (the FIRST
# field) still finds its binder; the decision sits at h's position in
# the tree, the later binders close as lambdas inside each arm
import Base

def f(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      match h:
        case 0n:
          f(t)
        case 1n+p:
          Nat.add(p, f(t))

def g(p: Nat & Nat) -> Nat:
  (a, b) = p
  match a:
    case 0n:
      b
    case 1n+q:
      Nat.add(q, b)

def main() -> IO(Unit):
  IO.print(Nat.show(Nat.add(f([0n, 3n, 2n]), g((2n, 5n)))))

#|9
