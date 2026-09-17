# the slot count after * is a literal power of two: 3n is refused at the
# literal, with a hint at the depth form
import Base

def main() -> Array<U32>:
  [0 : U32*3n]

#|Error:
#|- message  : a power of two count (^d takes a depth)
#|Location:
#|5 | def main() -> Array<U32>:
#|6>|   [0 : U32*3n]
#|7 |
#|exit 1
