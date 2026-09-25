# bend3's fill+readback guard rode the slab-array literal and its
# counter; bend has neither --stats nor slabs (Array<T> is a 2^d
# tree, its read/write sugar is over base ops), so the slab literal's
# own spelling is the refusal
import Base

law main:
  U32

def main():
  m : [:U32] = ![31:0, _:0; 32]
  m[0]

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|10 | def main():
#|11>|   m : [:U32] = ![31:0, _:0; 32]
#|   |        ^
#|12 |   m[0]
#|exit 1
