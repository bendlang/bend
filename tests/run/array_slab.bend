# bend3's >2^16-slot slab representation and its past-capacity no-op
# laws; bend's Array is a materialized tree with no slab tier -- the
# big sparse literal's spelling is the refusal
import Base

law main:
  U32

def main():
  m : [:U32] = ![70000:1, _:0; 131072]
  m[70000]

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : ':'
#|Location:
#| 9 | def main():
#|10>|   m : [:U32] = ![70000:1, _:0; 131072]
#|11 |   m[70000]
#|exit 1
