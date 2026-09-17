# bend3's slab-handle lazy allocation (pages minted on first write)
# and past-capacity no-ops; bend's Array has no slabs, handles or
# capacity -- the sparse slab literal's spelling is the refusal
import Base

law main:
  U32

def main():
  a = (![70000: 9, _: 1; 131072] : [:U32])
  0

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#| 9 | def main():
#|10>|   a = (![70000: 9, _: 1; 131072] : [:U32])
#|11 |   0
#|exit 1
