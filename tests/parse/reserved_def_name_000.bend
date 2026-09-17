# bend3 reserved the type name U32 at declarations; in bend U32 is a
# Base library name, not a keyword -- redeclaring it dies as an
# ordinary duplicate, which is the inverted law's own pin
import Base

law U32:
  Type

def U32():
  Type

#|Error:
#|- expected : a fresh name (duplicate declaration: U32)
#|- observed : ':'
#|Location:
#|5 | 
#|6>| law U32:
#|7 |   Type
#|exit 1
