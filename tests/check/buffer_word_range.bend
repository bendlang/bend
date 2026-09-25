# slab-array pin (check_buffer_word_range): bend3's buffer keys spanned
# the full 32-bit word range (slab capacity is the whole u32 index
# domain). bend has no buffer literals -- the ![ spelling pins bend's
# own parse refusal (bend's Array is a tree with bit-walk indexing,
# pinned by the ported array tests).
import Base

law main:
  U32

def main():
  x = (![4294967295:7,_:0;4294967296] : [:U32])@buf[4294967295]
  x

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|11 | def main():
#|12>|   x = (![4294967295:7,_:0;4294967296] : [:U32])@buf[4294967295]
#|   |        ^
#|13 |   x
#|exit 1
