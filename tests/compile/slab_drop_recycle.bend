# bend3's lazy slab pages (mint-wipe on recycle) at 2^17 slots;
# bend's Array is a materialized 2^d tree with no pages to recycle --
# the big slab literal's spelling is the refusal
import Base

law main:
  U32

def main():
  b = (![0:1, 131071:2, _:9; 131072] : [:U32])
  0

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#| 9 | def main():
#|10>|   b = (![0:1, 131071:2, _:9; 131072] : [:U32])
#|11 |   0
#|exit 1
