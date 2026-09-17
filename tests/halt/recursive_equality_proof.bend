# audit: recursive equality proofs cannot justify casts -- bad is a
# whole self-reference escaping as a value, refused at the def, so its
# claimed {Nat == D : Type} never reaches a rewrite.
# ported from bend3: U32 becomes Nat; the cast site falls with the def
import Base

type D is Data:
  K{}

law bad:
  {Nat == D : Type}

def bad(): bad
law main:
  Nat

def main(): 0n

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : bad
#|Location: bad
#|12 | 
#|13>| def bad(): bad
#|14 | law main:
#|exit 1
