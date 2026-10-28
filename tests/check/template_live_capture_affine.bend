# Negative kernel control: a captured affine witness must not become reusable.
# bend2 currently accepts this generic root, but --verdict must reject it.
# This records the remaining limitation, not successful kernel coverage.
import Base

def twice(~A: Data, ~f: @+x: A -> {x == x : A}, +x: A) -> {x == x : A} & {x == x : A}:
  (f(x), f(x))

def caller(~A: Data, f: @+x: A -> {x == x : A}, +x: A) -> {x == x : A} & {x == x : A}:
  twice(~A, ~f, x)

def concrete(+x: Bool) -> {x == x : Bool} & {x == x : Bool}:
  twice(~Bool, ~(y => {==}), x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
