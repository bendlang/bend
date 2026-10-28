# A runtime function captured by a template is passed once, not made Data.
import Base

def apply_once(~A: Data, ~f: A -> A, x: A) -> A:
  f(x)

def caller(~A: Data, f: A -> A, x: A) -> A:
  apply_once(~A, ~f, x)

def concrete(x: Bool) -> Bool:
  apply_once(~Bool, ~(y => y), x)

def concrete_ok(+x: Bool) -> {concrete(x) == x : Bool}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
