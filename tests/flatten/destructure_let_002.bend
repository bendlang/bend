# a destructure takes a parameter, and a checked argument position
# replaces bend3's `P = e : T` annotation: the worker's domain types
# the value, so no brace form is needed
# ported from bend3: local Pair renamed (base owns the def name)
import Base

type Duo is Data:
  Mk{a: U32, b: U32}

law flip:
  for d: Duo
  Duo

def flip(d):
  Mk{x, y} = d
  Mk{y, x}

law main:
  for p: Duo
  Duo

def main(p):
  flip(p)

#|p => flip(p)
