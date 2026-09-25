# comp pin (page_comp_arrow_position): bend3's @~ comp-forall spelling
# parsed and landed on the CompArrow page (a comp arrow lives only in
# def signatures). bend has no comp arrows at all: its @ forall binds
# a name (or an erased -name), and the ~ pins bend's own parse refusal.
import Base

law TT:
  Type

def TT():
  @~g: (U32 -> U32) -> U32

law main:
  U32

def main():
  0

#|Error:
#|- expected : a name
#|- observed : '~'
#|Location:
#|10 | def TT():
#|11>|   @~g: (U32 -> U32) -> U32
#|   |    ^
#|12 |
#|exit 1
