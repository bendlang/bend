# audit: the unicode lambda is dead syntax -- `=>` is the lambda form.
# ported from bend3
import Base

law id:
  @_:U32 -> U32

def id(): λx.x

law main:
  U32

def main(): id(7)

#|Error:
#|- expected : a term
#|- observed : 'λ'
#|Location:
#|7 | 
#|8>| def id(): λx.x
#|  |           ^
#|9 |
#|exit 1
