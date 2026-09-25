# audit: erased constructor matching cannot inspect the argument -- a
# `-` scrutinee matches only in a dead region.
# ported from bend3
type Bool8 is Data:
  F8{}
  T8{}

law hidden:
  @-b:Bool8 -> Bool8

def hidden(): \{F8: T8{}; \{T8: F8{}; \{}}}

law main:
  Bool8

def main(): hidden(T8{})

#|Error:
#|- message  : a live scrutinee (a - scrutinee matches only in a dead region)
#|Location: hidden
#|10 | 
#|11>| def hidden(): \{F8: T8{}; \{T8: F8{}; \{}}}
#|   |               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#|12 |
#|exit 1
