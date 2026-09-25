# audit: reserved words are rejected as let binders (`do` heads a
# do-block, which wants a monad type name, never a binder).
# ported from bend3
import Base

law main:
  U32

def main():
  do = 1
  2

#|Error:
#|- expected : a name
#|- observed : '='
#|Location:
#| 9 | def main():
#|10>|   do = 1
#|   |      ^
#|11 |   2
#|exit 1
