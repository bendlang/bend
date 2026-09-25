# a float literal is an F32 only where F32 declares the F32
# constructor: a module's own F32 with another constructor checks the
# literal's word, which reports as the constructor it is
type F32 is Data:
  Foo{}

def n() -> F32:
  1.5

#|Error:
#|- expected : a declared constructor (F32 declares Foo)
#|- observed : 1.5
#|Location: n
#|7 | def n() -> F32:
#|8>|   1.5
#|  |   ^^^
#|9 | 
#|exit 1
