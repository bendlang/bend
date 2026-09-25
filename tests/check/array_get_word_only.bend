# slab-array pin (check_array_get_word_only): bend3 limited free reads
# to word (U32/F32) elements -- a boxed element reads by swap. bend
# has no [:T] array type -- the [: spelling in main's parameter pins
# bend's own parse refusal.
import Base

type Box2 is Data:
  BX{v: U32}

law main:
  for xs: [:Box2]
  Box2

def main(xs):
  x = xs@ys[0]
  x

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|10 | law main:
#|11>|   for xs: [:Box2]
#|   |            ^
#|12 |   Box2
#|exit 1
