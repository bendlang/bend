# a ~ parameter's model search ends: a datatype whose argument holds a λ
# meets itself again under a ∀-typed field (its lowered key named the
# λ's depth, so it never repeated), and a nested datatype, which meets a
# new type at every step, runs out of steps and has no model
import Base

type W<-F: Nat -> Type> is Type:
  C{g: Nat -> W<F>}

def f(~w: W<(n => Nat)>, y: Nat) -> Nat:
  y

type Nest<-A: Type> is Type:
  NCons{x: A, rest: Nest<Pair(A, A)>}
  NNil{}

def g(~n: Nest<Nat>, y: Nat) -> Nat:
  y

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
