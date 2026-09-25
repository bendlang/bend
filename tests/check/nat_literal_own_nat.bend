# a literal is a Nat only where Nat declares Succ and Zero: a module's
# own Nat with other constructors rejects it
type Nat is Data:
  Foo{}

def n() -> Nat:
  3n

#|Error:
#|- expected : a declared constructor (Nat declares Foo)
#|- observed : 3n
#|Location: n
#|6 | def n() -> Nat:
#|7>|   3n
#|  |   ^^
#|8 | 
#|exit 1
