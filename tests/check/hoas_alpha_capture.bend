# soundness pin: HOAS conversion never confuses binders -- the K vs
# K* combinator equation is refused (a capture bug would accept it).
# ported from bend3
import Base

law bad:
  {(x => y => x) == (x => y => y) : U32 -> U32 -> U32}

def bad(): {==}

law main:
  U32

def main(): 0

#|Error:
#|- expected : x => y => x
#|- observed : x => y => y
#|Location: bad
#| 8 | 
#| 9>| def bad(): {==}
#|10 |
#|exit 1
