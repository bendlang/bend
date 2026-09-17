# audit: the unicode forall is dead syntax -- `@` is the forall binder.
# ported from bend3
import Base

law t:
  Type

def t(): ∀x:U32.U32

law main:
  U32

def main(): 0

#|Error:
#|- expected : a term
#|- observed : '∀'
#|Location:
#|7 | 
#|8>| def t(): ∀x:U32.U32
#|9 |
#|exit 1
