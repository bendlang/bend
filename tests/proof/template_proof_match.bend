# Preserve the match lambda's checked type in the emitted theorem.
import Base

law via:
  for ~f: Bool -> Bool
  for ~ok: (@x: Bool -> {f(x) == f(x) : Bool})
  for u: Unit
  {f(True{}) == f(True{}) : Bool}

def via(f, ok, u):
  ok(True{})

law use:
  for u: Unit
  {True{} == True{} : Bool}

def use(u):
  via(~(\{True: True{}; False: False{}}), ~(z => {==}), u)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
