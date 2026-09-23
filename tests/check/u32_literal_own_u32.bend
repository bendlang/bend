# a literal is a U32 only where U32 declares the U32 constructor: a
# module's own U32 with another constructor checks the literal's word,
# which reports as the constructor it is
type U32 is Data:
  Foo{}

def n() -> U32:
  5

#|Error:
#|- expected : a declared constructor (U32 declares Foo)
#|- observed : 5
#|Location: n
#|7 | def n() -> U32:
#|8>|   5
#|9 | 
#|exit 1
