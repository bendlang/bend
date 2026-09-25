# a literal is a String only where String declares SCon and SNil: a
# module's own String with other constructors rejects it
type String is Data:
  Foo{}

def s() -> String:
  "abc"

#|Error:
#|- expected : a declared constructor (String declares Foo)
#|- observed : "abc"
#|Location: s
#|6 | def s() -> String:
#|7>|   "abc"
#|  |   ^^^^^
#|8 | 
#|exit 1
