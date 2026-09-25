# bend3's GFX/Image/Bytes stack (a PPM codec over GFX.from_fn) is
# absent from bend (no IO, no Bytes namespace): the head call is an
# undefined name
import Base

law main:
  U32

def main():
  GFX.from_fn(3, x => x)

#|Error:
#|- expected : a defined name
#|- observed : GFX.from_fn
#|Location: main
#| 9 | def main():
#|10>|   GFX.from_fn(3, x => x)
#|   |   ^^^^^^^^^^^
#|11 |
#|exit 1
