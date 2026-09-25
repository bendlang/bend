# bend3 erased a - parameter at EMISSION even when the body mentioned
# it in dead positions; bend's checker refuses every such mention
# outright, so the emission cases cannot exist -- the dead let's
# operand is the refusal
import Base

law opnd:
  for -x: U32
  U32

def opnd(x):
  y = (x + 1 : U32)
  0

law main:
  U32

def main():
  opnd(5)

#|Error:
#|- expected : -x
#|- observed : x
#|Location: opnd
#|10 | 
#|11>| def opnd(x):
#|   |          ^
#|12 |   y = (x + 1 : U32)
#|exit 1
