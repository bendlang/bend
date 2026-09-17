# qualified local names: `M.name` is a legal top-level definition name,
# an ordinary name in the one namespace.
# ported from bend3: the generic Result plumbing shrinks to a dotted
# getter (bend defs take no <> params)
import Base

type Bx1 is Data:
  MkBx1{v: Unit}

law bx.unwrap:
  for b: Bx1
  Unit

def bx.unwrap(b):
  match b:
    case MkBx1{v}:
      v

law main:
  Unit

def main(): bx.unwrap(MkBx1{Unit{}})

#|Unit{}
