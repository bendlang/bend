# audit: direct polymorphic self recursion is rejected before use --
# loop(a) is a whole self-call with no shrinking column, refused even
# though it sits under the type binder a.
# ported from bend3: U32 becomes Nat
import Base

law loop:
  @a:Type -> a

def loop(): a => loop(a)
law main:
  Nat

def main(): loop(Nat)

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : loop
#|Context:
#|- a : Type
#|Location: loop
#| 9 | 
#|10>| def loop(): a => loop(a)
#|   |                  ^^^^
#|11 | law main:
#|exit 1
