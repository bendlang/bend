# error census: a do head with no type-argument group is refused -- the
# monad head opens `<` right after its name (`do M<>:` is the empty form).
# ported from bend3: same law, bend error page
import Base

law main:
  U32

def main():
  do Result:
    return 1

#|Error:
#|- expected : '<'
#|- observed : ':'
#|Location:
#| 9 | def main():
#|10>|   do Result:
#|   |            ^
#|11 |     return 1
#|exit 1
