# a destructure takes a parameter, and a checked argument position
# replaces bend3's `P = e : T` annotation: the worker's domain types
# the value, so no brace form is needed
# ported from bend3: local Pair renamed (base owns the def name)
import Base

type Duo is Data:
  Mk{a: U32, b: U32}

law main:
  for d: Duo
  Duo

def main(d):
  Mk{x, y} = d
  Mk{y, x}

#|\{Mk: (x => y => Mk{y, x})}
