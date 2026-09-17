# slab-array pin (check_array_element_data): bend3 refused a non-Data
# (arrow) element type AT THE LITERAL while the array type itself
# stayed well-formed. bend has neither the [:T] array type nor the
# literal -- the [: spelling in the signature pins bend's own parse
# refusal.
import Base

law take:
  for a: [:U32 -> U32]
  U32

def take(a):
  0

law main:
  U32

def main():
  h = (![0:1, _:0; 2] : [:U32 -> U32])
  0

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#| 8 | law take:
#| 9>|   for a: [:U32 -> U32]
#|10 |   U32
#|exit 1
