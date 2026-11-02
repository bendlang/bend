# A curried λ that returns a match keeps the match's type after β-reduction.
import Base

law via:
  for ~f: Nat -> Bool -> Bool
  for ~ok: (@x: Bool -> {f(0n, x) == f(0n, x) : Bool})
  for b: Bool
  {f(0n, b) == f(0n, b) : Bool}

def via(f, ok, b):
  ok(b)

law use:
  for b: Bool
  {b == b : Bool}

def use(b):
  -z = via(~(n => ({\{True: False{}; False: True{}} : Bool -> Bool})), ~(z => {==}), b)
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
