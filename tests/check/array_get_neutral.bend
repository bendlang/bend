# slab-array pin (check_array_get_neutral): bend3 type-checked a read
# of a NEUTRAL array parameter (the Get result must not stick as a
# dependent type-former). bend has no [:T] array type -- the [:
# spelling in main's parameter pins bend's own parse refusal.
import Base

law main:
  for a: [:U32]
  U32

def main(a):
  z = a@m[0]
  z

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|7 | law main:
#|8>|   for a: [:U32]
#|  |           ^
#|9 |   U32
#|exit 1
