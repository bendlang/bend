# a ~ law of another ~ parameter needs their models to hold together: at
# le = λx y. False{}, step has none, so --verdict refits le to True{}
# (#1182); antisymm's {x == y : A}, at A = Unit, holds by a match on x
# and on y
import Base

law step_le:
  for ~A: Data
  for ~le: A -> A -> Bool
  for ~step: @x: A -> @y: A -> {x == x : A} -> {le(x, y) == True{} : Bool}
  for +a: A
  for +b: A
  for h: {a == a : A}
  {le(a, b) == True{} : Bool}

def step_le(A, le, step, a, b, h):
  step(a, b, h)

law antisymm_eq:
  for ~A: Data
  for ~le: A -> A -> Bool
  for ~antisymm: @x: A -> @y: A -> {le(x, y) == True{} : Bool} -> {le(y, x) == True{} : Bool} -> {x == y : A}
  for +a: A
  for +b: A
  for ab: {le(a, b) == True{} : Bool}
  for ba: {le(b, a) == True{} : Bool}
  {a == b : A}

def antisymm_eq(A, le, antisymm, a, b, ab, ba):
  antisymm(a, b, ab, ba)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
