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

#|Error:
#|- expected : a pattern (a binder or a constructor)
#|- observed : Result.bind(U32, Pair(U32, U32), U32, Done{(1, 2)}, p => (a, b))
#|Location:
#|10 |   do Result<U32, U32>:
#|11>|     p : U32 & U32 <- Done{(1, 2)}
#|12 |     (a, b) = p
#|exit 1
