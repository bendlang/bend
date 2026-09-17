# bend3's slab bounds laws (total over u32 keys, defaults at unwritten
# slots); bend's Array<T> is a 2^d tree with wrapping bit-walk
# indexing and no literal -- the slab literal's spelling is the
# refusal (the in-range reads are covered by the ported array tests)
import Base

law main:
  U32

def main():
  m : [:U32] = ![0:10, 1:20, 3:7, _:0; 4]
  m[0]

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#|10 | def main():
#|11>|   m : [:U32] = ![0:10, 1:20, 3:7, _:0; 4]
#|12 |   m[0]
#|exit 1
