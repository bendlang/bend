# audit: type-level self recursion is rejected before conversion can
# loop -- a def body checks live even at Type, so the bare self
# -reference is refused as an escaping value.
# ported from bend3: U32 becomes Nat
import Base

law a:
  Type

def a(): a
law main:
  Nat

def main(): 0n

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : a
#|Location: a
#| 9 | 
#|10>| def a(): a
#|11 | law main:
#|exit 1
