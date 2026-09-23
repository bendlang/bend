# a nat literal plus a u32 literal is not a nat sum: 1n+5 is Succ{u32 5}
# whose field is a U32, so it is refused at a Nat rather than folded
import Base

def main() -> Nat:
  1n+5

#|
#|Error:
#|- expected : Nat
#|- observed : U32
#|Location: main
#|5 | def main() -> Nat:
#|6>|   1n+5
#|7 | 
#|exit 1
