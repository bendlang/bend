# slab-array pin (check_array_set_neutral_000): bend3 type-checked a
# write to a NEUTRAL array parameter (the Swp result must not stick as
# a dependent type-former). bend has no [:T] array type -- the [:
# spelling in main's parameter pins bend's own parse refusal.
import Base

law main:
  for a: [:U32]
  [:U32]

def main(a):
  old = a@m[0] <- 9
  m

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|7 | law main:
#|8>|   for a: [:U32]
#|  |           ^
#|9 |   [:U32]
#|exit 1
