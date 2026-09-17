# slab-array pin (check_array_get_copy): bend3's word-element read is a
# free copy (b@b1[0] contracts like a Lone word binder). bend has no
# slab arrays or @-reads -- the ![ literal pins bend's own parse
# refusal (base Array.get with U32.copy is the bend spelling, pinned
# by the ported array tests).
import Base

law main:
  U32

def main():
  b = (![0:5, _:0; 1] : [:U32])
  x = b@b1[0]
  (x + x : U32)

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|11 | def main():
#|12>|   b = (![0:5, _:0; 1] : [:U32])
#|13 |   x = b@b1[0]
#|exit 1
