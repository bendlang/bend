# a first-class match's empty tail keeps the match span, so a missing
# constructor points at the match that omitted it
type Bool is Data:
  True{}
  False{}
def bad() -> Bool -> Bool:
  \{True: True{}}

#|Error:
#|- expected : cases for False
#|- observed : \{}
#|Location: bad
#|6 | def bad() -> Bool -> Bool:
#|7>|   \{True: True{}}
#|  |   ^^^^^^^^^^^^^^^
#|8 |
#|exit 1
