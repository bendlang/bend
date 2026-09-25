# an assert-level exists keeps its clause span, so a missing Exists
# declaration points at the clause that introduced the sugar
law bad:
  exs x: Type
  Type

#|Error:
#|- expected : a defined name
#|- observed : Exists
#|Location: bad
#|3 | law bad:
#|4>|   exs x: Type
#|  |       ^
#|5 |   Type
#|exit 1
