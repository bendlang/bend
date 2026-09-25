# a bare underapplied generic def at a concrete type errors with its
# generalized type.
# ported from bend3: def-level <A> params become an erased -A: Type bind
import Base

law id2:
  for -A: Type
  for x: A
  A

def id2(A, x):
  x

law main:
  U32

def main(): id2

#|Error:
#|- expected : U32
#|- observed : @-A:Type -> @x:A -> A
#|Location: main
#|16 | 
#|17>| def main(): id2
#|   |             ^^^
#|18 |
#|exit 1
