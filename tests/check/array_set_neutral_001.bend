# slab-array pin (check_array_set_neutral_001): bend3's printer
# rendered a stuck Set on a neutral array parameter as the braced
# block spelling. bend has no [:T] array type -- the [: spelling in
# main's parameter pins bend's own parse refusal.
import Base

law main:
  for a: [:U32]
  U32

def main(a):
  x = a@m[0] <- 5
  x

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|7 | law main:
#|8>|   for a: [:U32]
#|9 |   U32
#|exit 1
