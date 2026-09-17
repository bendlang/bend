# a `<-` bind line is do-block syntax ONLY: outside a do-block, `x <- e`
# is not grammar.
# ported from bend3: same law, bend error page
import Base

law half:
  for x: U32
  U32

def half(x): U32.div(x, 2)

law main:
  U32

def main(): x <- half(10)

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : '<'
#|Location:
#|14 | 
#|15>| def main(): x <- half(10)
#|16 |
#|exit 1
