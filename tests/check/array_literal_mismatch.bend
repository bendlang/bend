# slab-array pin (check_array_literal_mismatch): bend3 reported an
# array literal at a non-array goal as the ordinary mismatch, printed
# in keyed form. bend has no array literals -- the ![ spelling pins
# bend's own parse refusal.
import Base

law main:
  U32

def main():
  m = (![0:5, _:0; 1] : U32)
  0

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|10 | def main():
#|11>|   m = (![0:5, _:0; 1] : U32)
#|   |        ^
#|12 |   0
#|exit 1
