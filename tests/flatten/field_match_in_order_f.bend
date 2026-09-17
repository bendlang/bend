# a field bound by a case or a destructure is matchable later, in
# binder order: a variable column is a substitution, not a decision,
# so binding h and t leaves both open and the match on h (the FIRST
# field) still finds its binder; the decision sits at h's position in
# the tree, the later binders close as lambdas inside each arm
import Base

def main(xs: List<Nat>) -> Nat:
  match xs:
    case Nil{}:
      0n
    case h <> t:
      match h:
        case 0n:
          main(t)
        case 1n+p:
          Nat.add(p, main(t))

def g(p: Nat & Nat) -> Nat:
  (a, b) = p
  match a:
    case 0n:
      b
    case 1n+q:
      Nat.add(q, b)

#|\{Nil: 0n; Con: \{Zero: (t => main(t)); Succ: (p => t => Nat.add(p, main(t)))}}
