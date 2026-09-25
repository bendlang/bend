# a rewrite's generated proof binder keeps the equation span, so its
# misuse in the motive points at the rewrite that bound it
def bad(e: {Type == Type : Type}) -> Type:
  %h@e : h
  Type

#|Error:
#|- expected : Type
#|- observed : {Type == _ : Type}
#|Context:
#|- e : {Type == Type : Type}
#|- _ : Type
#|- h : {Type == _ : Type}
#|Location: bad
#|3 | def bad(e: {Type == Type : Type}) -> Type:
#|4>|   %h@e : h
#|  |          ^
#|5 |   Type
#|exit 1
