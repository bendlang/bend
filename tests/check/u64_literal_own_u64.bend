# a u64 literal is a U64 only where U64 declares the U64 constructor: a
# module's own U64 with another constructor checks the literal's halves,
# which reports as the constructor it is
type U64 is Data:
  Foo{}

def n() -> U64:
  5u64

#|Error:
#|- expected : a declared constructor (U64 declares Foo)
#|- observed : 5u64
#|Location: n
#|7 | def n() -> U64:
#|8>|   5u64
#|9 |
#|exit 1
