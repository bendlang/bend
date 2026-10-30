# in a do block, `x+y` gets the same error, at the `+` (#1510)
import Base

def add(x: U32, +y: U32) -> IO(U32):
  do IO<U32>:
    x+y

def main() -> IO(U32):
  add(1, 2)

#|SOME PROOFS FAIL
#|Error:
#|- expected : '=' (an operator takes spaces on both sides and a type: (a + b : T))
#|- observed : '+'
#|Location:
#|5 |   do IO<U32>:
#|6>|     x+y
#|  |      ^
#|7 | 
#|exit 1
