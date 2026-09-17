# a bare 0x is not a number: bend literals are decimal only, so the
# 'x' fails right after the 0 with the literal page.
# ported from bend3: bend3 had hex and pinned the no-digit case; bend
# dropped hex whole
import Base

law main:
  U32

def main(): 0x

#|Error:
#|- expected : a numeric literal (NUMBER is U32, NUMBER n is Nat)
#|- observed : 'x'
#|Location:
#| 9 | 
#|10>| def main(): 0x
#|11 |
#|exit 1
