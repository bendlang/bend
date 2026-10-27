# bend3's do-lets took tuple and ctor destructures on do lines; bend's
# DoStmt grammar admits only binds and typed lets (io_do_let_lines
# pins the let) -- the tuple destructure dies inside the block
import Base

law f:
  Result<U32, U32>

def f():
  do Result<U32, U32>:
    p : U32 & U32 <- Done{(1, 2)}
    (a, b) = p
    return (a + b : U32)

law main:
  U32

def main():
  0

#|SOME PROOFS FAIL
#|Error:
#|- expected : a do-block let with its type (write "x : T = ...")
#|- observed : '='
#|Location:
#|11 |     p : U32 & U32 <- Done{(1, 2)}
#|12>|     (a, b) = p
#|   |            ^
#|13 |     return (a + b : U32)
#|exit 1
