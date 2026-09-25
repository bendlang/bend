# error census: the empty match over a non-datatype scrutinee names
# the datatype demand (over a non-empty datatype it names the missing
# cases: page_match_missing_ctors)
import Base
law main:
  (U32 -> U32) -> U32

def main(): \{}

#|Error:
#|- expected : a datatype
#|- observed : @_:U32 -> U32
#|Location: main
#|7 | 
#|8>| def main(): \{}
#|  |             ^^^
#|9 |
#|exit 1
