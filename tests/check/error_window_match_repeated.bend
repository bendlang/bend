# every first-class match layer keeps the match span, so a repeated
# constructor points at the match containing its second occurrence
type One is Data:
  One{}
def bad() -> One -> One:
  \{One: One{}; One: One{}}

#|Error:
#|- expected : a constructor of One (missing, or already matched)
#|- observed : \{One: One{}}
#|Location: bad
#|5 | def bad() -> One -> One:
#|6>|   \{One: One{}; One: One{}}
#|  |   ^^^^^^^^^^^^^^^^^^^^^^^^^
#|7 |
#|exit 1
