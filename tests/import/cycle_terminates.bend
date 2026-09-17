# bend3 loaded a cyclic file pair as one book; bend REFUSES cycles by
# design (book_load's acyclic-graph law) -- the cycle itself needs a
# second file the single-file corpus cannot hold, so the pinned half
# is the eager leading-line load dying on its target
import Base
import /cycle/other_half.bend as C

law main:
  U32

def main():
  0

#|Error:
#|- message  : no such file: /cycle/other_half.bend
#|Location:
#|5 | import Base
#|6>| import /cycle/other_half.bend as C
#|7 |
#|exit 1
