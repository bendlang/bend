# the cycle that #1984's merge made also hung the checker: after z and c
# merge, c's value reaches c, and {c == A{}} unfolds it forever
import Base

type T is Type:
  A{}
  B{}

def f(b: T) -> T:
  match b:
    case A{}:
      B{}
    case B{}:
      A{}

def P(c: T) -> Type:
  &z: T -> {f(c) == z : T} & {f(z) == c : T} & {c == A{} : T}

def p() -> P(A{}):
  (B{}, {==}, {==}, {==})

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
