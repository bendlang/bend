# bend3 pinned that a list literal never satisfies an ARRAY goal;
# bend has no [:T] array type at all -- the spelling dies at parse
# before any goal exists
import Base

law t:
  for x: U32
  {[x] == [x] : [:U32]}

def t(x):
  {==}

law main:
  U32

def main():
  0

#|Error:
#|- expected : a term
#|- observed : ':'
#|Location:
#|7 |   for x: U32
#|8>|   {[x] == [x] : [:U32]}
#|  |                  ^
#|9 |
#|exit 1
