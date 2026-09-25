# an inline exists keeps the sugar span, so a missing Exists declaration
# points at the inline clause that needs it
def bad() -> Type:
  &x: Type -> Type

#|Error:
#|- expected : a defined name
#|- observed : Exists
#|Location: bad
#|3 | def bad() -> Type:
#|4>|   &x: Type -> Type
#|  |   ^^^^^^^^^^^^^^^^
#|5 |
#|exit 1
