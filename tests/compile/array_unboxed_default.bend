# bend3's unboxed-ctor static default served at OOB slots; bend's
# Array has no default and wraps OOB indexes -- the defaulted slab
# literal's spelling is the refusal
import Base

type W4 is Data:
  W4{v: U32}

law main:
  U32

def main():
  h = (![0:W4{5}, _:W4{7}; 1] : [:W4])
  0

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|12 | def main():
#|13>|   h = (![0:W4{5}, _:W4{7}; 1] : [:W4])
#|14 |   0
#|exit 1
