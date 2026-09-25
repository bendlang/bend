# bend3's uninitialized padding slots and the drop walk's freed-node
# aliasing; bend's Array materializes every leaf and has no literal-
# with-default -- the padded slab literal's spelling is the refusal
import Base

type P4 is Data:
  P4{a: U32, b: U32}
  N4{}

law main:
  U32

def main():
  b = (![0:P4{1,2}, 1:P4{3,4}, _:N4{}; 8] : [:P4])
  0

#|Error:
#|- expected : a term
#|- observed : '!'
#|Location:
#|13 | def main():
#|14>|   b = (![0:P4{1,2}, 1:P4{3,4}, _:N4{}; 8] : [:P4])
#|   |        ^
#|15 |   0
#|exit 1
