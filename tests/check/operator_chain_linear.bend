# operator chains are ordinary calls under the affine core: a binder
# consumed by two operands is refused (bend3 priced the chain; bend
# walls it)
import Base

law f:
  for x: U32
  U32

def f(x):
  (x + x : U32)

law main:
  U32

def main():
  f(3)

#|Error:
#|- expected : x
#|- observed : x (consumed more than once)
#|Location: f
#| 9 | 
#|10>| def f(x):
#|11 |   (x + x : U32)
#|exit 1
