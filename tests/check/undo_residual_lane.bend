# bend3's undo-replay pin rode a binderless K+ match-lambda applied in
# a type: \{0: 0; 1+: f(y)}. bend match-lambdas take constructor keys
# only -- the numeric key dies at parse inside the type's braces, so
# no residual lane exists to rebuild
import Base

law bad:
  @f:(U32 -> U32 -> U32) -> @y:U32 -> {(\{0: 0; 1+: f(y)})(2) == f(y, 2) : U32}

def bad():
  f => y => {==}

law main:
  U32

def main():
  0

#|Error:
#|- expected : '}'
#|- observed : ':'
#|Location:
#|7 | law bad:
#|8>|   @f:(U32 -> U32 -> U32) -> @y:U32 -> {(\{0: 0; 1+: f(y)})(2) == f(y, 2) : U32}
#|  |                                            ^
#|9 |
#|exit 1
