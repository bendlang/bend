# audit 009: reserved names cannot be used as binders.
# ported from bend3
law main:
  @_:Type -> Type

def main(): Type => Type

#|Error:
#|- expected : a lambda binder (one name: k => body)
#|- observed : ' '
#|Location:
#|5 | 
#|6>| def main(): Type => Type
#|  |                    ^
#|7 |
#|exit 1
